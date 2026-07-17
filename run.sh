#!/usr/bin/env bash

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GODOT_BIN="${GODOT_BIN:-}"

if [[ -z "$GODOT_BIN" ]]; then
  if command -v godot >/dev/null 2>&1; then
    GODOT_BIN="$(command -v godot)"
  elif [[ -x "/Applications/Godot.app/Contents/MacOS/Godot" ]]; then
    GODOT_BIN="/Applications/Godot.app/Contents/MacOS/Godot"
  elif [[ -x "$HOME/Applications/Godot.app/Contents/MacOS/Godot" ]]; then
    GODOT_BIN="$HOME/Applications/Godot.app/Contents/MacOS/Godot"
  else
    echo "Error: Godot was not found." >&2
    echo "Install Godot, add it to PATH, or set GODOT_BIN=/path/to/Godot." >&2
    exit 1
  fi
fi

if [[ ! -x "$GODOT_BIN" ]]; then
  echo "Error: GODOT_BIN is not executable: $GODOT_BIN" >&2
  exit 1
fi

exec "$GODOT_BIN" --path "$PROJECT_DIR" "$@"
