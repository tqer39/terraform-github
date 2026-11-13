#!/usr/bin/env bash
# Create a personal repository and add it to the Terraform CI App installation.
# The CI installation token can neither create personal repositories nor be
# issued for a repository the App is not installed on, so this runs locally
# before the PR that imports the repository.
set -euo pipefail

owner="tqer39"
# Installation of tqer39-terraform-github on the tqer39 account (not a secret).
installation_id="172503992"

usage() {
    echo "Usage: mise run repo:create -- <repo-name> [--public|--private]" >&2
    exit 1
}

[[ $# -ge 1 && $# -le 2 ]] || usage
repo="$1"
visibility="${2:-}"
# Same rule as the Terraform roots and CI target selection: a name they reject
# (such as one with ".") could not be managed after being created here.
if [[ ! "$repo" =~ ^[a-zA-Z0-9][a-zA-Z0-9_-]*$ ]]; then
    echo "Invalid repository name: $repo" >&2
    exit 1
fi
[[ -z "$visibility" || "$visibility" == --public || "$visibility" == --private ]] || usage

# The regular gh login is an OAuth App token, which GitHub rejects with 403
# when changing an App installation. Check before creating anything.
if [[ -z "${APP_INSTALLATION_GITHUB_TOKEN:-}" ]]; then
    echo "APP_INSTALLATION_GITHUB_TOKEN is not set. See docs/workflow.md#リポジトリの追加" >&2
    exit 1
fi

if gh repo view "$owner/$repo" --json name >/dev/null 2>&1; then
    echo "Repository already exists: $owner/$repo" >&2
else
    # Without an explicit visibility a private repository could end up public.
    if [[ -z "$visibility" ]]; then
        echo "Specify --public or --private to create $owner/$repo" >&2
        exit 1
    fi
    # import cannot apply auto_init, so create the initial commit here.
    gh repo create "$owner/$repo" "$visibility" --add-readme
fi

repo_id="$(gh api "repos/$owner/$repo" --jq .id)"
GH_TOKEN="$APP_INSTALLATION_GITHUB_TOKEN" gh api --method PUT --silent \
    "user/installations/$installation_id/repositories/$repo_id"
echo "Added $owner/$repo to the Terraform CI App installation" >&2
