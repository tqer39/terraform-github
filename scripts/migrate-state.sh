#!/bin/bash
#
# Terraform State Migration Script
# Imports resources from old single state to new per-repository states
#
# Usage: aws-vault exec portfolio -- ./scripts/migrate-state.sh [--dry-run] [repo-name]
#
# Options:
#   --dry-run    Show what would be done without actually importing
#
# If repo-name is provided, only that repository will be migrated.
# Otherwise, all repositories will be migrated.
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
REPOS_DIR="${PROJECT_ROOT}/terraform/src/repositories"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

DRY_RUN=false

log_info() {
  echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
  echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
  echo -e "${RED}[ERROR]${NC} $1"
}

log_dry_run() {
  echo -e "${BLUE}[DRY-RUN]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
  if [ -z "$TF_VAR_github_token" ]; then
    log_error "TF_VAR_github_token is not set. Please set it before running this script."
    log_info "Example: export TF_VAR_github_token=\$(gh auth token)"
    exit 1
  fi

  if ! aws sts get-caller-identity &>/dev/null; then
    log_error "AWS credentials not available. Please run with: aws-vault exec portfolio -- $0"
    exit 1
  fi

  log_info "AWS credentials verified"
}

# Function to import a single repository
import_repository() {
  local repo_name="$1"
  local repo_dir="${REPOS_DIR}/${repo_name}"

  if [ ! -d "$repo_dir" ]; then
    log_error "Repository directory not found: $repo_dir"
    return 1
  fi

  log_info "=========================================="
  log_info "Importing: ${repo_name}"
  log_info "=========================================="

  cd "$repo_dir"

  # Initialize terraform
  log_info "Running terraform init..."
  if [ "$DRY_RUN" = true ]; then
    log_dry_run "Would run: terraform init -input=false"
  else
    terraform init -input=false
  fi

  # Check if this repo uses template (edu-quest, xtrade)
  local uses_template=false
  if grep -q "template_repository" "${repo_dir}/main.tf" 2>/dev/null; then
    uses_template=true
  fi

  # Import github_repository
  log_info "Importing github_repository..."
  if [ "$uses_template" = true ]; then
    if [ "$DRY_RUN" = true ]; then
      log_dry_run "Would run: terraform import \"module.this.github_repository.this_from_template[0]\" \"$repo_name\""
    else
      terraform import "module.this.github_repository.this_from_template[0]" "$repo_name" 2>/dev/null || \
        log_warn "github_repository.this_from_template[0] already imported or not found"
    fi
  else
    if [ "$DRY_RUN" = true ]; then
      log_dry_run "Would run: terraform import \"module.this.github_repository.this[0]\" \"$repo_name\""
    else
      terraform import "module.this.github_repository.this[0]" "$repo_name" 2>/dev/null || \
        log_warn "github_repository.this[0] already imported or not found"
    fi
  fi

  # Import github_branch_default
  log_info "Importing github_branch_default..."
  if [ "$DRY_RUN" = true ]; then
    log_dry_run "Would run: terraform import \"module.this.github_branch_default.this\" \"$repo_name\""
  else
    terraform import "module.this.github_branch_default.this" "$repo_name" 2>/dev/null || \
      log_warn "github_branch_default.this already imported or not found"
  fi

  # Import github_actions_repository_permissions (if not disabled)
  if ! grep -q 'configure_actions_permissions.*=.*false' "${repo_dir}/main.tf" 2>/dev/null; then
    log_info "Importing github_actions_repository_permissions..."
    if [ "$DRY_RUN" = true ]; then
      log_dry_run "Would run: terraform import \"module.this.github_actions_repository_permissions.this[0]\" \"$repo_name\""
    else
      terraform import "module.this.github_actions_repository_permissions.this[0]" "$repo_name" 2>/dev/null || \
        log_warn "github_actions_repository_permissions.this[0] already imported or not found"
    fi
  else
    log_info "Skipping github_actions_repository_permissions (disabled for this repo)"
  fi

  # Import github_repository_ruleset for each branch ruleset
  if grep -q "branch_rulesets" "${repo_dir}/main.tf" 2>/dev/null; then
    log_info "Importing github_repository_ruleset..."

    # Extract branch ruleset names from main.tf (macOS compatible)
    # Look for lines like: "main" = { or "development" = {
    local rulesets
    rulesets=$(grep -A30 'branch_rulesets = {' "${repo_dir}/main.tf" 2>/dev/null | grep -E '^\s+"(main|development)" = \{' | sed 's/.*"\([^"]*\)".*/\1/' || echo "")

    for ruleset in $rulesets; do
      log_info "  Importing ruleset: ${ruleset}"
      if [ "$DRY_RUN" = true ]; then
        log_dry_run "Would fetch ruleset ID from: gh api \"repos/tqer39/${repo_name}/rulesets\""
        log_dry_run "Would run: terraform import \"module.this.github_repository_ruleset.this[\\\"${ruleset}\\\"]\" \"${repo_name}:<ruleset_id>\""
      else
        local ruleset_id
        ruleset_id=$(gh api "repos/tqer39/${repo_name}/rulesets" --jq ".[] | select(.name == \"${ruleset}\") | .id" 2>/dev/null || echo "")

        if [ -n "$ruleset_id" ]; then
          terraform import "module.this.github_repository_ruleset.this[\"${ruleset}\"]" "${repo_name}:${ruleset_id}" 2>/dev/null || \
            log_warn "github_repository_ruleset.this[\"${ruleset}\"] already imported or not found"
        else
          log_warn "Could not find ruleset ID for ${ruleset} in ${repo_name}"
        fi
      fi
    done
  fi

  # Import github_repository_environment (if any)
  if grep -q "environments" "${repo_dir}/main.tf" 2>/dev/null; then
    log_info "Importing github_repository_environment..."
    local envs
    # Extract environment names from main.tf (macOS compatible)
    # Look for lines like: "claude-autofix" = { within environments block
    envs=$(grep -A30 'environments = {' "${repo_dir}/main.tf" 2>/dev/null | grep -E '^\s+"[^"]+" = \{' | sed 's/.*"\([^"]*\)".*/\1/' || echo "")

    for env in $envs; do
      log_info "  Importing environment: ${env}"
      if [ "$DRY_RUN" = true ]; then
        log_dry_run "Would run: terraform import \"module.this.github_repository_environment.this[\\\"${env}\\\"]\" \"${repo_name}:${env}\""
      else
        terraform import "module.this.github_repository_environment.this[\"${env}\"]" "${repo_name}:${env}" 2>/dev/null || \
          log_warn "github_repository_environment.this[\"${env}\"] already imported or not found"
      fi
    done
  fi

  # Run terraform plan to verify
  log_info "Running terraform plan to verify..."
  if [ "$DRY_RUN" = true ]; then
    log_dry_run "Would run: terraform plan -input=false -detailed-exitcode"
  else
    terraform plan -input=false -detailed-exitcode || {
      local exit_code=$?
      if [ $exit_code -eq 2 ]; then
        log_warn "There are changes to apply for ${repo_name}"
      elif [ $exit_code -eq 1 ]; then
        log_error "Terraform plan failed for ${repo_name}"
        return 1
      fi
    }
  fi

  log_info "Completed: ${repo_name}"
  echo ""
}

# Main
main() {
  local target_repo=""

  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case $1 in
      --dry-run)
        DRY_RUN=true
        shift
        ;;
      -*)
        log_error "Unknown option: $1"
        echo "Usage: $0 [--dry-run] [repo-name]"
        exit 1
        ;;
      *)
        target_repo="$1"
        shift
        ;;
    esac
  done

  if [ "$DRY_RUN" = true ]; then
    log_info "=========================================="
    log_info "DRY-RUN MODE - No changes will be made"
    log_info "=========================================="
    echo ""
  fi

  check_prerequisites

  if [ -n "$target_repo" ]; then
    import_repository "$target_repo"
  else
    log_info "Starting migration for all repositories..."

    local repos
    repos=$(find "${REPOS_DIR}" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; 2>/dev/null | sort)

    for repo in $repos; do
      import_repository "$repo" || {
        log_error "Failed to import ${repo}, continuing..."
      }
    done

    log_info "=========================================="
    log_info "Migration completed!"
    log_info "=========================================="
  fi
}

main "$@"
