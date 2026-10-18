"""Regressions for scoped, fail-closed API key distribution."""
import importlib.util
import json
from pathlib import Path
import subprocess
import unittest
from unittest.mock import patch

PROJECT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location(
    "distribution", PROJECT / "scripts/set_repository_secrets.py")
distribution = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(distribution)


class SecretDistributionTests(unittest.TestCase):
    def setUp(self):
        self.calls = []
        self.pages = [{"repositories": [{"full_name": "sample/one"}]},
                      {"repositories": [{"full_name": "sample/two"}]}]
        self.fail = None

    def gh(self, arguments, *, value=None):
        self.calls.append((arguments, value))
        if arguments == self.fail:
            raise RuntimeError("operation failed")
        return json.dumps(self.pages) if arguments[1] == "--paginate" else "{}"

    def run_distribution(self, names="one,two", dry_run="false", key="test-value"):
        distribution.distribute("sample", names, dry_run, key, gh=self.gh)

    def writes(self):
        return [call for call in self.calls if call[0][0] == "secret"]

    def test_dry_run_checks_all_destinations_without_key_or_writes(self):
        self.run_distribution(dry_run="true", key="")
        self.assertEqual(self.writes(), [])
        self.assertEqual(len(self.calls), 3)

    def test_only_api_key_is_written_via_stdin_after_all_probes(self):
        self.run_distribution()
        self.assertEqual(self.writes(), [
            (["secret", "set", "OPENROUTER_API_KEY", "--repo", "sample/one"], "test-value"),
            (["secret", "set", "OPENROUTER_API_KEY", "--repo", "sample/two"], "test-value"),
        ])
        self.assertTrue(all(value is None for _, value in self.calls[:3]))

    def test_invalid_allowlists_fail_before_network_access(self):
        for names in ("", "one,", "one,one", "../one", "other/repo", "--one\nx",
                      "terraform-github", ".", "..", " one", "one\n,two"):
            with self.subTest(names=names), self.assertRaises(ValueError):
                self.run_distribution(names=names)
        self.assertEqual(self.calls, [])

    def test_extra_missing_wrong_owner_and_duplicate_scope_fail_closed(self):
        for repos in (["sample/one"], ["sample/one", "sample/two", "sample/three"],
                      ["sample/one", "other/two"], ["sample/one", "sample/one"]):
            self.pages = [{"repositories": [{"full_name": name} for name in repos]}]
            with self.subTest(repos=repos), self.assertRaises(ValueError):
                self.run_distribution()
            self.assertEqual(self.writes(), [])

    def test_any_destination_probe_failure_prevents_all_writes(self):
        self.fail = ["api", "repos/sample/two/actions/secrets?per_page=1"]
        with self.assertRaises(RuntimeError):
            self.run_distribution()
        self.assertEqual(self.writes(), [])

    def test_missing_key_and_invalid_mode_prevent_writes(self):
        for key in ("", "  "):
            with self.assertRaises(ValueError):
                self.run_distribution(key=key)
        with self.assertRaises(ValueError):
            self.run_distribution(dry_run="yes")
        self.assertEqual(self.writes(), [])

    def test_write_failure_stops_remaining_destinations(self):
        self.fail = ["secret", "set", "OPENROUTER_API_KEY", "--repo", "sample/one"]
        with self.assertRaises(RuntimeError):
            self.run_distribution()
        self.assertEqual(len(self.writes()), 1)

    def test_gh_wrapper_never_includes_secret_in_arguments_or_remote_errors(self):
        result = subprocess.CompletedProcess([], 1, "test-value", "test-value")
        with patch.object(distribution.subprocess, "run", return_value=result) as run:
            with self.assertRaisesRegex(RuntimeError, "^GitHub operation failed$"):
                distribution.run_gh(["secret", "set", "KEY"], value="test-value")
            self.assertEqual(run.call_args.args[0], ["gh", "secret", "set", "KEY"])
            self.assertEqual(run.call_args.kwargs["input"], "test-value")

    def test_workflow_restricts_execution_and_never_distributes_app_credentials(self):
        workflow = (PROJECT / ".github/workflows/set-common-github-secrets.yml").read_text()
        self.assertNotIn("GHA_APP", workflow)
        self.assertIn("permission-secrets: write", workflow)
        self.assertIn("repositories: ${{ vars.SECRET_DISTRIBUTION_REPOSITORIES }}", workflow)
        self.assertIn("github.ref == 'refs/heads/main'", workflow)
        self.assertIn("github.triggering_actor == github.repository_owner", workflow)
        self.assertIn("persist-credentials: false", workflow)
