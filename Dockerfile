ARG RUNTIME_IMAGE=alpine:3.16
FROM --platform=${BUILDPLATFORM} golang:1.19 AS builder
ARG BINARY

WORKDIR $GOPATH/src/${BINARY}

# Copy project sources
COPY . .
RUN go mod download

ARG VERSION
ARG TARGETPLATFORM
ARG BUILDPLATFORM

# Compiles the binary
RUN GOARCH=${GOARCH} VERSION=${VERSION} CGO_ENABLED=0 \
    go build -a -installsuffix cgo -ldflags="-X main.VERSION=${VERSION}" \
    -o ${BINARY} cmd/main.go

# Builds target image
FROM ${RUNTIME_IMAGE}
ARG BINARY
COPY --from=builder /go/src/${BINARY}/${BINARY} /bin/${BINARY}

# UID/GID 65532 is also known as nonroot user in distroless image
USER 65532:65532

ENTRYPOINT ["/bin/${BINARY}"]
