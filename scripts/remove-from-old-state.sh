#!/bin/bash
#
# Remove migrated resources from old Terraform state
#
# Usage: aws-vault exec portfolio -- ./scripts/remove-from-old-state.sh [--dry-run] [repo-name]
#
# Options:
#   --dry-run    Show what would be removed without actually removing
#
# If repo-name is provided, only that repository's resources will be removed.
# Otherwise, all repositories' resources will be removed.
#
# WARNING: Run this AFTER successfully importing resources to new states!
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
OLD_REPO_DIR="${PROJECT_ROOT}/terraform/src/repository"

# Dry run mode
DRY_RUN=false

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

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
  echo -e "${CYAN}[DRY-RUN]${NC} $1"
}

# Check if aws credentials are available
if ! aws sts get-caller-identity &>/dev/null; then
  log_error "AWS credentials not available. Please run with: aws-vault exec portfolio -- $0"
  exit 1
fi

log_info "AWS credentials verified"

cd "$OLD_REPO_DIR"

# Initialize if needed
if [ ! -d ".terraform" ]; then
  log_info "Running terraform init..."
  terraform init -input=false
fi

# Function to remove resources for a single repository
remove_repository_resources() {
  local repo_name="$1"

  log_info "=========================================="
  log_info "Removing resources for: ${repo_name}"
  log_info "=========================================="

  # Determine module name based on old configuration
  local module_name
  case "$repo_name" in
    "blender-chat-character")
      module_name="blender_chat_character"
      ;;
    "nana-kana-dialogue-system")
      module_name="nana_kana_dialogue_system"
      ;;
    *)
      module_name="$repo_name"
      ;;
  esac

  # List of resources to remove
  local resources=(
    "module.${module_name}.github_repository.this[0]"
    "module.${module_name}.github_repository.this_from_template[0]"
    "module.${module_name}.github_branch_default.this"
    "module.${module_name}.github_actions_repository_permissions.this[0]"
  )

  # Remove each resource
  for resource in "${resources[@]}"; do
    if [ "$DRY_RUN" = true ]; then
      log_dry_run "Would remove: ${resource}"
    else
      log_info "Removing: ${resource}"
      terraform state rm "$resource" 2>/dev/null || \
        log_warn "Resource not found or already removed: ${resource}"
    fi
  done

  # Remove rulesets (main, development)
  for ruleset in main development; do
    local resource="module.${module_name}.github_repository_ruleset.this[\"${ruleset}\"]"
    if [ "$DRY_RUN" = true ]; then
      log_dry_run "Would remove: ${resource}"
    else
      log_info "Removing: ${resource}"
      terraform state rm "$resource" 2>/dev/null || \
        log_warn "Resource not found or already removed: ${resource}"
    fi
  done

  # Remove environments if any (loop allows easy expansion)
  # shellcheck disable=SC2043
  for env in claude-autofix; do
    local resource="module.${module_name}.github_repository_environment.this[\"${env}\"]"
    if [ "$DRY_RUN" = true ]; then
      log_dry_run "Would remove: ${resource}"
    else
      log_info "Removing: ${resource}"
      terraform state rm "$resource" 2>/dev/null || \
        log_warn "Resource not found or already removed: ${resource}"
    fi
  done

  if [ "$DRY_RUN" = true ]; then
    log_info "Dry-run completed for: ${repo_name}"
  else
    log_info "Completed: ${repo_name}"
  fi
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
      *)
        target_repo="$1"
        shift
        ;;
    esac
  done

  echo ""
  if [ "$DRY_RUN" = true ]; then
    log_info "=========================================="
    log_info "DRY-RUN MODE: No changes will be made"
    log_info "=========================================="
  else
    log_warn "=========================================="
    log_warn "WARNING: This will remove resources from the old state!"
    log_warn "Make sure you have successfully imported them to new states first!"
    log_warn "=========================================="
    echo ""
    read -rp "Are you sure you want to continue? (yes/no): " confirm

    if [ "$confirm" != "yes" ]; then
      log_info "Aborted."
      exit 0
    fi
  fi

  if [ -n "$target_repo" ]; then
    # Remove single repository
    remove_repository_resources "$target_repo"
  else
    # Remove all repositories
    log_info "Removing resources for all repositories..."

    local repos=(
      "anime-tweet-bot"
      "blender-chat-character"
      "blog"
      "boilerplate-base"
      "boilerplate-saas"
      "dotfiles"
      "edu-quest"
      "kkhs-workspace"
      "local-workspace-provisioning"
      "my-chat-ai-comfyui"
      "nana-kana-dialogue-system"
      "notifications"
      "obsidian-vault"
      "openai-generate-pr-description"
      "renovate-config"
      "setup-develop-environments"
      "terraform-aws"
      "terraform-github"
      "terraform-vercel"
      "time-capsule"
      "tqer39"
      "update-license-year"
      "xtrade"
    )

    for repo in "${repos[@]}"; do
      remove_repository_resources "$repo" || {
        log_error "Failed to remove ${repo}, continuing..."
      }
    done

    log_info "=========================================="
    if [ "$DRY_RUN" = true ]; then
      log_info "Dry-run completed! No changes were made."
    else
      log_info "Removal completed!"
    fi
    log_info "=========================================="
  fi
}

main "$@"
