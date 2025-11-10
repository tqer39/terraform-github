#!/usr/bin/env bash

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Checking Required Tools${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Function to check if a command exists
check_command() {
    local cmd=$1
    local required=${2:-true}

    if command -v "$cmd" >/dev/null 2>&1; then
        local version
        case "$cmd" in
            terraform)
                version=$(terraform version | head -n1 | awk '{print $2}')
                ;;
            tflint)
                version=$(tflint --version | head -n1 | awk '{print $2}')
                ;;
            aws-vault)
                version=$(aws-vault --version 2>&1 | awk '{print $2}')
                ;;
            prek)
                version=$(prek --version 2>&1 | head -n1 | awk '{print $2}')
                ;;
            gh)
                version=$(gh --version | head -n1 | awk '{print $3}')
                ;;
            git)
                version=$(git --version | awk '{print $3}')
                ;;
            make)
                version=$(make --version | head -n1 | awk '{print $3}')
                ;;
            *)
                version="installed"
                ;;
        esac
        echo -e "${GREEN}✅ ${cmd}${NC} - ${version}"
        return 0
    else
        if [[ "$required" == "true" ]]; then
            echo -e "${RED}❌ ${cmd}${NC} - not found (required)"
            return 1
        else
            echo -e "${YELLOW}⚠️  ${cmd}${NC} - not found (optional)"
            return 0
        fi
    fi
}

# Track if any required tools are missing
missing_tools=0

echo -e "${BLUE}Core Tools:${NC}"
check_command "git" || ((missing_tools++))
check_command "make" || ((missing_tools++))
check_command "just" || ((missing_tools++))
echo ""

echo -e "${BLUE}Version Manager:${NC}"
check_command "mise" || ((missing_tools++))
echo ""

echo -e "${BLUE}Terraform Tools:${NC}"
check_command "terraform" || ((missing_tools++))
check_command "tflint" "false"
echo ""

echo -e "${BLUE}AWS Tools:${NC}"
check_command "aws-vault" "false"
echo ""

echo -e "${BLUE}GitHub Tools (optional):${NC}"
check_command "gh" "false"
echo ""

echo -e "${BLUE}Code Quality Tools:${NC}"
check_command "prek" || ((missing_tools++))
echo ""

# Check Terraform version matches .tool-versions
if [[ -f .tool-versions ]]; then
    expected_version=$(grep terraform .tool-versions | awk '{print $2}')
    if command -v terraform >/dev/null 2>&1; then
        current_version=$(terraform version | head -n1 | awk '{print $2}' | sed 's/v//')
        if [[ "$current_version" == "$expected_version" ]]; then
            echo -e "${GREEN}✅ Terraform version matches .tool-versions (${expected_version})${NC}"
        else
            echo -e "${YELLOW}⚠️  Terraform version mismatch:${NC}"
            echo -e "   Expected: ${expected_version}"
            echo -e "   Current:  ${current_version}"
            echo -e "   Run: ${BLUE}mise install terraform@${expected_version}${NC}"
        fi
    fi
fi

echo ""
echo -e "${BLUE}========================================${NC}"

if [[ $missing_tools -eq 0 ]]; then
    echo -e "${GREEN}✨ All required tools are installed!${NC}"
    echo -e "${BLUE}========================================${NC}"
    exit 0
else
    echo -e "${RED}❌ ${missing_tools} required tool(s) missing${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
    echo -e "${YELLOW}Run '${BLUE}make bootstrap${YELLOW}' to install missing tools${NC}"
    exit 1
fi
