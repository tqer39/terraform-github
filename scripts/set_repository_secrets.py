"""Distribute only the API key to an explicit installation allowlist."""
import json
import os
import re
import subprocess
import sys


def run_gh(arguments, *, value=None):
    result = subprocess.run(
        ["gh", *arguments], input=value, text=True, capture_output=True,
        timeout=30, check=False,
    )
    if result.returncode:
        # Remote errors can contain credentials; never echo process output.
        raise RuntimeError("GitHub operation failed")
    return result.stdout


def distribute(owner, repositories, dry_run, key, *, gh=run_gh):
    if not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9-]*", owner):
        raise ValueError("Invalid repository owner")
    if dry_run not in ("true", "false"):
        raise ValueError("Invalid dry-run setting")
    names = repositories.split(",")
    if (not names or len(names) > 100 or len(set(names)) != len(names)
            or any(not re.fullmatch(r"[A-Za-z0-9_.-]+", name)
                   or name in (".", "..", "terraform-github") for name in names)):
        raise ValueError("Invalid repository allowlist")
    expected = {f"{owner}/{name}" for name in names}
    # Check the token's actual scope before the first write, including pagination.
    pages = json.loads(gh([
        "api", "--paginate", "--slurp", "installation/repositories?per_page=100",
    ]))
    actual = [repo["full_name"] for page in pages for repo in page["repositories"]]
    if len(actual) != len(expected) or set(actual) != expected:
        raise ValueError("Installation token scope differs from allowlist")
    # Verify every destination is reachable before writing to any destination.
    for repo in sorted(expected):
        gh(["api", f"repos/{repo}/actions/secrets?per_page=1"])
    if dry_run == "true":
        print(f"Verified {len(expected)} destinations; no secrets changed.")
        return
    if not key or not key.strip():
        raise ValueError("Missing API key")
    for repo in sorted(expected):
        gh(["secret", "set", "OPENROUTER_API_KEY", "--repo", repo], value=key)
    print(f"Updated API key in {len(expected)} destinations.")


def main():
    if len(sys.argv) != 2:
        raise ValueError("Expected repository owner argument")
    distribute(sys.argv[1], os.environ.get("SECRET_DISTRIBUTION_REPOSITORIES", ""),
               os.environ.get("DRY_RUN", "true"), os.environ.get("OPENROUTER_API_KEY", ""))


if __name__ == "__main__":
    try:
        main()
    except (ValueError, RuntimeError, KeyError, TypeError, subprocess.SubprocessError, OSError):
        sys.exit("Secret distribution failed; verify configuration and permissions.")
