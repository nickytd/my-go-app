FROM --platform=${TARGETPLATFORM} golang:1.20 AS builder
ARG BINARY
ARG VERSION
ARG TARGETPLATFORM
ARG TARGETARCH
WORKDIR $GOPATH/src/${BINARY}

# Copy project sources
COPY . .
RUN go mod tidy

# Compiles the binary
RUN GOOS=linux GOARCH=${TARGETARCH} VERSION=${VERSION} CGOENABLED=0 \
    go build -a -installsuffix cgo -ldflags="-X main.VERSION=${VERSION}" \
    -o /${BINARY} cmd/main.go


# Builds target image
FROM --platform="${TARGETPLATFORM}" debian:stable-slim
ARG CONTAINERCMD
ARG VERSION
ARG BINARY
LABEL version=${VERSION}
ENV cmd="${CONTAINERCMD}"
COPY --from=builder /${BINARY} /bin

# UID/GID 65532 is also known as nonroot user in distroless image
USER 65532:65532
CMD /bin/$cmd
