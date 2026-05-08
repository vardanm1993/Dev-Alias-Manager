#!/usr/bin/env bash
set -Eeuo pipefail

remove_block() {
  local file="$1"
  [ -f "$file" ] || return 0
  cp "$file" "$file.dam-backup.$(date +%F-%H%M%S)"
  perl -0pi -e 's/\n?# >>> dev-alias-manager >>>.*?# <<< dev-alias-manager <<<\n?/\n/s' "$file"
  echo "Removed source block from: $file"
}

remove_block "$HOME/.zshrc"
remove_block "$HOME/.bashrc"

if [ "${1:-}" = "--purge" ]; then
  rm -rf "${DAM_HOME:-${XDG_CONFIG_HOME:-$HOME/.config}/dev-alias-manager}"
  echo "Purged config directory."
else
  echo "Config kept at: ${DAM_HOME:-${XDG_CONFIG_HOME:-$HOME/.config}/dev-alias-manager}"
fi
