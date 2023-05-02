.PHONY: default

default:
	@1>&2 echo "Default section"

.PHONY: tests
tests:
	@go build
	@./tests.sh default

.PHONY: clean
clean:
	@rm -fv *.tmp kubectl
