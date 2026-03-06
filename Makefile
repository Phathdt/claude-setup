.PHONY: format lint install clean help

help: ## Show available commands
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'

format: ## Run prettier on all supported files
	npx prettier --write "**/*.{json,md,js,cjs,mjs,ts,yaml,yml}"

format-check: ## Check formatting without writing
	npx prettier --check "**/*.{json,md,js,cjs,mjs,ts,yaml,yml}"

install: ## Run install script
	./install.sh

clean: ## Remove generated/temp files
	rm -rf node_modules .cache dist build out coverage
