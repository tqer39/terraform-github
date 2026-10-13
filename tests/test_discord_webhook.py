"""Regression coverage for missing state and invalid/deleted Webhooks."""

import importlib.util
import io
import subprocess
import unittest
import urllib.error
from contextlib import redirect_stderr
from pathlib import Path
from unittest.mock import patch

SPEC = importlib.util.spec_from_file_location(
    "load_discord_webhook", Path(__file__).parents[1] / ".github/scripts/load_discord_webhook.py"
)
MODULE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MODULE)
URL = "https://discord.com/api/webhooks/123456789012345678/example-token"


class WebhookTests(unittest.TestCase):
    def test_s3_failures_are_classified_without_disclosing_error_content(self):
        for code, message in (("404", "not found"), ("NoSuchKey", "not found"),
                              ("403", "denied access"), ("AccessDenied", "denied access"),
                              ("UnknownCode", "AWS CLI could not read")):
            failure = subprocess.CalledProcessError(
                1, ["aws"], stderr=f"fatal error: An error occurred ({code}) when calling the HeadObject operation: {URL}".encode(),
            )
            with self.subTest(code=code), patch.object(MODULE.subprocess, "run", side_effect=failure):
                output = io.StringIO()
                with redirect_stderr(output):
                    self.assertEqual(MODULE.main(), 1)
                self.assertIn(message, output.getvalue())
                self.assertNotIn(URL, output.getvalue())
                self.assertNotIn("example-token", output.getvalue())

    def test_invalid_state_json_and_timeouts_have_safe_diagnostics(self):
        with patch.object(MODULE.subprocess, "run", return_value=subprocess.CompletedProcess([], 0, stdout=URL.encode())):
            with self.assertRaisesRegex(MODULE.ConfigurationError, "not valid JSON"):
                MODULE.read_state()
        with patch.object(MODULE.subprocess, "run", side_effect=subprocess.TimeoutExpired(["aws"], 60, stderr=URL)):
            with self.assertRaisesRegex(MODULE.ConfigurationError, "timed out"):
                MODULE.read_state()

    def test_missing_empty_or_external_output_is_rejected(self):
        for value in (None, "", "https://example.com/api/webhooks/123/token", URL + "\n"):
            with self.subTest(value=value), self.assertRaises(MODULE.ConfigurationError):
                MODULE.webhook_from_state({"outputs": {"webhook_url": {"value": value}}})
        with self.assertRaises(MODULE.ConfigurationError):
            MODULE.webhook_from_state({})

    def test_saved_output_is_used_and_get_does_not_send_notifications(self):
        self.assertEqual(MODULE.webhook_from_state({"outputs": {"webhook_url": {"value": URL}}}), URL)

        def fetch(request, timeout):
            self.assertEqual(request.get_method(), "GET")
            self.assertIsNone(request.data)
            self.assertEqual(timeout, 20)
            return io.BytesIO(b'{"id":"123456789012345678","channel_id":"456"}')

        MODULE.verify_webhook(URL, fetch)

    def test_deleted_webhook_error_does_not_disclose_url(self):
        def fetch(request, timeout):
            raise urllib.error.HTTPError(URL, 404, "gone", {}, None)

        with self.assertRaises(MODULE.ConfigurationError) as result:
            MODULE.verify_webhook(URL, fetch)
        self.assertNotIn("example-token", str(result.exception))
        self.assertNotIn(URL, str(result.exception))

    def test_wrong_webhook_and_non_json_responses_fail(self):
        for body in (b'{"id":"999","channel_id":"456"}', b'{}', b'null', b'not json'):
            with self.subTest(body=body), self.assertRaises(MODULE.ConfigurationError):
                MODULE.verify_webhook(URL, lambda request, timeout: io.BytesIO(body))

    def test_redirects_are_not_followed(self):
        self.assertIsNone(MODULE.NoRedirect().redirect_request(None, None, 302, "", {}, "https://example.com"))


if __name__ == "__main__":
    unittest.main()
