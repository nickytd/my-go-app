#!/usr/bin/env bash

set -e

CONTAINER_BUILD_PLATFORM="${1:-linux/amd64}"

CONTAINER_IMAGE="${2:-}"
if [ -z ${CONTAINER_IMAGE} ]; then
  echo "CONTAINER_IMAGE is required"
  exit 1
fi

BINARY="${3:-}"
if [ -z ${BINARY} ]; then
  echo "BINARY is required"
  exit 1
fi
VERSION="${4:-latest}"


if docker buildx inspect $BINARY > /dev/null 2>&1; then
	echo "using $BINARY builder"
else
	echo "creating $BINARY builder"
	docker buildx create --name $BINARY --use
fi

docker buildx build --platform="${CONTAINER_BUILD_PLATFORM}" \
  --tag ${CONTAINER_IMAGE} \
  --build-arg BINARY="${BINARY}" \
  --build-arg VERSION="${VERSION}" \
  --push -f Dockerfile .
