#!/usr/bin/env bash
# Only one Terraform process runs at a time against this runner's provider cache.
set -euo pipefail

roots_json="${REPOSITORIES:?REPOSITORIES is required}"
# Validate the whole batch before any root may apply; reject duplicates and traversal.
jq -e 'type == "array" and length > 0 and
    all(.[]; type == "string" and test("^[a-zA-Z0-9][a-zA-Z0-9_-]*$")) and
    (length == (unique | length))' <<< "$roots_json" > /dev/null
roots=()
while IFS= read -r root; do
    [[ -f "terraform/src/repositories/$root/terraform.tf" ]] || {
        echo "Unknown root: $root" >&2
        exit 1
    }
    roots+=("$root")
done < <(jq -r '.[]' <<< "$roots_json")
case "${MANUAL_APPLY:-false}:${REQUIRE_MANUAL_APPLY:?REQUIRE_MANUAL_APPLY is required}" in
    true:true|true:false|false:true|false:false) ;;
    *) echo "Invalid apply policy" >&2; exit 1 ;;
esac
apply=false
case "${EVENT_NAME:?EVENT_NAME is required}" in
    pull_request) ;;
    push) [[ "$REQUIRE_MANUAL_APPLY" == true ]] || apply=true ;;
    workflow_dispatch) apply="${MANUAL_APPLY:-false}" ;;
    *) echo "Unsupported event" >&2; exit 1 ;;
esac
if [[ "$apply" == true && "${GITHUB_REF:-}" != refs/heads/main ]] &&
    jq -e 'index("kazokubi") != null' <<< "$roots_json" > /dev/null; then
    echo 'kazokubi apply requires refs/heads/main' >&2
    exit 1
fi
metrics_dir="${METRICS_DIR:?METRICS_DIR is required}"
mkdir -p "$metrics_dir"
: > "$metrics_dir/roots.jsonl"

# The PAT is the provider's credential; the Actions token has a separate API budget.
# Snapshot failures are visible but must not hide the Terraform result.
rate_limit() {
    local phase="$1"
    if ! GH_TOKEN="${TF_VAR_github_token:-}" gh api rate_limit \
        --jq '{resources: .resources}' > "$metrics_dir/rate-limit-$phase.json"; then
        echo '{"unavailable":true}' > "$metrics_dir/rate-limit-$phase.json"
        echo "::warning::Provider API rate-limit snapshot unavailable ($phase)"
    fi
}
rate_limit before
failed=0
for root in "${roots[@]}"; do
    echo "::group::Terraform $root"
    started="$(date +%s)"
    stage_file="$metrics_dir/$root-stage"
    # Do not put this subshell in an if/&& expression: that disables Bash errexit.
    set +e
    (
        set -e
        if [[ "$root" == kazokubi ]]; then
            if [[ -n "${KAZOKUBI_RELEASE_SECRETS:-}" ]]; then
                export TF_VAR_release_secrets="$KAZOKUBI_RELEASE_SECRETS"
            fi
        else
            unset TF_VAR_discord_webhook_url TF_VAR_release_secrets
        fi
        unset KAZOKUBI_RELEASE_SECRETS
        cd "terraform/src/repositories/$root"
        rm -f tfplan
        echo fmt > "$stage_file"
        terraform fmt -check -recursive -diff
        echo init > "$stage_file"
        terraform init -input=false -lockfile=readonly -no-color
        echo validate > "$stage_file"
        terraform validate -no-color
        echo tflint > "$stage_file"
        tflint --chdir=. --call-module-type=all
        if [[ "$root" == kazokubi ]]; then
            echo test > "$stage_file"
            terraform test -no-color
        fi
        echo plan > "$stage_file"
        tfcmt --var "target:$root" plan -patch -skip-no-changes -- terraform plan -input=false -no-color -out=tfplan
        if [[ "$apply" == true && ( "$root" != kazokubi || "$EVENT_NAME" == workflow_dispatch ) ]]; then
            echo apply > "$stage_file"
            terraform apply -input=false tfplan
        fi
        echo complete > "$stage_file"
    )
    status=$?
    set -e
    elapsed=$(( $(date +%s) - started ))
    stage="$(cat "$stage_file")"
    jq -nc --arg root "$root" --arg stage "$stage" \
        --argjson exit_code "$status" --argjson seconds "$elapsed" \
        '{root: $root, stage: $stage, exit_code: $exit_code, seconds: $seconds}' \
        >> "$metrics_dir/roots.jsonl"
    if [[ "$status" -ne 0 ]]; then
        echo "::error::Terraform $root failed at $stage (exit $status)"
        failed=1
    fi
    echo "::endgroup::"
done
rate_limit after
if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
    {
        echo '| Root | Last stage | Exit code | Seconds |'
        echo '| --- | --- | --- | --- |'
        jq -r '"| \(.root) | \(.stage) | \(.exit_code) | \(.seconds) |"' "$metrics_dir/roots.jsonl"
        echo
        echo 'Provider PAT rate-limit snapshots (shared with other runs; not a per-run request count):'
        echo '```json'
        jq -s '{before: .[0], after: .[1]}' "$metrics_dir"/rate-limit-{before,after}.json
        echo '```'
    } >> "$GITHUB_STEP_SUMMARY"
fi
exit "$failed"
