FROM golang:1.21 AS builder

WORKDIR /src

# Copy project sources
COPY . .
RUN go mod tidy
# Compiles the binary
ARG BINARY=
ARG VERSION=
ENV GOCACHE=/root/.cache/go-build
RUN --mount=type=cache,target="/root/.cache/go-build" \
    CGO_ENABLED=0 go build -ldflags="-X main.VERSION=${VERSION}" -o "/bin/${BINARY}" ./cmd/main.go


# Builds target image
FROM gcr.io/distroless/static:nonroot

ARG VERSION=latest
LABEL version=${VERSION}

ARG BINARY=
COPY --from=builder /bin/${BINARY} /bin/

# UID/GID 65532 is also known as nonroot user in distroless image
USER 65532:65532
ARG BINARY=
ENV BINARY=${BINARY}
CMD /bin/${BINARY}
