.PHONY: default

default:
	@1>&2 echo "Default section"

.PHONY: tests
tests:
	@go mod init `pwd -P`
	@go build
	@./tests.sh default

.PHONY: clean
clean:
	@rm -fv *.tmp kubectl
