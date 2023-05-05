FROM --platform=${TARGETPLATFORM} golang:1.20 AS builder
ARG GO_MODULE
WORKDIR $GOPATH/src/${GO_MODULE}

# Copy project sources
COPY . .
RUN go mod tidy
# Compiles the binary
RUN make build

# Builds target image
FROM --platform="${TARGETPLATFORM}" debian:stable-slim
ARG CONTAINER_CMD
ARG VERSION
ARG BINARY
LABEL version=${VERSION}
ENV cmd=${CONTAINER_CMD}
COPY --from=builder /go/src/${BINARY} /${CONTAINER_CMD}

# UID/GID 65532 is also known as nonroot user in distroless image
USER 65532:65532
CMD /$cmd
