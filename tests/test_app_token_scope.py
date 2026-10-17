"""Regressions for read-only plans and repository-scoped apply credentials."""
import importlib.util
from pathlib import Path
import unittest

spec = importlib.util.spec_from_file_location(
    "app_token_scope", Path(__file__).resolve().parents[1] / ".github/scripts/app_token_scope.py")
policy = importlib.util.module_from_spec(spec)
spec.loader.exec_module(policy)


class AppTokenScopeTests(unittest.TestCase):
    def scope(self, roots=("local-video-gen-lab", "tts-partner"),
              event="pull_request", ref="refs/pull/1/merge", manual="false", shared="false"):
        return policy.token_scope(list(roots), event, ref, manual, shared)

    def test_pr_cannot_request_write_even_with_apply_input(self):
        scope = self.scope(manual="true")
        self.assertEqual(scope["administration"], "read")
        self.assertEqual(scope["contents"], "read")
        self.assertEqual(scope["repositories"], "local-video-gen-lab,tts-partner")
        self.assertTrue(all(scope[p] == "" for p in ("environments", "secrets", "variables")))

    def test_shared_change_push_is_plan_only(self):
        self.assertEqual(self.scope(event="push", ref="refs/heads/main", shared="true")
                         ["administration"], "read")

    def test_main_apply_requests_write(self):
        for event, manual in (("push", "false"), ("workflow_dispatch", "true")):
            scope = self.scope(event=event, ref="refs/heads/main", manual=manual)
            self.assertEqual(scope["administration"], "write")
            self.assertEqual(scope["contents"], "read")

    def test_non_main_apply_is_rejected(self):
        for ref in ("refs/heads/feature", "refs/tags/main", ""):
            with self.assertRaises(ValueError):
                self.scope(event="workflow_dispatch", ref=ref, manual="true")

    def test_kazokubi_release_permissions_only_write_on_manual_apply(self):
        scope = self.scope(roots=("kazokubi",), event="push", ref="refs/heads/main")
        self.assertEqual(scope["administration"], "read")
        self.assertEqual(scope["secrets"], "read")
        scope = self.scope(roots=("kazokubi", "media-server"), event="push", ref="refs/heads/main")
        self.assertEqual(scope["administration"], "write")
        self.assertEqual(scope["secrets"], "read")
        scope = self.scope(roots=("kazokubi",), event="workflow_dispatch",
                           ref="refs/heads/main", manual="true")
        self.assertTrue(all(scope[p] == "write" for p in ("environments", "secrets", "variables")))

    def test_untrusted_repository_names_and_policies_are_rejected(self):
        for roots in ([], ["one", "one"], ["../one"], ["one\npermissions=write"], [3], "one"):
            with self.assertRaises(ValueError):
                policy.token_scope(roots, "pull_request", "refs/pull/1/merge", "false", "false")
        with self.assertRaises(ValueError):
            self.scope(event="pull_request_target")
        with self.assertRaises(ValueError):
            self.scope(shared="yes")
