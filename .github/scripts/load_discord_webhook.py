"""Read the Discord state and verify the Webhook without emitting credentials."""

import json
import os
import re
import subprocess
import sys
import urllib.error
import urllib.request

STATE_URI = "s3://terraform-tfstate-tqer39-072693953877-ap-northeast-1/kazokubi/infra/discord.tfstate"
URL_PATTERN = re.compile(r"https://discord\.com/api/webhooks/([0-9]+)/([A-Za-z0-9_-]+)")


class ConfigurationError(Exception):
    """A safe error message that never includes a response or credential."""


def read_state():
    try:
        result = subprocess.run(
            ["aws", "s3", "cp", STATE_URI, "-", "--only-show-errors"],
            capture_output=True, check=True, timeout=60,
        )
    except subprocess.CalledProcessError as error:
        # Only classify known codes; raw AWS stderr may contain credentials.
        stderr = error.stderr or b""
        if isinstance(stderr, bytes):
            stderr = stderr.decode("utf-8", errors="replace")
        codes = re.findall(r"\(([^()]+)\) (?:occurred )?when calling", stderr)
        if any(code in ("404", "NoSuchKey", "NotFound") for code in codes):
            raise ConfigurationError("Discord state was not found in S3 (404). Complete the initial Discord apply with the configured backend.") from None
        if any(code in ("403", "AccessDenied", "Forbidden") for code in codes):
            raise ConfigurationError("S3 denied access to Discord state (403). Check the CI role's s3:GetObject and s3:ListBucket permissions; without ListBucket, a missing state can also return 403.") from None
        raise ConfigurationError("AWS CLI could not read Discord state. Check CI credentials, region and S3 access.") from None
    except subprocess.TimeoutExpired:
        raise ConfigurationError("Reading Discord state from S3 timed out.") from None
    try:
        return json.loads(result.stdout)
    except ValueError:
        raise ConfigurationError("Discord state in S3 is not valid JSON.") from None


def webhook_from_state(state):
    if not isinstance(state, dict):
        raise ConfigurationError("Discord state is invalid.")
    outputs = state.get("outputs", {})
    output = outputs.get("webhook_url", {}) if isinstance(outputs, dict) else {}
    value = output.get("value") if isinstance(output, dict) else None
    if not isinstance(value, str) or not URL_PATTERN.fullmatch(value):
        raise ConfigurationError("Discord state has no valid webhook_url output; complete the initial Discord apply.")
    return value


class NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, new_url):
        return None


def verify_webhook(url, open_url=None):
    match = URL_PATTERN.fullmatch(url)
    if not match:
        raise ConfigurationError("Invalid Discord Webhook URL.")
    request = urllib.request.Request(url, headers={"User-Agent": "kazokubi-terraform-ci/1.0"})
    try:
        open_url = open_url or urllib.request.build_opener(NoRedirect()).open
        with open_url(request, timeout=20) as response:
            data = json.loads(response.read(65536))
    except (urllib.error.URLError, OSError, ValueError):
        raise ConfigurationError("Discord Webhook existence check failed; check the initial apply or recreate the managed Webhook.") from None
    if not isinstance(data, dict) or data.get("id") != match[1] or not data.get("channel_id"):
        raise ConfigurationError("Discord Webhook response did not match the saved output.")


def main():
    try:
        url = webhook_from_state(read_state())
        # Mask both the full URL and the token before any network operation.
        print(f"::add-mask::{url}", flush=True)
        print(f"::add-mask::{URL_PATTERN.fullmatch(url)[2]}", flush=True)
        verify_webhook(url)
        with open(os.environ["GITHUB_ENV"], "a", encoding="utf-8") as env_file:
            env_file.write(f"TF_VAR_discord_webhook_url={url}\n")
        print("Discord Webhook exists; passed its URL to Terraform as a sensitive variable.")
    except ConfigurationError as error:
        print(f"::error::{error}", file=sys.stderr)
        return 1
    except (subprocess.SubprocessError, OSError, ValueError):
        # stderr from AWS and exception repr may include sensitive state/URLs.
        print("::error::Cannot load a valid existing Discord Webhook from S3. Check state access and the initial Discord apply.", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
