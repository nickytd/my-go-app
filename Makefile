ROOT_DIR:=$(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
## Change BINARY to the desired applicaiton name
## The compiled binary is located under ./bin folder
BINARY					   	?= my-go-app
REGISTRY					?= docker.io

PKG_DIR						:= $(ROOT_DIR)/pkg
BIN_DIR						:= $(ROOT_DIR)/bin
TOOLS_DIR	 				:= $(ROOT_DIR)/hack
TOOLS_BIN_DIR				:= $(TOOLS_DIR)/bin

GO_LINT						:= $(TOOLS_BIN_DIR)/golangci-lint
GO_LINT_VERSION				?= v1.50.1

DOCKER_BUILD_PLATFORM 		?= linux/amd64,linux/arm64
DOCKER_BUILD_RUNTIME_IMAGE 	?= alpine:3.16

VERSION ?= $(shell git describe --always --dirty --tags 2>/dev/null || echo "latest")

# Default target
all: build

# Cleans the binary
.PHONY: clean
clean:
	rm -f $(BIN_DIR)/$(BINARY)

# Also removes the downloaded binaries
.PHONY: clean_all
clean_all: clean
	rm -rf $(BIN_DIR)
	rm -rf $(TOOLS_DIR)

# The build, formats, generates sources, executes the linter followed by the tests
.PHONY: build
build: fmt generate verify test $(BIN_DIR)/$(BINARY)

# Executes code generators
.PHONY: generate
generate:
	go generate $(ROOT_DIR)/pkg/...

# Executes project tests
.PHONY: test
test:
	go test $(ROOT_DIR)/...

# Build project binary target
$(BIN_DIR)/$(BINARY):
	CGO_ENABLED=0 go build -a -installsuffix cgo -ldflags="-X main.VERSION=${VERSION}" -o $(abspath $(BIN_DIR))/$(BINARY) cmd/main.go

# Formats project gode
.PHONY: fmt
fmt:
	go fmt $(ROOT_DIR)/...

# Executes the linter
.PHONY: verify
verify: $(GO_LINT)
	$(GO_LINT) run $(ROOT_DIR)/...

# Downloads the linter binary
$(GO_LINT):
	GOBIN=$(abspath $(TOOLS_BIN_DIR)) go install github.com/golangci/golangci-lint/cmd/golangci-lint@$(GO_LINT_VERSION)

# Executes the builded binary
run: build
	$(BIN_DIR)/$(BINARY)

# Initializes the docker buildx
DOCKER_BUILDX_ARGS ?= --build-arg RUNTIME_IMAGE=${DOCKER_BUILD_RUNTIME_IMAGE}
DOCKER_BUILDX := docker buildx build ${DOCKER_BUILDX_ARGS} --build-arg VERSION=${VERSION} --build-arg BINARY=${BINARY}
DOCKER_BUILDX_X_PLATFORM := $(DOCKER_BUILDX) --platform ${DOCKER_BUILD_PLATFORM}
DOCKER_BUILDX_PUSH := docker buildx build --push ${DOCKER_BUILDX_ARGS} --build-arg VERSION=${VERSION} --build-arg BINARY=${BINARY}
DOCKER_BUILDX_PUSH_X_PLATFORM := $(DOCKER_BUILDX_PUSH) --platform ${DOCKER_BUILD_PLATFORM}

# Builds the container image
.PHONY: docker
docker:
	$(DOCKER_BUILDX_X_PLATFORM) -f Dockerfile -t $(REGISTRY)/$(BINARY):$(VERSION) .

# Pushes the container image to the target container registry
.PHONY: docker-push
docker-push:
	$(DOCKER_BUILDX_PUSH_X_PLATFORM) -t $(REGISTRY)/$(BINARY):$(VERSION) .
