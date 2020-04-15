.PHONY: all
all: ;


.PHONY: lint-sh
lint-sh:
	shellcheck -x $(shell grep -lr '\#!/usr/bin/env bash' . | grep -v Makefile)


.PHONY: lint-groovy
lint-groovy:
	for f in ./jobs/*.groovy; do echo "--- $$f"; ./jenkins-cli declarative-linter < "$$f"; done
