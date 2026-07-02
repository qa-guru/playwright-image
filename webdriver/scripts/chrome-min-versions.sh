#!/usr/bin/env bash
set -euo pipefail

# Chrome CfT builds aligned with playwright-chromium -min images.
# PW 1.61.1-min -> Chromium 149.0.7827.55
# PW 1.60.0-min -> Chromium 148.0.7778.96

resolve_chrome_cft_version() {
  local version="${1#v}"
  version="${version%-min}"

  case "${version}" in
    1.61.1) printf '%s' "149.0.7827.55" ;;
    1.60.0) printf '%s' "148.0.7778.96" ;;
    149|149.0) printf '%s' "149.0.7827.55" ;;
    148|148.0) printf '%s' "148.0.7778.96" ;;
    *.*.*.*) printf '%s' "${version}" ;;
    *)
      echo "Unknown chrome-min version: ${1}" >&2
      echo "Use 148, 149, 1.60.0, 1.61.1, or full CfT version (e.g. 149.0.7827.55)." >&2
      return 1
      ;;
  esac
}

resolve_chrome_major() {
  local cft
  cft="$(resolve_chrome_cft_version "$1")"
  printf '%s' "${cft%%.*}"
}

resolve_min_tag() {
  local major
  major="$(resolve_chrome_major "$1")"
  printf '%s' "${major}-min"
}
