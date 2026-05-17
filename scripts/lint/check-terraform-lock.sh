#!/usr/bin/env bash
# Fail if any terraform/src/repositories/<repo>/ directory is missing .terraform.lock.hcl.
# Prevents new-repository PRs from being merged without the provider lock file.
set -euo pipefail

repo_root="terraform/src/repositories"

if [[ ! -d "$repo_root" ]]; then
  exit 0
fi

missing=()
while IFS= read -r -d '' dir; do
  if [[ ! -f "$dir/.terraform.lock.hcl" ]]; then
    missing+=("$dir")
  fi
done < <(find "$repo_root" -mindepth 1 -maxdepth 1 -type d -print0)

if (( ${#missing[@]} > 0 )); then
  {
    echo "Missing .terraform.lock.hcl in the following repository directories:"
    for d in "${missing[@]}"; do
      echo "  - $d"
    done
    echo
    echo "Run 'terraform -chdir=<dir> init' to generate the lock file, then commit it."
  } >&2
  exit 1
fi
