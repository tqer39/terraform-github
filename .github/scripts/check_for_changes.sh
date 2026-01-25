#!/bin/bash
#
# Check if there are changes in a specific repository directory
# that would require Terraform to be run.
#
# Usage: check_for_changes.sh <repo_path> <base_branch> <head_branch>
#
# Returns:
#   0 - Changes detected (should run Terraform)
#   1 - No changes (skip Terraform)

set -e

REPO_PATH="$1"
BASE_BRANCH="$2"
HEAD_BRANCH="$3"

if [ -z "$REPO_PATH" ] || [ -z "$BASE_BRANCH" ] || [ -z "$HEAD_BRANCH" ]; then
  echo "Usage: $0 <repo_path> <base_branch> <head_branch>"
  exit 1
fi

# Fetch the base branch
git fetch origin "$BASE_BRANCH" --depth=1 2>/dev/null || true

# Get the list of changed files between base and head
CHANGED_FILES=$(git diff --name-only "origin/${BASE_BRANCH}...HEAD" 2>/dev/null || git diff --name-only "origin/${BASE_BRANCH}" HEAD 2>/dev/null || echo "")

if [ -z "$CHANGED_FILES" ]; then
  echo "No changed files detected"
  exit 1
fi

# Check if any changed file is in the repository path
is_changed() {
  local file="$1"

  # Check if file is in the repository directory
  if [[ "$file" == "${REPO_PATH}/"* ]]; then
    return 0
  fi

  # Check if file is a Terraform module that might affect this repo
  if [[ "$file" == "terraform/modules/repository/"* ]]; then
    return 0
  fi

  # Check if common GitHub Actions workflows changed
  if [[ "$file" == ".github/actions/terraform-plan/"* ]] || \
     [[ "$file" == ".github/actions/terraform-apply/"* ]] || \
     [[ "$file" == ".github/actions/setup-terraform/"* ]] || \
     [[ "$file" == ".github/actions/terraform-validate/"* ]]; then
    return 0
  fi

  return 1
}

# Check each changed file
for file in $CHANGED_FILES; do
  if is_changed "$file"; then
    echo "Change detected: $file affects $REPO_PATH"
    exit 0
  fi
done

echo "No relevant changes for $REPO_PATH"
exit 1
