# project root directory
ROOT_DIR:=$(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))

# build targets
BINARY				?= my-go-app
VERSION 				?= $(shell git rev-parse --short HEAD 2>/dev/null || echo "latest")

# project folder structure
PKG_DIR				:= $(ROOT_DIR)/pkg
BIN_DIR				:= $(ROOT_DIR)/bin
TOOLS_DIR	 			:= $(ROOT_DIR)/hack
TOOLS_BIN_DIR			:= $(TOOLS_DIR)/bin

# linter dependencies
GO_LINT				:= $(TOOLS_BIN_DIR)/golangci-lint
GO_LINT_VERSION			?= v1.51.2

# test dependencies
GINKGO 				:= $(TOOLS_BIN_DIR)/ginkgo
GINKGO_VERSION			?= v2.9.2

# docker configuration
DOCKER_BUILD_PLATFORM		?= linux/amd64 linux/arm64
DOCKER_RUNTIME_IMAGE 		?= debian:stable-slim
REGISTRY				?= docker.io
DOCKER_CMD				:= $(BINARY)

# default target
all: build

# cleans the binary
.PHONY: clean
clean:
	rm -f $(BIN_DIR)/$(BINARY)

# cleans project dependencies
.PHONY: clean_all
clean_all: clean
	rm -rf $(BIN_DIR)
	rm -rf $(TOOLS_DIR)

# The build formats, generates sources, executes the linter followed by the tests
.PHONY: build
build: fmt generate verify test test-integration $(BIN_DIR)/$(BINARY)

# code generators
.PHONY: generate
generate:
	go mod tidy
	go generate $(ROOT_DIR)/pkg/...

# project tests
.PHONY: test
test:
	go test $(ROOT_DIR)/...

# ginkgo tests
.PHONY: test-integration
test-integration: $(GINKGO)
	$(GINKGO) $(ROOT_DIR)/test/...

# project binary target
$(BIN_DIR)/$(BINARY):
	CGO_ENABLED=0 go build -a -installsuffix cgo -ldflags="-X main.VERSION=${VERSION}" -o $(abspath $(BIN_DIR))/$(BINARY) cmd/main.go

# formats project code
.PHONY: fmt
fmt:
	go fmt $(ROOT_DIR)/...

# verify project code
.PHONY: verify
verify: $(GO_LINT)
	go vet $(ROOT_DIR)/...
	$(GO_LINT) run $(ROOT_DIR)/...

# fetch linter dependency
$(GO_LINT):
	GOBIN=$(abspath $(TOOLS_BIN_DIR)) go install github.com/golangci/golangci-lint/cmd/golangci-lint@$(GO_LINT_VERSION)

# fetch ginkgo dependency
$(GINKGO):
	GOBIN=$(abspath $(TOOLS_BIN_DIR)) go install -mod=mod github.com/onsi/ginkgo/v2/ginkgo@$(GINKGO_VERSION)

# run ptoject
run: build
	$(BIN_DIR)/$(BINARY)

# container image multi-platform build
.PHONY: docker
docker:
	$(foreach arch, $(DOCKER_BUILD_PLATFORM), docker build --platform $(arch) \
	--build-arg BINARY=$(BINARY) \
	--build-arg VERSION=$(VERSION) \
	--build-arg RUNTIME_IMAGE=$(DOCKER_RUNTIME_IMAGE) \
	--build-arg CONTAINERCMD=$(DOCKER_CMD) \
	--build-arg TARGETARCH=$(subst linux/,,$(arch)) \
	--tag $(REGISTRY)/$(BINARY):$(VERSION)-$(subst linux/,,$(arch)) -f $(ROOT_DIR)/Dockerfile .; )

# push container images
.PHONY: docker-push
docker-push: 
	$(foreach arch, $(DOCKER_BUILD_PLATFORM), docker push \
	$(REGISTRY)/$(BINARY):$(VERSION)-$(subst linux/,,$(arch)) ; )
	docker manifest rm $(REGISTRY)/$(BINARY):$(VERSION) || true
	docker manifest create $(REGISTRY)/$(BINARY):$(VERSION) $(foreach arch, $(DOCKER_BUILD_PLATFORM),--amend $(REGISTRY)/$(BINARY):$(VERSION)-$(subst linux/,,$(arch))) 
	$(foreach arch, $(DOCKER_BUILD_PLATFORM), docker manifest annotate --os linux --arch $(subst linux/,,$(arch)) $(REGISTRY)/$(BINARY):$(VERSION) $(REGISTRY)/$(BINARY):$(VERSION)-$(subst linux/,,$(arch)) ; ) 
	docker manifest push $(REGISTRY)/$(BINARY):$(VERSION)
	

