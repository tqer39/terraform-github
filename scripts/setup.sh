#!/usr/bin/env bash

set -euo pipefail

BLUE='\033[0;34m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}Setting up development environment...${NC}"

if ! command -v mise >/dev/null 2>&1; then
    echo -e "${RED}⚠ mise not found. Please run ./scripts/bootstrap.sh first.${NC}"
    exit 1
fi

echo -e "${BLUE}→ Installing tools with mise...${NC}"
mise install

echo -e "${BLUE}→ Installing node dev dependencies with pnpm...${NC}"
pnpm install --frozen-lockfile

echo -e "${BLUE}→ Installing lefthook git hooks...${NC}"
lefthook install

echo -e "${GREEN}✓ Setup complete!${NC}"
