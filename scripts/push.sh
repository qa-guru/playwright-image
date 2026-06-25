#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VERSION="${1:-v1.61.1-noble}"
IMAGE="${DOCKER_IMAGE:-qaguru/playwright}"
TAG="${IMAGE}:${VERSION}"
PW_PACKAGE="${VERSION#v}"
PW_PACKAGE="${PW_PACKAGE%-noble}"
PLATFORMS="${PLATFORMS:-linux/amd64,linux/arm64}"
BUILDER="${BUILDER:-playwright-image}"

if ! docker info >/dev/null 2>&1; then
  echo "Docker is not running." >&2
  exit 1
fi

if ! docker-credential-desktop list 2>/dev/null | grep -q 'index.docker.io'; then
  echo "Run: docker login" >&2
  echo "Push to ${IMAGE} requires write access to the Docker Hub namespace." >&2
  exit 1
fi

if ! docker buildx inspect "${BUILDER}" >/dev/null 2>&1; then
  docker buildx create --name "${BUILDER}" --driver docker-container --use
else
  docker buildx use "${BUILDER}"
fi

docker buildx build \
  --pull \
  --platform "${PLATFORMS}" \
  --build-arg "PLAYWRIGHT_VERSION=${VERSION}" \
  --build-arg "PLAYWRIGHT_PACKAGE=${PW_PACKAGE}" \
  -t "${TAG}" \
  --push \
  "${ROOT}"

echo "Pushed ${TAG} for ${PLATFORMS}"
