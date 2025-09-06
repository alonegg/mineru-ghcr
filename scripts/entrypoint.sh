#!/usr/bin/env bash
set -euo pipefail

# Environment variables:
#   MINERU_DOWNLOAD: 1 to enable downloading at start, 0 to skip (default 0)
#   MINERU_MODEL_SOURCE: modelscope or hf (default modelscope)
#   MINERU_MODEL_LIST: space/comma separated list of models to download; if empty and MINERU_DOWNLOAD=1, download core/minimal set or all based on flag
#   MINERU_DOWNLOAD_ALL: 1 to download all models when list is empty (default 0)

DOWNLOAD=${MINERU_DOWNLOAD:-0}
SRC=${MINERU_MODEL_SOURCE:-modelscope}
LIST=${MINERU_MODEL_LIST:-}
ALL=${MINERU_DOWNLOAD_ALL:-0}

if [[ "$DOWNLOAD" == "1" ]]; then
  echo "[entrypoint] Download requested. Source=$SRC"
  if [[ -n "$LIST" ]]; then
    # Normalize comma to space
    LIST_NORM=$(echo "$LIST" | tr ',' ' ')
    echo "[entrypoint] Downloading selected models: $LIST_NORM"
    for m in $LIST_NORM; do
      echo "[entrypoint] -> $m"
      mineru-models-download -s "$SRC" -m "$m" || {
        echo "[entrypoint] Failed to download $m" >&2
        exit 1
      }
    done
  else
    if [[ "$ALL" == "1" ]]; then
      echo "[entrypoint] Downloading ALL models"
      mineru-models-download -s "$SRC" -m all
    else
      echo "[entrypoint] Downloading CORE models"
      mineru-models-download -s "$SRC" -m core
    fi
  fi
else
  echo "[entrypoint] Skipping model downloads. Set MINERU_DOWNLOAD=1 to enable."
fi

# Execute the given command (default CMD)
exec "$@"
