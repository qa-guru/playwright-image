#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VERSION="${1:-v1.61.1-noble}"
TAG="${DOCKER_IMAGE:-qaguru/playwright}:${VERSION}"
PW_PACKAGE="${VERSION#v}"
PW_PACKAGE="${PW_PACKAGE%-noble}"
if [[ -z "${PLATFORM:-}" ]]; then
  case "$(uname -m)" in
    arm64|aarch64) PLATFORM="linux/arm64" ;;
    *) PLATFORM="linux/amd64" ;;
  esac
fi

docker build \
  --platform "${PLATFORM}" \
  --build-arg "PLAYWRIGHT_VERSION=${VERSION}" \
  --build-arg "PLAYWRIGHT_PACKAGE=${PW_PACKAGE}" \
  -t "${TAG}" \
  "${ROOT}"

echo "Built ${TAG}"
