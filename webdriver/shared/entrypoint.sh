#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=common.sh
source "$(dirname "$(realpath "$0")")/common.sh"

DISPLAY_NUM="${DISPLAY_NUM:-99}"
export DISPLAY="${DISPLAY:-:${DISPLAY_NUM}}"
SCREEN_RESOLUTION="${SCREEN_RESOLUTION:-1920x1080x24}"
WARM_API_DIR="${WARM_API_DIR:-/opt/warm/api}"

normalize_bool() {
  case "$(printf '%s' "${1:-}" | tr '[:upper:]' '[:lower:]')" in
    1|true|yes|on) printf 'true' ;;
    *) printf 'false' ;;
  esac
}

ENABLE_VNC="$(normalize_bool "${ENABLE_VNC:-false}")"
WARM_VIDEO="$(normalize_bool "${WARM_VIDEO:-true}")"

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

wait_for_tcp() {
  local host_port="$1"
  local i
  for ((i = 0; i < 120; i++)); do
    if curl -sf "http://${host_port}/status" >/dev/null 2>&1; then
      return 0
    fi
    sleep 0.25
  done
  echo "chromedriver did not become ready at ${host_port}" >&2
  return 1
}

cleanup() {
  terminate_pid "${warm_pid:-}"
  terminate_pid "${driver_pid:-}"
  terminate_pid "${vnc_pid:-}"
  terminate_pid "${xvfb_pid:-}"
}

trap cleanup EXIT
trap 'exit 143' TERM INT

mkdir -p "${WARM_VIDEO_DIR:-/data/video}"

if [[ "${ENABLE_VNC}" == "true" || "${WARM_VIDEO}" == "true" ]]; then
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

if ! command -v chromedriver >/dev/null 2>&1; then
  echo "chromedriver not found in PATH" >&2
  exit 1
fi

chromedriver --port=4444 --allowed-ips= --allowed-origins='*' --log-path=/tmp/chromedriver.log &
driver_pid=$!
wait_for_tcp "127.0.0.1:4444"

node "${WARM_API_DIR}/webdriver-warm-main.cjs" &
warm_pid=$!
wait "${warm_pid}"
