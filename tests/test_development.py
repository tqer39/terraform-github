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

    def test_manual_single_root(self):
        self.assertEqual(self.matrix().returncode, 0)
        self.assertEqual(self.result(), ["one"])

    def test_manual_all_roots(self):
        self.assertEqual(self.matrix(target="all").returncode, 0)
        self.assertEqual(self.result(), ["one", "two"])

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
