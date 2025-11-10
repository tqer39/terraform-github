#!/usr/bin/env bash

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Git Worktree Setup${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Get the repository root directory
REPO_ROOT=$(git rev-parse --show-toplevel)
REPO_NAME=$(basename "$REPO_ROOT")

# Worktree base directory (parent of current repo)
WORKTREE_BASE=$(dirname "$REPO_ROOT")

echo -e "${GREEN}📁 Repository: ${REPO_NAME}${NC}"
echo -e "${GREEN}📂 Repository root: ${REPO_ROOT}${NC}"
echo -e "${GREEN}🌳 Worktree base: ${WORKTREE_BASE}${NC}"
echo ""

# Check if we're already in a worktree
if git rev-parse --git-common-dir > /dev/null 2>&1; then
    GIT_COMMON_DIR=$(git rev-parse --git-common-dir)
    if [[ "$GIT_COMMON_DIR" != ".git" ]] && [[ "$GIT_COMMON_DIR" != *".git"* ]]; then
        echo -e "${YELLOW}⚠️  You are already in a git worktree${NC}"
        echo ""
    fi
fi

# Show current worktrees
echo -e "${BLUE}Current worktrees:${NC}"
git worktree list
echo ""

# Function to create a new worktree
create_worktree() {
    local branch_name=$1
    local worktree_path="${WORKTREE_BASE}/${REPO_NAME}-${branch_name}"

    if [[ -d "$worktree_path" ]]; then
        echo -e "${YELLOW}⚠️  Worktree already exists: ${worktree_path}${NC}"
        return 1
    fi

    echo -e "${GREEN}Creating worktree for branch: ${branch_name}${NC}"

    # Check if branch exists remotely
    if git ls-remote --heads origin "$branch_name" | grep -q "$branch_name"; then
        echo -e "${BLUE}Branch exists remotely, checking out...${NC}"
        git worktree add "$worktree_path" "$branch_name"
    else
        echo -e "${BLUE}Creating new branch...${NC}"
        git worktree add -b "$branch_name" "$worktree_path"
    fi

    echo -e "${GREEN}✅ Worktree created: ${worktree_path}${NC}"
    return 0
}

# Interactive mode
echo -e "${BLUE}Git Worktree Management${NC}"
echo -e "1) Create new worktree"
echo -e "2) List existing worktrees"
echo -e "3) Show worktree info"
echo -e "4) Exit"
echo ""

read -r -p "Select option (1-4): " choice

case $choice in
    1)
        echo ""
        read -r -p "Enter branch name for new worktree: " branch_name
        if [[ -z "$branch_name" ]]; then
            echo -e "${RED}❌ Branch name cannot be empty${NC}"
            exit 1
        fi
        create_worktree "$branch_name"
        ;;
    2)
        echo ""
        echo -e "${BLUE}Existing worktrees:${NC}"
        git worktree list
        ;;
    3)
        echo ""
        echo -e "${BLUE}Worktree Structure:${NC}"
        echo -e "  Main repository:  ${GREEN}${REPO_ROOT}${NC}"
        echo -e "  Worktree pattern: ${GREEN}${WORKTREE_BASE}/${REPO_NAME}-<branch>${NC}"
        echo ""
        echo -e "${BLUE}Example usage:${NC}"
        echo -e "  # Create a worktree for 'feature/new-feature' branch"
        echo -e "  ${YELLOW}git worktree add ../${REPO_NAME}-feature-new-feature -b feature/new-feature${NC}"
        echo ""
        echo -e "  # Or use this script"
        echo -e "  ${YELLOW}make worktree-setup${NC}"
        echo ""
        echo -e "${BLUE}Remove a worktree:${NC}"
        echo -e "  ${YELLOW}git worktree remove ../${REPO_NAME}-feature-new-feature${NC}"
        ;;
    4)
        echo -e "${GREEN}👋 Exiting...${NC}"
        exit 0
        ;;
    *)
        echo -e "${RED}❌ Invalid option${NC}"
        exit 1
        ;;
esac

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✨ Done!${NC}"
echo -e "${GREEN}========================================${NC}"
