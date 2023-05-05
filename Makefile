# Project root directory
ROOT_DIR:=$(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))

# The compiled binary is located under ./bin folder
BINARY					?= my-go-app
GO_MODULE					:= my-go-app
REGISTRY					?= docker.io
VERSION 					?= $(shell git rev-parse --short HEAD 2>/dev/null || echo "latest")

PKG_DIR					:= $(ROOT_DIR)/pkg
BIN_DIR					:= $(ROOT_DIR)/bin
TOOLS_DIR	 				:= $(ROOT_DIR)/hack
TOOLS_BIN_DIR				:= $(TOOLS_DIR)/bin

GO_LINT					:= $(TOOLS_BIN_DIR)/golangci-lint
GO_LINT_VERSION				?= v1.51.2

GINKGO 					:= $(TOOLS_BIN_DIR)/ginkgo
GINKGO_VERSION				:= v2.9.2

DOCKER_BUILD_PLATFORM			?= linux/amd64,linux/arm64
DOCKER_RUNTIME_IMAGE 			?= debian:stable-slim
DOCKER_CONTAINER_IMAGE			:=$(REGISTRY)/$(BINARY):$(VERSION)

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
	@GOBIN=$(abspath $(TOOLS_BIN_DIR)) go install github.com/golangci/golangci-lint/cmd/golangci-lint@$(GO_LINT_VERSION)

# Downloads ginkgo binary
$(GINKGO):
	@GOBIN=$(abspath $(TOOLS_BIN_DIR)) go install -mod=mod github.com/onsi/ginkgo/v2/ginkgo@$(GINKGO_VERSION)

# Executes the build binary
run: build
	@$(BIN_DIR)/$(BINARY)
	
# Builds the container image
.PHONY: docker
docker:
	@docker build --tag $(DOCKER_CONTAINER_IMAGE) \
	  --build-arg GO_MODULE="$(GO_MODULE)" \
	  --build-arg BINARY="$(GO_MODULE)/bin/$(BINARY)" \
	  --build-arg CONTAINER_CMD="$(BINARY)" \
	  --build-arg VERSION="$(VERSION)" \
	  -f Dockerfile .

.PHONY: docker-push
docker-push:
	@docker buildx create --name=$(BINARY) --use || true 
	@docker buildx build --platform="$(DOCKER_BUILD_PLATFORM)" \
	  --build-arg GO_MODULE="$(GO_MODULE)" \
	  --build-arg BINARY="$(GO_MODULE)/bin/$(BINARY)" \
	  --build-arg CONTAINER_CMD="$(BINARY)" \
	  --build-arg VERSION="$(VERSION)" \
	  --tag $(DOCKER_CONTAINER_IMAGE) \
	  --push -f Dockerfile .

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

