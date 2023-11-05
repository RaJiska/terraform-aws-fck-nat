docs:
	@echo "Generating documentation..."
	@docker run --rm --volume "$(shell pwd):/terraform-docs" -u $(shell id -u) quay.io/terraform-docs/terraform-docs:0.16.0 markdown /terraform-docs --header-from /docs/header.md > README.md

docs-examples-full:
	@echo "Generating documentation..."
	@docker run --rm --volume "$(shell pwd)/examples/full:/terraform-docs" -u $(shell id -u) quay.io/terraform-docs/terraform-docs:0.16.0 markdown /terraform-docs --header-from /docs/header.md > $(shell pwd)/examples/full/README.md

.PHONY: docs docs-examples-full