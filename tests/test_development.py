"""Regression tests for target selection and staged secret scanning."""
import json
import os
from pathlib import Path
import subprocess
import tempfile
import textwrap
import unittest

PROJECT = Path(__file__).resolve().parents[1]


class DevelopmentTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name)
        self.env = dict(os.environ, GITHUB_OUTPUT=str(self.root / "output"))
        self.env.pop("BETTERLEAKS_ALL_FILES", None)
        self.git("init", "-q")
        self.git("config", "user.name", "Test")
        self.git("config", "user.email", "test@example.com")
        for repo in ("one", "two"):
            path = self.root / "terraform/src/repositories" / repo
            path.mkdir(parents=True)
            (path / "terraform.tf").write_text("terraform {}\n")
        self.git("add", "terraform")
        self.git("commit", "-qm", "initial")
        (self.root / "mise.toml").write_text('[tools]\nterraform = "1.16.4"\nnode = "24"\n')
        self.git("add", "mise.toml")
        self.git("commit", "-qm", "initial tools")
        self.base = self.git("rev-parse", "HEAD").stdout.strip()

    def tearDown(self):
        self.temp.cleanup()

    def git(self, *args):
        return subprocess.run(["git", *args], cwd=self.root, check=True,
                              text=True, capture_output=True)

    def matrix(self, event="workflow_dispatch", target="one", base=None):
        (self.root / "output").unlink(missing_ok=True)
        env = dict(self.env, EVENT_NAME=event, TARGET_REPOSITORY=target,
                   BASE_SHA=base or self.base, HEAD_SHA="HEAD")
        return subprocess.run(["bash", str(PROJECT / ".github/scripts/set_matrix.sh")],
                              cwd=self.root, env=env, text=True, capture_output=True)

    def result(self):
        return json.loads((self.root / "output").read_text().splitlines()[0].split("=", 1)[1])

    def commit_file(self, name):
        path = self.root / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text("change\n")
        self.git("add", name)
        self.git("commit", "-qm", "change")

    def test_whitespace_fix_preserves_open_readers_and_executable_mode(self):
        target = self.root / "reader.sh"
        original = "#!/usr/bin/env bash\necho ok  \n"
        target.write_text(original)
        target.chmod(0o755)
        with target.open() as reader:
            subprocess.run(["bash", str(PROJECT / "scripts/lint/trailing-whitespace.sh"),
                            str(target)], check=True)
            self.assertEqual(reader.read(), original)
        self.assertEqual(target.read_text(), "#!/usr/bin/env bash\necho ok\n")
        self.assertEqual(target.stat().st_mode & 0o777, 0o755)
        inode = target.stat().st_ino
        subprocess.run(["bash", str(PROJECT / "scripts/lint/trailing-whitespace.sh"),
                        str(target)], check=True)
        self.assertEqual(target.stat().st_ino, inode)

    def test_manual_single_root(self):
        self.assertEqual(self.matrix().returncode, 0)
        self.assertEqual(self.result(), ["one"])

    def test_renamed_root_is_selected_without_the_removed_directory(self):
        self.git("mv", "terraform/src/repositories/one", "terraform/src/repositories/kazokubi")
        self.git("commit", "-qm", "rename root")
        for event in ("pull_request", "push"):
            with self.subTest(event=event):
                self.assertEqual(self.matrix(event=event).returncode, 0)
                self.assertEqual(self.result(), ["kazokubi"])
        self.assertEqual(self.matrix(target="kazokubi").returncode, 0)
        self.assertEqual(self.result(), ["kazokubi"])
        self.assertNotEqual(self.matrix(target="one").returncode, 0)

    def test_manual_all_roots(self):
        self.assertEqual(self.matrix(target="all").returncode, 0)
        self.assertEqual(self.result(), ["one", "two"])

    def shards(self):
        lines = (self.root / "output").read_text().splitlines()
        return json.loads(next(line.split("=", 1)[1] for line in lines
                               if line.startswith("shards=")))

    def test_shard_distribution_for_single_all_and_empty(self):
        self.assertEqual(self.matrix().returncode, 0)
        self.assertEqual(self.shards(), [{"id": 0, "repositories": ["one"]}])
        for number in range(39):
            path = self.root / "terraform/src/repositories" / f"repo-{number:02}"
            path.mkdir()
            (path / "terraform.tf").write_text("terraform {}\n")
        self.assertEqual(self.matrix(target="all").returncode, 0)
        shards = self.shards()
        self.assertEqual(len(shards), 5)
        roots = [root for shard in shards for root in shard["repositories"]]
        self.assertEqual(sorted(roots), self.result())
        self.assertEqual(len(set(roots)), 41)
        sizes = [len(shard["repositories"]) for shard in shards]
        self.assertEqual(sorted(sizes), [8, 8, 8, 8, 9])
        self.assertEqual(self.matrix(event="push").returncode, 0)
        self.assertEqual(self.shards(), [])

    def test_shard_implementation_changes_select_all_without_auto_apply(self):
        for name in (".github/scripts/terraform_shard.sh",
                     ".github/scripts/set_matrix.sh",
                     ".github/workflows/terraform-github.yml",
                     ".github/actions/terraform-shard/action.yml"):
            self.commit_file(name)
            self.assertEqual(self.matrix(event="push").returncode, 0)
            self.assertEqual(self.result(), ["one", "two"])
            self.assertIn("require_manual_apply=true", (self.root / "output").read_text())

    def test_summary_lists_every_group_and_handles_no_targets(self):
        summary = self.root / "summary"
        summary.write_text("Existing summary\n")
        self.env["GITHUB_STEP_SUMMARY"] = str(summary)
        for number in range(7):
            path = self.root / "terraform/src/repositories" / f"repo-{number}"
            path.mkdir()
            (path / "terraform.tf").write_text("terraform {}\n")
        self.assertEqual(self.matrix(target="all").returncode, 0)
        contents = summary.read_text()
        self.assertTrue(contents.startswith("Existing summary\n"))
        self.assertIn("| グループ | 対象リポジトリ |", contents)
        for shard in self.shards():
            names = ", ".join(f"`{root}`" for root in shard["repositories"])
            self.assertIn(f"| {shard['id']} | {names} |", contents)
        summary.write_text("")
        self.assertEqual(self.matrix(event="push").returncode, 0)
        self.assertIn("対象リポジトリはありません。", summary.read_text())

    def test_invalid_manual_targets(self):
        for target in ("", "unknown", "../one", "one;echo bad"):
            self.assertNotEqual(self.matrix(target=target).returncode, 0)

    def test_push_single_root(self):
        self.commit_file("terraform/src/repositories/one/main.tf")
        self.assertEqual(self.matrix(event="push").returncode, 0)
        self.assertEqual(self.result(), ["one"])
        self.assertIn("require_manual_apply=false", (self.root / "output").read_text())

    def test_pr_module_change_selects_all(self):
        self.commit_file("terraform/modules/repository/example.tf")
        self.assertEqual(self.matrix(event="pull_request").returncode, 0)
        self.assertEqual(self.result(), ["one", "two"])
        self.assertIn("require_manual_apply=true", (self.root / "output").read_text())

    def test_unrelated_change_selects_none(self):
        self.commit_file("README.md")
        self.assertEqual(self.matrix(event="push").returncode, 0)
        self.assertEqual(self.result(), ["_empty"])

    def archive_config(self, value="true", repo="one"):
        path = self.root / "terraform/src/repositories" / repo / "main.tf"
        path.write_text('module "this" {\n'
                        '  source = "../../../modules/repository"\n'
                        f'  archived = {value}\n'
                        '}\n')
        self.git("add", str(path.relative_to(self.root)))
        self.git("commit", "-qm", "archive configuration")

    def test_shared_changes_skip_existing_archived_roots(self):
        self.archive_config("true # archived")
        self.base = self.git("rev-parse", "HEAD").stdout.strip()
        self.commit_file("terraform/modules/repository/example.tf")
        for event in ("pull_request", "push"):
            self.assertEqual(self.matrix(event=event).returncode, 0)
            self.assertEqual(self.result(), ["two"])
            self.assertEqual(self.shards(), [{"id": 0, "repositories": ["two"]}])
            self.assertIn("require_manual_apply=true", (self.root / "output").read_text())

    def test_archived_only_changes_skip_terraform(self):
        self.archive_config()
        self.base = self.git("rev-parse", "HEAD").stdout.strip()
        self.commit_file("terraform/src/repositories/one/variables.tf")
        for event in ("pull_request", "push"):
            self.assertEqual(self.matrix(event=event).returncode, 0)
            self.assertEqual(self.result(), ["_empty"])
            self.assertEqual(self.shards(), [])

    def test_archive_transitions_remain_eligible(self):
        for value in ("true", "false", "true", "var.archived"):
            previous = self.git("rev-parse", "HEAD").stdout.strip()
            self.archive_config(value)
            for event in ("pull_request", "push"):
                self.assertEqual(self.matrix(event=event, base=previous).returncode, 0)
                self.assertEqual(self.result(), ["one"])

    def test_manual_runs_include_archived_roots(self):
        self.archive_config()
        for target, expected in (("one", ["one"]), ("all", ["one", "two"])):
            self.assertEqual(self.matrix(target=target).returncode, 0)
            self.assertEqual(self.result(), expected)

    def test_unknown_or_commented_archive_settings_remain_eligible(self):
        for index, value in enumerate(("var.archived", "false # archived = true",
                                       "false\n  /*\n  archived = true\n  */")):
            self.archive_config(value)
            self.base = self.git("rev-parse", "HEAD").stdout.strip()
            self.commit_file(f"terraform/modules/repository/example-{index}.tf")
            self.assertEqual(self.matrix(event="push").returncode, 0)
            self.assertEqual(self.result(), ["one", "two"])

    def test_archive_detection_uses_committed_head(self):
        self.archive_config()
        self.base = self.git("rev-parse", "HEAD").stdout.strip()
        self.commit_file("terraform/modules/repository/example.tf")
        path = self.root / "terraform/src/repositories/one/main.tf"
        path.write_text(path.read_text().replace("true", "false"))
        self.assertEqual(self.matrix(event="pull_request").returncode, 0)
        self.assertEqual(self.result(), ["two"])

    def test_pr_archive_detection_uses_merge_base(self):
        self.git("checkout", "-qb", "feature")
        self.archive_config()
        self.git("checkout", "-qb", "base-update", self.base)
        self.archive_config("true # base branch")
        base = self.git("rev-parse", "HEAD").stdout.strip()
        self.git("checkout", "-q", "feature")
        self.assertEqual(self.matrix(event="pull_request", base=base).returncode, 0)
        self.assertEqual(self.result(), ["one"])

    def test_missing_history_fails(self):
        self.assertNotEqual(self.matrix(event="push", base="missing").returncode, 0)

    def update_tools(self, content):
        (self.root / "mise.toml").write_text(content)
        self.git("add", "mise.toml")
        self.git("commit", "-qm", "update tools")

    def test_terraform_version_change_selects_all_without_auto_apply(self):
        self.update_tools('[tools]\nterraform = "1.16.5"\nnode = "24"\n')
        for event in ("pull_request", "push"):
            self.assertEqual(self.matrix(event=event).returncode, 0)
            self.assertEqual(self.result(), ["one", "two"])
            self.assertIn("require_manual_apply=true", (self.root / "output").read_text())

    def test_node_and_pnpm_change_does_not_select_roots(self):
        self.update_tools('[tools]\nterraform = "1.16.4"\nnode = "26"\n'
                          '"aqua:pnpm/pnpm" = "12.7.0"\n')
        self.assertEqual(self.matrix(event="pull_request").returncode, 0)
        self.assertEqual(self.result(), ["_empty"])

    def test_tfcmt_version_change_selects_all_without_auto_apply(self):
        self.update_tools('[tools]\nterraform = "1.16.4"\n'
                          '"aqua:suzuki-shunsuke/tfcmt" = "4.14.19"\n')
        for event in ("pull_request", "push"):
            self.assertEqual(self.matrix(event=event).returncode, 0)
            self.assertEqual(self.result(), ["one", "two"])
            self.assertIn("require_manual_apply=true", (self.root / "output").read_text())

    def test_committed_terraform_version_is_not_hidden_by_worktree(self):
        self.update_tools('[tools]\nterraform = "1.16.5"\n')
        (self.root / "mise.toml").write_text('[tools]\nterraform = "1.16.4"\n')
        self.assertEqual(self.matrix(event="pull_request").returncode, 0)
        self.assertEqual(self.result(), ["one", "two"])

    def test_removed_mise_config_selects_all(self):
        self.git("rm", "mise.toml")
        self.git("commit", "-qm", "remove tools")
        self.assertEqual(self.matrix(event="push").returncode, 0)
        self.assertEqual(self.result(), ["one", "two"])

    def test_pr_compares_terraform_version_with_merge_base(self):
        self.git("checkout", "-qb", "feature")
        self.update_tools('[tools]\nterraform = "1.16.4"\nnode = "26"\n')
        self.git("checkout", "-qb", "base-update", self.base)
        self.update_tools('[tools]\nterraform = "1.16.5"\nnode = "24"\n')
        base = self.git("rev-parse", "HEAD").stdout.strip()
        self.git("checkout", "-q", "feature")
        self.assertEqual(self.matrix(event="pull_request", base=base).returncode, 0)
        self.assertEqual(self.result(), ["_empty"])

    def scan(self, *files, all_files=False):
        env = dict(self.env)
        if all_files:
            env["BETTERLEAKS_ALL_FILES"] = "true"
        return subprocess.run(["bash", str(PROJECT / "scripts/lint/betterleaks.sh"),
                               *files], cwd=self.root, env=env, text=True,
                              capture_output=True)

    def stage_secret(self):
        # Generate a synthetic token at runtime, never store a real credential.
        token = "gh" + "p_" + "a1B2c3D4e5F6g7H8i9J0k1L2m3N4o5P6q7R8"
        (self.root / "secret file.txt").write_text("token=" + token + "\n")
        self.git("add", "secret file.txt")

    def test_partially_staged_secret_is_rejected(self):
        self.stage_secret()
        (self.root / "secret file.txt").write_text("safe\n")
        (self.root / "other.txt").write_text("safe\n")
        self.git("add", "other.txt")
        self.assertEqual(self.scan("other.txt", "secret file.txt").returncode, 1)

    def test_removed_worktree_file_does_not_hide_staged_secret(self):
        self.stage_secret()
        (self.root / "secret file.txt").unlink()
        self.assertEqual(self.scan("secret file.txt").returncode, 1)

    def test_all_files_checks_worktree_and_ignores_unlisted_files(self):
        (self.root / "safe.txt").write_text("safe\n")
        self.stage_secret()
        self.assertEqual(self.scan("safe.txt", all_files=True).returncode, 0)
        self.assertEqual(self.scan("safe.txt", "secret file.txt", all_files=True).returncode, 1)

    def test_empty_scan_succeeds(self):
        self.assertEqual(self.scan().returncode, 0)

    def cleanup_comments(self, comments, failure=""):
        """複数ページの GitHub API を模擬して実際の削除スクリプトを実行する。"""
        (self.root / "comments.json").write_text(json.dumps(comments))
        gh = self.root / "gh"
        gh.write_text(textwrap.dedent('''\
            #!/usr/bin/env python3
            import json
            import os
            from pathlib import Path
            import subprocess
            import sys
            args = sys.argv[1:]
            if "DELETE" in args:
                if os.environ["API_FAILURE"] == "delete":
                    sys.exit(1)
                with Path("deleted").open("a") as output:
                    output.write(args[-1] + "\\n")
            else:
                if os.environ["API_FAILURE"] == "list":
                    sys.exit(1)
                comments = json.loads(Path("comments.json").read_text())
                pages = [comments[i:i+30] for i in range(0, len(comments), 30)]
                if "--paginate" not in args:
                    pages = pages[:1]
                query = args[args.index("--jq") + 1]
                for index, page in enumerate(pages):
                    if index > 0 and os.environ["API_FAILURE"] == "later-page":
                        sys.exit(1)
                    subprocess.run(["jq", "-r", query], input=json.dumps(page),
                                   text=True, check=True)
            '''))
        gh.chmod(0o755)
        workflow = (PROJECT / ".github/workflows/terraform-github.yml").read_text()
        cleanup = workflow.split("  delete-nochange-comments:\n", 1)[1]
        cleanup = cleanup.split("  workflow-result:\n", 1)[0]
        script = textwrap.dedent(cleanup.split("        run: |\n", 1)[1])
        env = dict(self.env, PATH=str(self.root) + os.pathsep + os.environ["PATH"],
                   GH_REPO="owner/repository", PR_NUMBER="123", API_FAILURE=failure)
        result = subprocess.run(["bash", "-e", "-o", "pipefail", "-c", script],
                                cwd=self.root, env=env, text=True, capture_output=True)
        deleted = self.root / "deleted"
        return result, deleted.read_text().splitlines() if deleted.exists() else []

    def test_cleanup_deletes_nochange_bot_plans_on_later_pages_only(self):
        """30件を超えても対象を削除し、人の発言・警告・変更結果は保持する。"""
        body = ('<pre><code>No changes. Your infrastructure matches the configuration.'
                '</code></pre>\n<!-- github-comment: '
                '{"Program":"tfcmt","Command":"plan","WorkflowName":"Terraform - GitHub"} -->')
        comments = [{"id": i, "user": {"login": "person"}, "body": "discussion"}
                    for i in range(30)]
        for index, (author, content) in enumerate([
                ("github-actions[bot]", body), ("person", body),
                ("github-actions[bot]", body + '\n## :warning: Warnings'),
                ("github-actions[bot]", body + '<details>Drift</details>'),
                ("github-actions[bot]", body.replace('"plan"', '"apply"')),
                ("github-actions[bot]", "Plan: 1 to add, 0 to change, 0 to destroy."),
                ("github-actions[bot]", body)], 30):
            comments.append({"id": index, "user": {"login": author}, "body": content})
        result, deleted = self.cleanup_comments(comments)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(deleted, ["repos/owner/repository/issues/comments/30",
                                   "repos/owner/repository/issues/comments/36"])

    def test_cleanup_reports_api_failures_and_accepts_empty_comments(self):
        """API の一覧取得と削除の失敗を成功扱いにしない。"""
        result, deleted = self.cleanup_comments([])
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(deleted, [])
        result, _ = self.cleanup_comments([], failure="list")
        self.assertNotEqual(result.returncode, 0)
        comment = {"id": 1, "user": {"login": "github-actions[bot]"},
                   "body": '<pre><code>No changes. Your infrastructure matches the '
                           'configuration.</code></pre> <!-- github-comment: '
                           '{"Program":"tfcmt","Command":"plan","WorkflowName":"Terraform - GitHub"} -->'}
        result, _ = self.cleanup_comments([comment], failure="delete")
        self.assertNotEqual(result.returncode, 0)

    def test_cleanup_fetches_all_pages_before_deleting_comments(self):
        """後続ページの取得失敗時は、取得済みページのコメントも削除しない。"""
        comment = {"id": 1, "user": {"login": "github-actions[bot]"},
                   "body": '<pre><code>No changes. Your infrastructure matches the '
                           'configuration.</code></pre> <!-- github-comment: '
                           '{"Program":"tfcmt","Command":"plan","WorkflowName":"Terraform - GitHub"} -->'}
        comments = [comment] + [{"id": i + 2, "user": {"login": "person"},
                                 "body": "discussion"} for i in range(30)]
        result, deleted = self.cleanup_comments(comments, failure="later-page")
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(deleted, [])

    def workflow_result(self, matrix='["one"]', terraform="success",
                        lint="success", selection="success"):
        workflow = (PROJECT / ".github/workflows/terraform-github.yml").read_text()
        script = textwrap.dedent(workflow.rsplit("        run: |\n", 1)[1])
        env = dict(self.env, TARGET_MATRIX=matrix, TERRAFORM_RESULT=terraform,
                   LINT_RESULT=lint, MATRIX_RESULT=selection)
        return subprocess.run(["bash", "-e", "-c", script], env=env,
                              text=True, capture_output=True).returncode

    def test_workflow_accepts_no_targets(self):
        self.assertEqual(self.workflow_result(matrix='["_empty"]',
                                              terraform="skipped"), 0)

    def test_workflow_accepts_successful_targets(self):
        self.assertEqual(self.workflow_result(), 0)

    def test_workflow_rejects_failed_or_cancelled_jobs(self):
        for state in ("failure", "cancelled", "skipped"):
            self.assertNotEqual(self.workflow_result(terraform=state), 0)
            self.assertNotEqual(self.workflow_result(matrix='["_empty"]', lint=state), 0)
            self.assertNotEqual(self.workflow_result(matrix='["_empty"]', selection=state), 0)

    def test_cleanup_removes_only_our_successful_no_resource_change_plans(self):
        zero = "<pre><code>Plan: 0 to add, 0 to change, 0 to destroy.</code></pre>"
        no_changes = "<pre><code>No changes. Your infrastructure matches the configuration.</code></pre>"

        def comment(identifier, body, author="github-actions[bot]", **metadata):
            marker = dict(Program="tfcmt", Command="plan", WorkflowName="Terraform - GitHub")
            marker.update(metadata)
            return dict(id=identifier, user=dict(login=author),
                        body=body + "\n<!-- github-comment: " + json.dumps(marker) + " -->")

        pages = [[comment(1, no_changes),
                  comment(2, zero + "\n# resource has moved to resource[0]"),
                  comment(3, zero + "\n## :warning: Warnings"),
                  comment(4, zero + "\nWarning: deprecated argument"),
                  comment(5, zero + "\nError: plan failed"),
                  comment(6, "## :x: Plan Result\n" + zero),
                  comment(7, zero, author="human"),
                  comment(8, zero, Program="another-tool"),
                  comment(9, zero, Command="apply"),
                  comment(10, zero, WorkflowName="Other workflow"),
                  comment(11, "<pre><code>Plan: 1 to add, 0 to change, 0 to destroy.</code></pre>"),
                  dict(id=12, user=dict(login="github-actions[bot]"), body=no_changes)],
                 [comment(31, zero), comment(32, no_changes + "\n## :warning: Errors"),
                  comment(33, zero + "\nObjects have changed outside of Terraform")]]
        result, deleted = self.cleanup_comments([comment for page in pages for comment in page])
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(deleted, ["repos/owner/repository/issues/comments/1",
                                   "repos/owner/repository/issues/comments/2",
                                   "repos/owner/repository/issues/comments/31"])


class RuleGenerationTests(unittest.TestCase):
    """LLM の入口が原本を参照し、更新漏れを検出することを検証する。"""

    def generate(self, output, check=False):
        command = ["pnpm", "exec", "rulesync", "generate",
                   "--config", str(PROJECT / "rulesync.jsonc"),
                   "--input-roots", str(PROJECT / ".rulesync"),
                   "--output-roots", str(output)]
        if check:
            command.append("--check")
        return subprocess.run(command, cwd=PROJECT, text=True, capture_output=True)

    def test_entries_reference_origins_without_recreating_retired_files(self):
        with tempfile.TemporaryDirectory() as temp:
            output = Path(temp)
            result = self.generate(output)
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            origins = ("project", "development", "coding-standards", "documentation")
            for name in ("AGENTS.md", ".github/copilot-instructions.md"):
                content = (output / name).read_text()
                for origin in origins:
                    self.assertIn(f"docs/rules/{origin}.md", content)
            for origin in origins:
                self.assertTrue((PROJECT / f"docs/rules/{origin}.md").is_file())
                for name in (f".claude/rules/{origin}.md",
                             f".github/instructions/{origin}.instructions.md",
                             f".devin/rules/{origin}.md"):
                    content = (output / name).read_text()
                    self.assertIn(f"docs/rules/{origin}.md", content)
                    self.assertNotIn("origin.md", content)
            self.assertFalse((PROJECT / "docs/rules/origin.md").exists())
            for name in ("CLAUDE.md", "GEMINI.md", ".mcp.json"):
                self.assertFalse((output / name).exists())
            self.assertEqual(self.generate(output, check=True).returncode, 0)
            (output / "AGENTS.md").write_text("古いルール\n")
            self.assertNotEqual(self.generate(output, check=True).returncode, 0)


    def test_json_formatter_formats_files_with_project_ignore_rules(self):
        with tempfile.TemporaryDirectory(dir=PROJECT) as temp:
            target = Path(temp) / "example.json"
            target.write_text('{"name":"検証","enabled":true}\n')
            command = ["pnpm", "exec", "oxfmt", str(target)]
            unformatted = subprocess.run(command + ["--check"], cwd=PROJECT,
                                         text=True, capture_output=True)
            self.assertEqual(unformatted.returncode, 1,
                             unformatted.stdout + unformatted.stderr)
            formatted = subprocess.run(command + ["--write"], cwd=PROJECT,
                                       text=True, capture_output=True)
            self.assertEqual(formatted.returncode, 0,
                             formatted.stdout + formatted.stderr)
            self.assertIn('"name": "検証"', target.read_text())
            self.assertEqual(json.loads(target.read_text()),
                             {"name": "検証", "enabled": True})
            checked = subprocess.run(command + ["--check"], cwd=PROJECT,
                                     text=True, capture_output=True)
            self.assertEqual(checked.returncode, 0, checked.stdout + checked.stderr)


if __name__ == "__main__":
    unittest.main()
