"""Exercise shard execution with fake CLIs, never access state or apply resources."""
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

PROJECT = Path(__file__).resolve().parents[1]


class ShardTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name)
        self.bin = self.root / "bin"
        self.bin.mkdir()
        for name in ("one", "two", "three", "family-schedule"):
            directory = self.root / "terraform/src/repositories" / name
            directory.mkdir(parents=True)
            (directory / "terraform.tf").write_text("terraform {}\n")
            # A stale plan must never be applied after a failed fresh plan.
            (directory / "tfplan").write_text("stale")
        self.cli("terraform", '''
root="$(basename "$PWD")"
operation="$1"
echo "$root terraform $*" >> "$CALLS"
[[ "${FAIL:-}" != "$root:$operation" ]] || exit 23
if [[ "$operation" == init ]]; then
    [[ "$*" == *'-input=false -lockfile=readonly'* ]] || exit 24
    [[ "$*" != *'-upgrade'* ]] || exit 25
fi
if [[ "$operation" == plan ]]; then
    echo "$root" > tfplan
fi
if [[ "$operation" == apply ]]; then
    [[ "$*" == 'apply -input=false tfplan' ]] || exit 26
    [[ "$(cat tfplan)" == "$root" ]] || exit 27
fi
''')
        self.cli("tflint", '''
root="$(basename "$PWD")"
echo "$root tflint $*" >> "$CALLS"
[[ "${FAIL:-}" != "$root:tflint" ]] || exit 23
''')
        self.cli("tfcmt", '''
echo "$(basename "$PWD") tfcmt $*" >> "$CALLS"
while [[ "$1" != -- ]]; do shift; done
shift
exec "$@"
''')
        self.cli("gh", '''
[[ "${RATE_FAIL:-false}" != true ]] || exit 1
echo '{"resources":{"core":{"used":10,"remaining":4990,"reset":123}}}'
''')
        self.env = dict(os.environ, PATH=str(self.bin) + os.pathsep + os.environ["PATH"],
                        CALLS=str(self.root / "calls"),
                        METRICS_DIR=str(self.root / "metrics"),
                        GITHUB_STEP_SUMMARY=str(self.root / "summary"),
                        REQUIRE_MANUAL_APPLY="false", MANUAL_APPLY="false",
                        EVENT_NAME="pull_request")

    def tearDown(self):
        self.temp.cleanup()

    def cli(self, name, code):
        path = self.bin / name
        path.write_text("#!/usr/bin/env bash\nset -euo pipefail\n" + code)
        path.chmod(0o755)

    def run_shard(self, roots=("one", "two"), **env):
        return subprocess.run(
            ["bash", str(PROJECT / ".github/scripts/terraform_shard.sh")],
            cwd=self.root, env=dict(self.env, REPOSITORIES=json.dumps(roots), **env),
            text=True, capture_output=True)

    def calls(self):
        return (self.root / "calls").read_text().splitlines()

    def test_single_root_preserves_plan_and_comment_target(self):
        result = self.run_shard(("one",))
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("one terraform plan -input=false -no-color -out=tfplan", self.calls())
        self.assertIn("one tfcmt --var target:one plan -patch -skip-no-changes -- terraform plan "
                      "-input=false -no-color -out=tfplan", self.calls())
        self.assertFalse(any(" terraform apply " in call for call in self.calls()))

    def test_roots_run_serially_and_keep_separate_results(self):
        result = self.run_shard(("one", "two", "three"))
        self.assertEqual(result.returncode, 0, result.stderr)
        names = [call.split()[0] for call in self.calls()]
        self.assertEqual(names, sorted(names, key=("one", "two", "three").index))
        metrics = [json.loads(line) for line in
                   (self.root / "metrics/roots.jsonl").read_text().splitlines()]
        self.assertEqual([r["root"] for r in metrics], ["one", "two", "three"])
        self.assertTrue(all(r["exit_code"] == 0 and r["stage"] == "complete"
                            for r in metrics))
        self.assertIn("| two | complete | 0 |", (self.root / "summary").read_text())
        for name in ("one", "two", "three"):
            self.assertEqual((self.root / "terraform/src/repositories" / name /
                              "tfplan").read_text().strip(), name)

    def test_every_failure_stage_continues_other_roots_and_fails_shard(self):
        for stage in ("fmt", "init", "validate", "tflint", "plan", "apply"):
            with self.subTest(stage=stage):
                (self.root / "calls").write_text("")
                result = self.run_shard(FAIL="one:" + stage,
                                        EVENT_NAME="workflow_dispatch", MANUAL_APPLY="true")
                self.assertNotEqual(result.returncode, 0)
                metrics = [json.loads(line) for line in
                           (self.root / "metrics/roots.jsonl").read_text().splitlines()]
                self.assertEqual(metrics[0]["stage"], stage)
                self.assertEqual(metrics[0]["exit_code"], 23)
                self.assertEqual(metrics[1]["stage"], "complete")
                self.assertIn("two terraform apply -input=false tfplan", self.calls())
                if stage != "apply":
                    self.assertFalse(any(call.startswith("one terraform apply")
                                         for call in self.calls()))

    def test_apply_policy_for_pr_push_and_manual_single_and_all(self):
        scenarios = (("pull_request", "false", "true", False),
                     ("push", "false", "false", True),
                     ("push", "true", "true", False),
                     ("workflow_dispatch", "true", "false", False),
                     ("workflow_dispatch", "true", "true", True))
        for roots in (("one",), ("one", "two", "three")):
            for event, shared, manual, expected in scenarios:
                with self.subTest(roots=roots, event=event, manual=manual):
                    (self.root / "calls").write_text("")
                    result = self.run_shard(roots, EVENT_NAME=event,
                                            REQUIRE_MANUAL_APPLY=shared, MANUAL_APPLY=manual)
                    self.assertEqual(result.returncode, 0, result.stderr)
                    applies = [call for call in self.calls() if " terraform apply " in call]
                    self.assertEqual(len(applies), len(roots) if expected else 0)

    def test_kazokubi_only_applies_on_explicit_manual_run(self):
        for event, manual, expected in (("push", "false", False),
                                        ("pull_request", "true", False),
                                        ("workflow_dispatch", "false", False),
                                        ("workflow_dispatch", "true", True)):
            with self.subTest(event=event, manual=manual):
                (self.root / "calls").unlink(missing_ok=True)
                result = self.run_shard(("family-schedule",), EVENT_NAME=event, MANUAL_APPLY=manual)
                self.assertEqual(result.returncode, 0, result.stderr)
                applies = [call for call in self.calls() if " terraform apply " in call]
                self.assertEqual(bool(applies), expected)

    def test_invalid_batch_is_rejected_before_any_apply(self):
        for roots in (("one", "../two"), ("one", "missing"), ("one", "one"), (),
                      (123,), "one"):
            result = self.run_shard(roots, EVENT_NAME="workflow_dispatch", MANUAL_APPLY="true")
            self.assertNotEqual(result.returncode, 0)
            self.assertFalse((self.root / "calls").exists())

    def test_missing_rate_snapshot_does_not_hide_terraform_failure(self):
        self.assertNotEqual(self.run_shard(FAIL="one:plan", RATE_FAIL="true").returncode, 0)
        self.assertEqual(json.loads((self.root / "metrics/rate-limit-after.json").read_text()),
                         {"unavailable": True})
        self.assertEqual(self.run_shard(RATE_FAIL="true").returncode, 0)


class PlanCommentCLITests(unittest.TestCase):
    def test_real_tfcmt_accepts_plan_flags_and_preserves_command_result(self):
        """CI と同じ実バイナリでオプション互換性と保存 plan・失敗伝播を確認する。"""
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            env = dict(os.environ)
            # Local-file output never posts to GitHub; use no real credential.
            env["GITHUB_TOKEN"] = "unused-local-output"
            for status, output in ((0, "No changes. Your infrastructure matches the configuration."),
                                   (0, "Plan: 0 to add, 0 to change, 0 to destroy."),
                                   (0, "Plan: 1 to add, 0 to change, 0 to destroy."),
                                   (1, "Error: synthetic plan failure")):
                with self.subTest(status=status, output=output):
                    plan = root / "tfplan"
                    plan.unlink(missing_ok=True)
                    result = subprocess.run(
                        ["tfcmt", "--output", str(root / "comment.md"),
                         "--owner", "owner", "--repo", "repo", "--pr", "123",
                         "--var", "target:one", "plan", "-patch", "-skip-no-changes", "--",
                         "bash", "-c", 'printf "%s\\n" "$1"; echo saved > tfplan; exit "$2"',
                         "fixture", output, str(status)],
                        cwd=root, env=env, text=True, capture_output=True)
                    self.assertEqual(result.returncode, status, result.stderr)
                    self.assertEqual(plan.read_text(), "saved\n")


class MetricsTests(unittest.TestCase):
    def test_wall_time_and_runner_seconds_are_different(self):
        import runpy
        summarize = runpy.run_path(str(PROJECT / ".github/scripts/ci_metrics.py"))["summarize"]
        run = {"id": 1, "created_at": "2026-10-10T00:00:00Z"}
        jobs = [
            {"name": "terraform (0)", "started_at": "2026-10-10T00:00:10Z",
             "completed_at": "2026-10-10T00:01:10Z", "conclusion": "success"},
            {"name": "terraform (1)", "started_at": "2026-10-10T00:00:20Z",
             "completed_at": "2026-10-10T00:01:00Z", "conclusion": "failure"},
            {"name": "workflow-result", "started_at": "2026-10-10T00:01:15Z",
             "completed_at": "2026-10-10T00:01:20Z", "conclusion": "failure"}]
        result = summarize(run, [{"jobs": jobs[:1]}, {"jobs": jobs[1:]}])
        self.assertEqual(result["workflow_seconds"], 80)
        self.assertEqual(result["terraform_wall_seconds"], 60)
        self.assertEqual(result["terraform_runner_seconds"], 100)
        self.assertEqual(result["conclusions"], ["failure", "success"])
        rerun = dict(run, run_attempt=2, run_started_at="2026-10-10T00:00:05Z")
        for job in jobs:
            job["run_attempt"] = 2
        self.assertEqual(summarize(rerun, [{"jobs": jobs}])["workflow_seconds"], 75)
        with self.assertRaises(ValueError):
            summarize(dict(run, run_attempt=2), [{"jobs": jobs}])
        for job in jobs:
            job["run_attempt"] = 1
        jobs[0]["run_attempt"] = 2
        with self.assertRaises(ValueError):
            summarize(run, [{"jobs": jobs}])
        jobs[0]["completed_at"] = None
        with self.assertRaises(ValueError):
            summarize(run, [{"jobs": jobs}])


if __name__ == "__main__":
    unittest.main()
