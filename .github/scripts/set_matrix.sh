#!/usr/bin/env bash
# Emit repository roots affected by a PR/push, or one explicit manual target.
set -euo pipefail

repos_dir="terraform/src/repositories"
targets=()
all_repos=()
require_manual_apply=false

# Use the same pinned version consumed by setup-terraform, from committed files.
terraform_version() {
    local ref="$1"
    git cat-file -e "$ref:mise.toml" 2>/dev/null || return 0
    git show "$ref:mise.toml" | awk -F '"' '/^terraform[[:space:]]*=/ {print $2}'
}
for dir in "$repos_dir"/*/; do
    [[ -f "$dir/terraform.tf" ]] || continue
    all_repos+=("$(basename "$dir")")
done

event="${EVENT_NAME:?EVENT_NAME is required}"
if [[ "$event" == workflow_dispatch ]]; then
    repo="${TARGET_REPOSITORY:-}"
    if [[ "$repo" == all ]]; then
        targets=("${all_repos[@]}")
    elif [[ "$repo" =~ ^[a-zA-Z0-9][a-zA-Z0-9_-]*$ && -f "$repos_dir/$repo/terraform.tf" ]]; then
        targets=("$repo")
    else
        echo "Invalid repository target: $repo" >&2
        exit 1
    fi
else
    base="${BASE_SHA:?BASE_SHA is required}"
    head="${HEAD_SHA:?HEAD_SHA is required}"
    # Missing history must fail instead of silently skipping deployment.
    git cat-file -e "$base^{commit}"
    git cat-file -e "$head^{commit}"
    if [[ "$event" == pull_request ]]; then
        diff_base="$(git merge-base "$base" "$head")"
    elif [[ "$event" == push ]]; then
        diff_base="$base"
    else
        echo "Unsupported event: $event" >&2
        exit 1
    fi
    changes="$(git diff --name-only "$diff_base" "$head")"
    while IFS= read -r file; do
        case "$file" in
            terraform/modules/repository/*|.github/actions/terraform-plan/*|.github/actions/terraform-apply/*|.github/actions/setup-terraform/*|.github/actions/terraform-validate/*)
                require_manual_apply=true
                ;;
            mise.toml)
                if [[ "$(terraform_version "$diff_base")" != "$(terraform_version "$head")" ]]; then
                    require_manual_apply=true
                fi
                ;;
        esac
    done <<< "$changes"
    if [[ "$require_manual_apply" == true ]]; then
        targets=("${all_repos[@]}")
    else
        for repo in "${all_repos[@]}"; do
            while IFS= read -r file; do
                case "$file" in
                    "$repos_dir/$repo/"*)
                        targets+=("$repo")
                        break
                        ;;
                esac
            done <<< "$changes"
        done
    fi
fi

if [[ ${#targets[@]} -eq 0 ]]; then
    matrix='["_empty"]'
else
    matrix="$(printf '%s\n' "${targets[@]}" | jq -R . | jq -sc .)"
fi
echo "Matrix: $matrix"
echo "matrix=$matrix" >> "${GITHUB_OUTPUT:?GITHUB_OUTPUT is required}"
echo "require_manual_apply=$require_manual_apply" >> "$GITHUB_OUTPUT"
