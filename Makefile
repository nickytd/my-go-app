# Project root directory
ROOT_DIR:=$(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))

# The compiled binary is located under ./bin folder
BINARY                      ?= my-go-app
BASE                        := $(shell basename $(ROOT_DIR))
COMMIT                      ?= $(shell git rev-list --tags --max-count=1 HEAD --abbrev-commit)
VERSION                     ?=$(shell cat VERSION)-$(shell git rev-parse --short HEAD)
VERSION_SEMVER              ?=$(shell echo $(VERSION) | grep -o 'v[0-9]\+\.[0-9]\+\.[0-9]\+')

PKG_DIR                     := $(ROOT_DIR)/pkg
BIN_DIR                     := $(ROOT_DIR)/bin
TOOLS_DIR                   := $(ROOT_DIR)/hack
TOOLS_BIN_DIR               := $(TOOLS_DIR)/bin

GO_LINT                     := $(TOOLS_BIN_DIR)/golangci-lint
GO_LINT_VERSION             ?= v1.54.2

GINKGO                      := $(TOOLS_BIN_DIR)/ginkgo
GINKGO_VERSION              := v2.12.1

CONTAINER_BUILD_PLATFORM    ?= linux/amd64,linux/arm64
CONTAINER_BASE_IMAGE        ?= gcr.io/distroless/static:nonroot
CONTAINER_REGISTRY          ?= docker.io
CONTAINER_IMAGE             := $(CONTAINER_REGISTRY)/$(BINARY):$(VERSION)

# The build, formats, generates sources, executes the linter followed by the tests
all: generate verify test build

# Executes code generators
.PHONY: generate
generate:
	@go fmt $(ROOT_DIR)/...
	@go mod tidy
	@go generate $(ROOT_DIR)/pkg/...

# Executes project tests
.PHONY: test
test: verify
	@go test $(ROOT_DIR)/...

# Execute ginkgo tests
.PHONY: test-integration
test-integration: $(GINKGO) verify
	@$(GINKGO) $(ROOT_DIR)/test/...

# Build project binary target
build:
	@CGO_ENABLED=0 go build -ldflags="-X main.VERSION=${VERSION}" \
	  -o $(ROOT_DIR)/bin/$(BINARY) $(ROOT_DIR)/cmd/main.go

# Formats project gode
.PHONY: fmt
fmt:
	@go fmt $(ROOT_DIR)/...

# Executes the linter
.PHONY: verify
verify: $(GO_LINT)
	@$(GO_LINT) run $(ROOT_DIR)/...

# Downloads the linter binary
$(GO_LINT):
	@GOBIN=$(abspath $(TOOLS_BIN_DIR)) go install \
	  github.com/golangci/golangci-lint/cmd/golangci-lint@$(GO_LINT_VERSION)

# Downloads ginkgo binary
$(GINKGO):
	@GOBIN=$(abspath $(TOOLS_BIN_DIR)) go install -mod=mod \
	  github.com/onsi/ginkgo/v2/ginkgo@$(GINKGO_VERSION)

# Executes the build binary
run: build
	@$(BIN_DIR)/$(BINARY)

# Builds the container image
.PHONY: container
container:
	@docker build --tag $(CONTAINER_IMAGE) \
	  --build-arg BINARY="$(BINARY)" \
	  --build-arg VERSION="$(VERSION)" \
	  -f Dockerfile .

.PHONY: container
container-push:
	@$(ROOT_DIR)/hack/multi-platform-build.sh	\
	  "$(CONTAINER_BUILD_PLATFORM)" "$(CONTAINER_IMAGE)" \
	  "$(BINARY)" "$(VERSION)"

# Cleans the binary
.PHONY: clean
clean:
	@go clean -testcache -modcache  || true
	@rm -f $(BIN_DIR)/$(BINARY)

.PHONY: clean_all
clean_all: clean
	@docker buildx rm $(BINARY) || true
	@rm -rf $(BIN_DIR)
	@rm -rf $(TOOLS_DIR)
