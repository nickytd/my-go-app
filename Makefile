# Project root directory
ROOT_DIR:=$(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))

# The compiled binary is located under ./bin folder
BINARY					?= my-go-app
REGISTRY				?= docker.io
VERSION 				?= $(shell git rev-parse --short HEAD 2>/dev/null || echo "latest")

PKG_DIR					:= $(ROOT_DIR)/pkg
BIN_DIR					:= $(ROOT_DIR)/bin
TOOLS_DIR	 			:= $(ROOT_DIR)/hack
TOOLS_BIN_DIR				:= $(TOOLS_DIR)/bin

GO_LINT					:= $(TOOLS_BIN_DIR)/golangci-lint
GO_LINT_VERSION				?= v1.51.2

GINKGO 					:= $(TOOLS_BIN_DIR)/ginkgo
GINKGO_VERSION				:= v2.9.2

DOCKER_BUILD_PLATFORM			?= linux/amd64 linux/arm64
DOCKER_RUNTIME_IMAGE 			?= debian:stable-slim
DOCKER_CMD				:= $(BINARY)

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
build: fmt generate verify test test-integration $(BIN_DIR)/$(BINARY)

# Executes code generators
.PHONY: generate
generate:
	go mod tidy
	go generate $(ROOT_DIR)/pkg/...

# Executes project tests
.PHONY: test
test:
	go test $(ROOT_DIR)/...

# Execute ginkgo tests
.PHONY: test-integration
test-integration: $(GINKGO)
	$(GINKGO) $(ROOT_DIR)/test/...

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

# Downloads ginkgo binary
$(GINKGO):
	GOBIN=$(abspath $(TOOLS_BIN_DIR)) go install -mod=mod github.com/onsi/ginkgo/v2/ginkgo@$(GINKGO_VERSION)

# Executes the builded binary
run: build
	$(BIN_DIR)/$(BINARY)

# Initializes the docker buildx

# Builds the container image
.PHONY: docker
docker:
	$(foreach arch, $(DOCKER_BUILD_PLATFORM), docker build --platform $(arch) \
	--build-arg BINARY=$(BINARY) \
	--build-arg VERSION=$(VERSION) \
	--build-arg RUNTIME_IMAGE=$(DOCKER_RUNTIME_IMAGE) \
	--build-arg CONTAINERCMD=$(DOCKER_CMD) \
	--build-arg TARGETARCH=$(subst linux/,,$(arch)) \
	--tag $(REGISTRY)/$(BINARY):$(VERSION)-$(subst linux/,,$(arch)) -f $(ROOT_DIR)/Dockerfile .; )

# Pushes the container image to the target container registry
.PHONY: docker-push
docker-push: 
	$(foreach arch, $(DOCKER_BUILD_PLATFORM), docker push \
	$(REGISTRY)/$(BINARY):$(VERSION)-$(subst linux/,,$(arch)) ; )
	docker manifest rm $(REGISTRY)/$(BINARY):$(VERSION) || true
	docker manifest create $(REGISTRY)/$(BINARY):$(VERSION) $(foreach arch, $(DOCKER_BUILD_PLATFORM),--amend $(REGISTRY)/$(BINARY):$(VERSION)-$(subst linux/,,$(arch))) 
	$(foreach arch, $(DOCKER_BUILD_PLATFORM), docker manifest annotate --os linux --arch $(subst linux/,,$(arch)) $(REGISTRY)/$(BINARY):$(VERSION) $(REGISTRY)/$(BINARY):$(VERSION)-$(subst linux/,,$(arch)) ; ) 
	docker manifest push $(REGISTRY)/$(BINARY):$(VERSION)
	

