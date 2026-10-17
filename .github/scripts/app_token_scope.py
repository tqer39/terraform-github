"""Limit the Terraform installation token to this shard and its operation."""
import json
import os
from pathlib import Path
import re


def token_scope(roots, event, ref, manual_apply, shared_change):
    if (not isinstance(roots, list) or not roots
            or any(not isinstance(root, str)
                   or not re.fullmatch(r"[a-zA-Z0-9][a-zA-Z0-9_-]*", root) for root in roots)
            or len(set(roots)) != len(roots)):
        raise ValueError("Invalid repository scope")
    if event not in ("pull_request", "push", "workflow_dispatch"):
        raise ValueError("Unsupported event")
    if manual_apply not in ("true", "false") or shared_change not in ("true", "false"):
        raise ValueError("Invalid apply policy")
    applying = (event == "workflow_dispatch" and manual_apply == "true"
                or event == "push" and shared_change == "false"
                and any(root != "kazokubi" for root in roots))
    if applying and ref != "refs/heads/main":
        raise ValueError("Apply requires refs/heads/main")
    # Only kazokubi manages environments, Actions secrets and variables.
    release_level = ("write" if event == "workflow_dispatch" and applying else "read")
    return {
        "repositories": ",".join(roots),
        # GitHub omits merge settings and ruleset bypasses without admin write,
        # even on GET. Read-only credentials would produce a false plan.
        "administration": "write",
        "contents": "read",
        "actions": "read" if "kazokubi" in roots else "",
        **{permission: release_level if "kazokubi" in roots else ""
           for permission in ("environments", "secrets", "variables")},
    }


if __name__ == "__main__":
    roots = (json.loads(os.environ["REPOSITORIES"]) if "REPOSITORIES" in os.environ
             else [os.environ["REPOSITORY"]])
    scope = token_scope(roots, os.environ["EVENT_NAME"],
                        os.environ["GITHUB_REF"], os.environ["MANUAL_APPLY"],
                        os.environ["REQUIRE_MANUAL_APPLY"])
    for repository in scope["repositories"].split(","):
        if not Path(f"terraform/src/repositories/{repository}/terraform.tf").is_file():
            raise ValueError("Unknown Terraform root")
    with open(os.environ["GITHUB_OUTPUT"], "a", encoding="utf-8") as output:
        output.writelines(f"{key}={value}\n" for key, value in scope.items())
