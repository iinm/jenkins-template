scripts := jenkins jenkins-cli update_jobs.sh update_views.sh

.PHONY: all
all: ;

.PHONY: lint
lint:
	shellcheck -x $(scripts)
	for f in ./jobs/*.groovy; do echo "--- $$f"; ./jenkins-cli declarative-linter < "$$f"; done
