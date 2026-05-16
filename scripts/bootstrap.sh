#!/usr/bin/env bash

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

UNAME_S="$(uname -s)"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Bootstrap (Homebrew + Brewfile)${NC}"
echo -e "${BLUE}========================================${NC}"
echo -e "Detected OS: ${UNAME_S}"

case "${UNAME_S}" in
    Darwin)
        echo -e "${GREEN}✓ macOS detected - compatible${NC}"
        ;;
    Linux)
        echo -e "${GREEN}✓ Linux detected - compatible${NC}"
        ;;
    *)
        echo -e "${RED}⚠ Unsupported OS: ${UNAME_S}${NC}"
        echo -e "This script supports macOS and Linux only"
        exit 1
        ;;
esac

# Install Homebrew if not present
if command -v brew >/dev/null 2>&1; then
    echo -e "${GREEN}✓ Homebrew already installed${NC}"
else
    echo -e "${BLUE}→ Installing Homebrew...${NC}"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    if [[ "${UNAME_S}" == "Linux" ]]; then
        shell_name="$(basename "${SHELL:-/bin/bash}")"
        if [[ "${shell_name}" == "zsh" ]]; then
            rcfile="${HOME}/.zshrc"
        else
            rcfile="${HOME}/.bashrc"
        fi
        # shellcheck disable=SC2016
        echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> "${rcfile}"
        echo -e "Added Homebrew shellenv to ${rcfile}"
        eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    fi
    echo -e "${GREEN}✓ Homebrew installed${NC}"
fi

# brew bundle
echo -e "${BLUE}→ Installing packages from Brewfile...${NC}"
brew bundle install
echo -e "${GREEN}✓ Brewfile installed${NC}"

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}🍺 Bootstrap complete!${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "Next steps:"
if [[ "${UNAME_S}" == "Darwin" ]]; then
    echo -e "  1. Restart your terminal"
else
    echo -e "  1. Reload your shell (source ~/.zshrc or ~/.bashrc)"
fi
echo -e "  2. Run: ${YELLOW}mise install${NC}"
echo -e "  3. Run: ${YELLOW}mise run setup${NC}"
echo ""
