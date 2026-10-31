#!/usr/bin/env bash
set -euo pipefail

source_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
mkdir -p "$HOME/.local/bin"
install -m 700 "$source_dir/wpgp" "$HOME/.local/bin/wpgp"

if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
  path_line='export PATH="$HOME/.local/bin:$PATH"'
  if [[ -f "$HOME/.bashrc" ]] && ! grep -Fq "$path_line" "$HOME/.bashrc"; then
    printf '\n%s\n' "$path_line" >> "$HOME/.bashrc"
  fi
fi

printf 'Installed Wpgp to %s/.local/bin/wpgp\n' "$HOME"
printf 'Open a new terminal, then run: wpgp\n'
