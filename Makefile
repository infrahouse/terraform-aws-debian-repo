.DEFAULT_GOAL := help

define BROWSER_PYSCRIPT
import webbrowser
webbrowser.open("docs/_build/html/index.html")
endef
export BROWSER_PYSCRIPT

define PRINT_HELP_PYSCRIPT
import re, sys

for line in sys.stdin:
    match = re.match(r'^([a-zA-Z_-]+):.*?## (.*)$$', line)
    if match:
        target, help = match.groups()
        print("%-40s %s" % (target, help))
endef
export PRINT_HELP_PYSCRIPT

help: install-hooks
	@python -c "$$PRINT_HELP_PYSCRIPT" < Makefile

.PHONY: install-hooks
install-hooks:  ## Install repo hooks
	@echo "Checking and installing hooks"
	@test -d .git/hooks || (echo "Looks like you are not in a Git repo" ; exit 1)
	@test -L .git/hooks/pre-commit || ln -fs ../../hooks/pre-commit .git/hooks/pre-commit
	@chmod +x .git/hooks/pre-commit

.PHONY: format
format:  ## Format terraform files
	terraform fmt -recursive
	black tests

.PHONY: lint
lint:  ## Run code style checks
	terraform fmt --check -recursive

.PHONY: test
test:  ## Run tests on the module
	pytest -xvvs tests

.PHONY: bootstrap
bootstrap: ## bootstrap the development environment
	pip install -U "pip ~= 23.1"
	pip install -U "setuptools ~= 68.0"
	pip install -r requirements.txt

BROWSER := python -c "$$BROWSER_PYSCRIPT"

.PHONY: docs
docs: ## generate Sphinx HTML documentation, including API docs
	$(MAKE) -C docs clean
	$(MAKE) -C docs html
	$(BROWSER) docs/_build/html/index.html

.PHONY: clean
clean:  ## Remove various artifacts
	rm -rf test_data/gha-admin/.terraform \
		test_data/gha-admin/.terraform.lock.hcl \
		test_data/gha-admin/terraform.tfstate \
		test_data/gha-admin/terraform.tfstate.backup \
		.pytest_cache \
		tf-apply-trace.txt \
		tf-destroy-trace.txt
