docs:
	@echo "Generating documentation..."
	@docker run --rm --volume "$(shell pwd):/terraform-docs" -u $(shell id -u) quay.io/terraform-docs/terraform-docs:0.16.0 markdown /terraform-docs --header-from /docs/header.md > README.md

.PHONY: docs