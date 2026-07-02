#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WARM_API_SRC="${ROOT}/../warm-pool-orchestrator/warm-api"
BROWSER="${1:-}"
VERSION="${2:-1.61.1}"
VARIANT="${3:-}"

if [[ -z "${BROWSER}" ]]; then
  echo "Usage: $0 <browser> [version-tag] [variant]" >&2
  echo "Browsers: chromium firefox webkit chrome msedge all" >&2
  echo "Variants: (default) | min (chromium only)" >&2
  exit 1
fi

if [[ -n "${VARIANT}" && "${VARIANT}" != "min" ]]; then
  echo "Unknown variant: ${VARIANT}" >&2
  exit 1
fi

if [[ "${VARIANT}" == "min" && "${BROWSER}" != "chromium" ]]; then
  echo "Variant min is only supported for chromium" >&2
  exit 1
fi

normalize_version() {
  local v="${1#v}"
  v="${v%-noble}"
  printf '%s' "$v"
}

PW_PACKAGE="$(normalize_version "${VERSION}")"

if [[ -z "${PLATFORM:-}" ]]; then
  case "$(uname -m)" in
    arm64|aarch64) PLATFORM="linux/arm64" ;;
    *) PLATFORM="linux/amd64" ;;
  esac
fi

stage_warm_api() {
  if [[ ! -d "${WARM_API_SRC}" ]]; then
    echo "warm-api not found at ${WARM_API_SRC}" >&2
    exit 1
  fi
  rm -rf "${ROOT}/warm-api"
  cp -R "${WARM_API_SRC}" "${ROOT}/warm-api"
}

build_one() {
  local browser="$1"
  local image="qaguru/playwright-${browser}"
  local tag="${image}:${PW_PACKAGE}"
  local dockerfile="${ROOT}/playwright-${browser}/Dockerfile"

  if [[ "${VARIANT}" == "min" ]]; then
    dockerfile="${ROOT}/playwright-${browser}/Dockerfile.min.scratch"
    tag="${image}:${PW_PACKAGE}-min"
  fi

  if [[ ! -f "${dockerfile}" ]]; then
    echo "Unknown browser: ${browser}" >&2
    exit 1
  fi

  if [[ "${VARIANT}" != "min" ]]; then
    stage_warm_api
  fi

  docker build \
    --platform "${PLATFORM}" \
    --build-arg "PLAYWRIGHT_VERSION=${PW_PACKAGE}" \
    -f "${dockerfile}" \
    -t "${tag}" \
    "${ROOT}"

  echo "Built ${tag}"
  rm -rf "${ROOT}/warm-api"
}

if [[ "${BROWSER}" == "all" ]]; then
  for b in chromium firefox webkit chrome msedge; do
    build_one "${b}"
  done
else
  build_one "${BROWSER}"
fi
