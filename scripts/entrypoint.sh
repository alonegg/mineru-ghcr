#!/usr/bin/env bash
set -euo pipefail

# Environment variables:
#   MINERU_DOWNLOAD: 1 to enable downloading at start, 0 to skip (default 0)
#   MINERU_MODEL_SOURCE: modelscope or hf (default modelscope)
#   MINERU_MODEL_LIST: space/comma separated list of models to download; empty means core/all
#   MINERU_DOWNLOAD_ALL: 1 to download all models when list is empty (default 0)
#   MINERU_BOOTSTRAP_CMD: optional shell command to run for downloading models (takes precedence)

DOWNLOAD=${MINERU_DOWNLOAD:-0}
SRC=${MINERU_MODEL_SOURCE:-modelscope}
LIST=${MINERU_MODEL_LIST:-}
ALL=${MINERU_DOWNLOAD_ALL:-0}
BOOT=${MINERU_BOOTSTRAP_CMD:-}

normalize_list() {
  echo "$1" | tr ',' ' ' | xargs -n1 | paste -sd ' ' -
}

run_with_cmd() {
  echo "[entrypoint] Running bootstrap command: $1"
  sh -lc "$1"
}

try_download() {
  local tool="$1"; shift
  if command -v "$tool" >/dev/null 2>&1; then
    if [[ -n "$LIST" ]]; then
      local LIST_NORM; LIST_NORM=$(normalize_list "$LIST")
      echo "[entrypoint] Using $tool to download selected models: $LIST_NORM"
      for m in $LIST_NORM; do
        echo "[entrypoint] -> $m"
        "$tool" -s "$SRC" -m "$m"
      done
    else
      if [[ "$ALL" == "1" ]]; then
        echo "[entrypoint] Using $tool to download ALL models"
        "$tool" -s "$SRC" -m all
      else
        echo "[entrypoint] Using $tool to download CORE models"
        "$tool" -s "$SRC" -m core
      fi
    fi
    return 0
  fi
  return 1
}

if [[ "$DOWNLOAD" == "1" ]]; then
  echo "[entrypoint] Download requested. Source=$SRC"
  if [[ -n "$BOOT" ]]; then
    run_with_cmd "$BOOT"
  else
    # Try known MinerU download CLIs (best-effort)
    if ! try_download mineru-models-download; then
      if ! try_download mineru-download-models; then
        echo "[entrypoint] No known MinerU download CLI found. Set MINERU_BOOTSTRAP_CMD with your download command." >&2
      fi
    fi
  fi
else
  echo "[entrypoint] Skipping model downloads. Set MINERU_DOWNLOAD=1 to enable."
fi

# Execute the given command (default CMD)
exec "$@"
