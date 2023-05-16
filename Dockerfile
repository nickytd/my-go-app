FROM golang:1.20 AS builder
ARG BASE=
WORKDIR $GOPATH/src/$BASE

# Copy project sources
COPY . .
RUN go mod tidy
# Compiles the binary
RUN make build

# Builds target image
FROM alpine:3.18.0

ARG VERSION=latest
LABEL version=${VERSION}

ARG BASE=
COPY --from=builder /go/src/$BASE /

# UID/GID 65532 is also known as nonroot user in distroless image
USER 65532:65532
ARG BINARY=
ENV BINARY=${BINARY}
CMD ${BINARY}
