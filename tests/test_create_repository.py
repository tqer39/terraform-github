"""Exercise repository creation with a fake gh, never calling the GitHub API."""
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

PROJECT = Path(__file__).resolve().parents[1]


class CreateRepositoryTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name)
        gh = self.root / "gh"
        # Records each call with the token it ran under, so tests can tell the
        # installation change apart from calls using the regular gh login.
        gh.write_text('''#!/usr/bin/env bash
set -euo pipefail
echo "${GH_TOKEN:-login} $*" >> "$CALLS"
if [[ "$1 $2" == "repo view" ]]; then
    [[ "${EXISTS:-false}" == true ]]
elif [[ "$1 $2" == "api repos/tqer39/new-repo" ]]; then
    echo 42
elif [[ "$1 $2" == "api --method" ]]; then
    [[ "${PUT_FAIL:-false}" != true ]]
fi
''')
        gh.chmod(0o755)
        self.env = dict(os.environ, PATH=str(self.root) + os.pathsep + os.environ["PATH"],
                        CALLS=str(self.root / "calls"),
                        APP_INSTALLATION_GITHUB_TOKEN="install-token")
        self.env.pop("GH_TOKEN", None)

    def tearDown(self):
        self.temp.cleanup()

    def run_script(self, *args, **env):
        return subprocess.run(["bash", str(PROJECT / "scripts/create-repository.sh"), *args],
                              env=dict(self.env, **env), text=True, capture_output=True)

    def calls(self):
        path = self.root / "calls"
        return path.read_text().splitlines() if path.exists() else []

    def test_creates_repository_and_adds_it_with_the_installation_token(self):
        result = self.run_script("new-repo", "--private")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.calls(), [
            "login repo view tqer39/new-repo --json name",
            "login repo create tqer39/new-repo --private --add-readme",
            "login api repos/tqer39/new-repo --jq .id",
            "install-token api --method PUT --silent "
            "user/installations/172503992/repositories/42",
        ])

    def test_existing_repository_is_only_added(self):
        result = self.run_script("new-repo", EXISTS="true")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertNotIn("repo create", "\n".join(self.calls()))
        self.assertIn("install-token api --method PUT", self.calls()[-1])

    def test_refuses_before_creating_without_token_or_visibility(self):
        """作成後に追加できず止まる状態や、意図しない公開を防ぐ。"""
        result = self.run_script("new-repo", "--private", APP_INSTALLATION_GITHUB_TOKEN="")
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(self.calls(), [])
        result = self.run_script("new-repo")
        self.assertNotEqual(result.returncode, 0)
        self.assertNotIn("repo create", "\n".join(self.calls()))

    def test_rejects_invalid_arguments(self):
        for args in (("../other", "--private"), ("new-repo", "--internal"),
                     ("new-repo", "--private", "extra"), ()):
            result = self.run_script(*args)
            self.assertNotEqual(result.returncode, 0, args)
        self.assertEqual(self.calls(), [])

    def test_installation_failure_fails_the_task(self):
        result = self.run_script("new-repo", "--private", PUT_FAIL="true")
        self.assertNotEqual(result.returncode, 0)


if __name__ == "__main__":
    unittest.main()
