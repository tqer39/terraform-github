#!/usr/bin/env bash
# Run Terraform in one explicit repository root. Extra arguments go to Terraform.
set -euo pipefail

operation="${1:?Terraform operation is required}"
shift
project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
target_dir="${TERRAFORM_DIR:-terraform/src/repositories/terraform-github}"
if [[ $# -gt 0 && "$1" != -* ]]; then
    repo="$1"
    shift
    if [[ ! "$repo" =~ ^[a-zA-Z0-9][a-zA-Z0-9_-]*$ ]]; then
        echo "Invalid repository name: $repo" >&2
        exit 1
    fi
    target_dir="terraform/src/repositories/$repo"
fi
if [[ "$target_dir" != /* ]]; then
    target_dir="$project_root/$target_dir"
fi
if [[ ! -f "$target_dir/terraform.tf" ]]; then
    echo "Terraform root not found: $target_dir" >&2
    exit 1
fi
echo "Terraform target: $target_dir" >&2
exec terraform -chdir="$target_dir" "$operation" "$@"
