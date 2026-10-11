#!/usr/bin/env bash
# Emit repository roots affected by a PR/push, or one explicit manual target.
set -euo pipefail

repos_dir="terraform/src/repositories"
targets=()
all_repos=()
require_manual_apply=false

# Use the pinned Terraform and comment CLI versions from committed files.
ci_tool_versions() {
    local ref="$1"
    git cat-file -e "$ref:mise.toml" 2>/dev/null || return 0
    git show "$ref:mise.toml" | awk -F '"' '
        /^terraform[[:space:]]*=/ {print "terraform=" $2}
        /^"aqua:suzuki-shunsuke\/tfcmt"[[:space:]]*=/ {print "tfcmt=" $4}
    '
}

# Recognize only the root's conventional, literal module setting. Unknown or
# more complex HCL stays eligible, so target selection never evaluates code.
is_archived() {
    local ref="$1" repo="$2" config
    config="$(git show "$ref:$repos_dir/$repo/main.tf" 2>/dev/null)" || return 1
    awk '
        /\/\*|<</ { unknown = 1 }
        /^module "this" \{/ { in_module = 1; modules++ }
        /^}/ { in_module = 0 }
        in_module && /^  source[[:space:]]*=[[:space:]]*"\.\.\/\.\.\/\.\.\/modules\/repository"[[:space:]]*$/ { source = 1 }
        in_module && /^  archived[[:space:]]*=[[:space:]]*true[[:space:]]*(#.*|\/\/.*)?$/ { archived = 1 }
        END { exit !(modules == 1 && source && archived && !unknown) }
    ' <<< "$config"
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
            terraform/modules/repository/*|.github/workflows/terraform-github.yml|.github/scripts/set_matrix.sh|.github/scripts/terraform_shard.sh|.github/actions/terraform-shard/*|.github/actions/terraform-plan/*|.github/actions/terraform-apply/*|.github/actions/setup-terraform/*|.github/actions/terraform-validate/*)
                require_manual_apply=true
                ;;
            mise.toml)
                if [[ "$(ci_tool_versions "$diff_base")" != "$(ci_tool_versions "$head")" ]]; then
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

    # Keep archive/unarchive transitions deployable. Only roots already archived
    # at both ends of the comparison can skip automatic plan/apply.
    active_targets=()
    for repo in "${targets[@]}"; do
        if is_archived "$diff_base" "$repo" && is_archived "$head" "$repo"; then
            echo "Skipping archived repository: $repo"
        else
            active_targets+=("$repo")
        fi
    done
    targets=("${active_targets[@]}")
fi

if [[ ${#targets[@]} -eq 0 ]]; then
    matrix='["_empty"]'
else
    matrix="$(printf '%s\n' "${targets[@]}" | jq -R . | jq -sc .)"
fi
echo "Matrix: $matrix"
echo "matrix=$matrix" >> "${GITHUB_OUTPUT:?GITHUB_OUTPUT is required}"
echo "require_manual_apply=$require_manual_apply" >> "$GITHUB_OUTPUT"

# Round-robin distribution is deterministic, balanced and never exceeds five runners.
if [[ ${#targets[@]} -eq 0 ]]; then
    shards='[]'
else
    shards="$(printf '%s\n' "${targets[@]}" | jq -R . | jq -sc '
        . as $roots | ([length, 5] | min) as $count |
        [range($count) as $id |
            {id: $id, repositories: [$roots | to_entries[] |
                select(.key % $count == $id) | .value]}]')"
fi
echo "shards=$shards" >> "$GITHUB_OUTPUT"
