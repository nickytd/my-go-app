#!/usr/bin/env bash

set -e

DOCKER_BUILD_PLATFORM="${1:-linux/amd64}"

DOCKER_CONTAINER_IMAGE="${2:-}"
if [ -z ${DOCKER_CONTAINER_IMAGE} ]; then
  echo "DOCKER_CONTAINER_IMAGE is required"
  exit 1
fi

BASE="${3:-}"
if [ -z ${BASE} ]; then
  echo "BASE is required"
  exit 1
fi

BINARY="${4:-}"
if [ -z ${BINARY} ]; then
  echo "BINARY is required"
  exit 1
fi
VERSION="${5:-latest}" 


if docker buildx inspect $BINARY > /dev/null 2>&1; then
	echo "using $BINARY builder"
else
	echo "creating $BINARY builder"
	docker buildx create --name $BINARY --use
fi

docker buildx build --platform="${DOCKER_BUILD_PLATFORM}" \
  --tag ${DOCKER_CONTAINER_IMAGE} \
  --build-arg BASE="${BASE}" \
  --build-arg BINARY="${BINARY}" \
  --build-arg VERSION="${VERSION}" \
  --push -f Dockerfile .
