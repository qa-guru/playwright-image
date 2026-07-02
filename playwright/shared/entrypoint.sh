#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=common.sh
source "$(dirname "$(realpath "$0")")/common.sh"

DISPLAY_NUM="${DISPLAY_NUM:-99}"
export DISPLAY="${DISPLAY:-:${DISPLAY_NUM}}"
SCREEN_RESOLUTION="${SCREEN_RESOLUTION:-1920x1080x24}"

normalize_bool() {
  case "$(printf '%s' "${1:-}" | tr '[:upper:]' '[:lower:]')" in
    1|true|yes|on) printf 'true' ;;
    *) printf 'false' ;;
  esac
}

ENABLE_VNC="$(normalize_bool "${ENABLE_VNC:-false}")"
ENABLE_VIDEO="$(normalize_bool "${ENABLE_VIDEO:-false}")"
MANUAL_SESSION="$(normalize_bool "${MANUAL_SESSION:-false}")"
PW_HEADLESS="$(normalize_bool "${PW_HEADLESS:-true}")"
WARM_ENABLED="$(normalize_bool "${WARM_ENABLED:-false}")"
WARM_API_DIR="${WARM_API_DIR:-/opt/playwright/warm-api}"
PW_PORT="${PW_PORT:-3000}"
PW_PATH="${PW_PATH:-/}"
WARM_VIDEO="$(normalize_bool "${WARM_VIDEO:-true}")"

needs_display=false
if [[ "${ENABLE_VNC}" == "true" || "${ENABLE_VIDEO}" == "true" || "${WARM_VIDEO}" == "true" ]]; then
  needs_display=true
fi

if [[ "${WARM_ENABLED}" == "true" ]]; then
  mkdir -p "${WARM_VIDEO_DIR:-/data/video}"
fi

wait_for_x() {
  local i
  for ((i = 0; i < 50; i++)); do
    if xdpyinfo -display "${DISPLAY}" >/dev/null 2>&1; then
      return 0
    fi
    sleep 0.1
  done
  echo "X display ${DISPLAY} did not become ready in time" >&2
  return 1
}

wait_for_http() {
  local url="$1"
  local i
  for ((i = 0; i < 120; i++)); do
    if curl -sf "${url}" >/dev/null 2>&1; then
      return 0
    fi
    sleep 0.25
  done
  echo "HTTP endpoint did not become ready: ${url}" >&2
  return 1
}

cleanup() {
  terminate_pid "${warm_pid:-}"
  terminate_pid "${server_pid:-}"
  terminate_pid "${headed_pid:-}"
  terminate_pid "${vnc_pid:-}"
  terminate_pid "${xvfb_pid:-}"
}

trap cleanup EXIT
trap 'exit 143' TERM INT

if [[ "${needs_display}" == "true" ]]; then
  Xvfb "${DISPLAY}" -screen 0 "${SCREEN_RESOLUTION}" -ac +extension RANDR -noreset -listen tcp >/dev/null 2>&1 &
  xvfb_pid=$!
  wait_for_x
fi

if [[ "${ENABLE_VNC}" == "true" ]]; then
  x11vnc \
    -display "${DISPLAY}" \
    -rfbport 5900 \
    -forever \
    -shared \
    -passwd selenoid \
    >/dev/null 2>&1 &
  vnc_pid=$!
fi

if [[ "${MANUAL_SESSION}" == "true" && "${PW_HEADLESS}" == "false" && "${ENABLE_VNC}" == "true" ]]; then
  node /opt/playwright/launch-headed-browser.js >>/tmp/headed-launch.log 2>&1 &
  headed_pid=$!
fi

node /opt/playwright/server.cjs &
server_pid=$!

if [[ "${WARM_ENABLED}" == "true" ]]; then
  wait_for_http "http://127.0.0.1:${PW_PORT}/"
  export PW_WS_ENDPOINT="ws://127.0.0.1:${PW_PORT}${PW_PATH:-/}"
  node "${WARM_API_DIR}/playwright-warm-main.cjs" &
  warm_pid=$!
fi

wait "${server_pid}"
