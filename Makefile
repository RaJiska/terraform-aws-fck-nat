docs:
	@echo "Generating documentation..."
	@docker run --rm --volume "$(shell pwd):/terraform-docs" -u $(shell id -u) quay.io/terraform-docs/terraform-docs:0.16.0 markdown /terraform-docs --header-from /docs/header.md > README.md

docs-examples-full:
	@echo "Generating documentation..."
	@docker run --rm --volume "$(shell pwd)/examples/full:/terraform-docs" -u $(shell id -u) quay.io/terraform-docs/terraform-docs:0.16.0 markdown /terraform-docs --header-from /docs/header.md > $(shell pwd)/examples/full/README.md

start-floci:
	@echo "Starting Floci..."
	@docker run -d --rm -p 4566:4566 -v /var/run/docker.sock:/var/run/docker.sock floci/floci:latest
    #export AWS_ENDPOINT_URL=http://localhost:4566

test-floci:
	@./scripts/test-with-floci.sh

.PHONY: docs docs-examples-full start-floci test-floci
