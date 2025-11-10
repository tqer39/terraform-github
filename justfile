# Development tasks for terraform-github

# Use bash for all recipes
set shell := ["bash", "-c"]

# Terraform working directory
terraform_dir := "terraform/src/repository"

# Show available commands
help:
 @just --list

# Setup development environment
setup:
 @echo "Setting up development environment..."
 @if command -v mise >/dev/null 2>&1; then \
   echo "→ Installing tools with mise..."; \
   eval "$$(mise activate bash)"; \
   mise install; \
 else \
   echo "⚠ mise not found. Please run 'make bootstrap' first."; \
   exit 1; \
 fi
 @echo "→ Installing prek hooks..."
 @prek install
 @echo "→ Initializing Terraform..."
 @cd {{terraform_dir}} && terraform init -upgrade
 @echo "✓ Setup complete!"

# Check if required tools are installed
check-tools:
 @bash scripts/check-tools.sh

# Interactive git worktree setup
worktree-setup:
 @bash scripts/setup-worktree.sh

# Format all Terraform files
fmt:
 @echo "📝 Formatting Terraform files..."
 @terraform fmt -recursive

# Validate Terraform configuration
validate:
 @echo "✅ Validating Terraform configuration..."
 @cd {{terraform_dir}} && terraform validate

# Run all linters (prek)
lint:
 @echo "🔍 Running linters..."
 @prek run --all-files

# Run specific prek hook
lint-hook hook:
 @prek run {{hook}}

# Initialize Terraform
init:
 @echo "🔧 Initializing Terraform..."
 @cd {{terraform_dir}} && terraform init -upgrade

# Run Terraform plan
plan:
 @echo "📋 Running Terraform plan..."
 @cd {{terraform_dir}} && terraform plan

# Run Terraform apply (use with caution)
apply:
 @echo "⚠️  Running Terraform apply..."
 @cd {{terraform_dir}} && terraform apply

# Format staged files (typical git commit flow)
fmt-staged:
 @prek run terraform_fmt

# Fix common formatting issues
fix:
 @prek run end-of-file-fixer --all-files
 @prek run trailing-whitespace --all-files
 @prek run markdownlint-cli2 --all-files

# Clean Terraform temporary files
clean:
 @echo "🧹 Cleaning Terraform temporary files..."
 @find {{terraform_dir}} -type d -name ".terraform" -exec rm -rf {} + 2>/dev/null || true
 @find {{terraform_dir}} -type f -name "*.tfstate.backup" -delete 2>/dev/null || true
 @echo "✓ Clean complete!"

# Show mise status
status:
 @mise list

# Install mise tools
install:
 @echo "Installing tools with mise..."
 @mise install

# Update mise tools
update:
 @mise upgrade

# Update brew packages
update-brew:
 @brew update
 @brew bundle install
 @brew upgrade

# Show tool versions
version:
 @terraform version
 @mise --version
 @just --version

# Run rulesync with passthrough args
rulesync args='':
 @if command -v rulesync >/dev/null 2>&1; then \
   echo "Running: rulesync {{args}}"; \
   rulesync {{args}}; \
 else \
   echo "⚠ rulesync not found. Please run 'make bootstrap' or 'brew install rulesync' first."; \
   exit 1; \
 fi

# Git worktree helpers
[private]
worktree-add branch:
 @bash scripts/setup-worktree.sh add {{branch}}

[private]
worktree-list:
 @git worktree list

[private]
worktree-remove branch:
 @git worktree remove ../terraform-github-{{branch}}
