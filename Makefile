# Bootstrap development environment
# This Makefile handles Homebrew installation only

.DEFAULT_GOAL := help

# Detect operating system
UNAME_S := $(shell uname -s)

# Check if command exists
check_command = $(shell command -v $(1) >/dev/null 2>&1 && echo "exists")

.PHONY: help
help: ## Show this help message
	@echo "Bootstrap Homebrew for development environment"
	@echo ""
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf " %-15s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.PHONY: check-os
check-os: ## Check operating system compatibility
	@echo "Detected OS: $(UNAME_S)"
ifeq ($(UNAME_S),Darwin)
	@echo "✓ macOS detected - compatible"
else ifeq ($(UNAME_S),Linux)
	@echo "✓ Linux detected - compatible"
else
	@echo "⚠ Unsupported OS: $(UNAME_S)"
	@echo "This Makefile supports macOS and Linux only"
	@exit 1
endif

.PHONY: install-brew
install-brew: check-os ## Install Homebrew package manager
ifeq ($(UNAME_S),Darwin)
	@echo "Installing Homebrew for macOS..."
	@if [ "$(call check_command,brew)" = "exists" ]; then \
		echo "✓ Homebrew already installed"; \
	else \
		echo "→ Installing Homebrew..."; \
		/bin/bash -c "$$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; \
		echo "✓ Homebrew installed successfully"; \
	fi
else ifeq ($(UNAME_S),Linux)
	@echo "Installing Homebrew for Linux..."
	@if [ "$(call check_command,brew)" = "exists" ]; then \
		echo "✓ Homebrew already installed"; \
	else \
		echo "→ Installing Homebrew..."; \
		/bin/bash -c "$$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; \
		echo "→ Adding Homebrew to PATH..."; \
		if [ "$$(basename "$$SHELL")" = "zsh" ]; then \
			echo 'eval "$$(​/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> ~/.zshrc; \
			echo "Added to ~/.zshrc"; \
		else \
			echo 'eval "$$(​/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> ~/.bashrc; \
			echo "Added to ~/.bashrc"; \
		fi; \
		eval "$$(​/home/linuxbrew/.linuxbrew/bin/brew shellenv)"; \
		echo "✓ Homebrew installed successfully"; \
	fi
endif

.PHONY: brew-bundle
brew-bundle: ## Install dependencies listed in Brewfile
	@if command -v brew >/dev/null 2>&1; then \
		:; \
	elif [ -x /home/linuxbrew/.linuxbrew/bin/brew ]; then \
		eval "$$(​/home/linuxbrew/.linuxbrew/bin/brew shellenv)"; \
	else \
		echo "⚠ Homebrew not found. Please run make install-brew first."; \
		exit 1; \
	fi; \
	echo "Installing packages from Brewfile..."; \
	brew bundle install; \
	echo "✓ Installed packages from Brewfile"

.PHONY: bootstrap
bootstrap: install-brew brew-bundle ## Install Homebrew and show next steps
	@echo ""
	@echo "🍺 Homebrew installation complete!"
	@echo ""
	@echo "Next steps:"
ifeq ($(UNAME_S),Darwin)
	@echo "1. Restart your terminal (macOS)"
else ifeq ($(UNAME_S),Linux)
	@if [ "$$(basename "$$SHELL")" = "zsh" ]; then \
		echo "1. Reload your shell: source ~/.zshrc (Linux)"; \
	else \
		echo "1. Reload your shell: source ~/.bashrc (Linux)"; \
	fi
else
	@echo "1. Reload your shell or restart terminal"
endif
	@echo "2. Run: just setup (to setup development environment)"
	@echo ""
	@echo "Available commands after setup:"
	@echo " just help    - Show available tasks"
	@echo " just setup   - Setup development environment"
	@echo " just lint    - Run code quality checks"
	@echo " just fmt     - Format Terraform files"
