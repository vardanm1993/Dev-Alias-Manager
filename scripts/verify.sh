#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

bash -n install.sh
bash -n uninstall.sh
bash -n core/dam.sh

if command -v zsh >/dev/null 2>&1; then
  zsh -n core/dam.sh
fi

run_behavior_test() {
  local shell_bin="$1"

  "$shell_bin" -c '
    set -e
    tmp="$(mktemp -d)"
    export DAM_HOME="$tmp"
    . ./core/dam.sh

    dam add say system printf "Print args" >/dev/null
    out="$(say "%s|%s\n" "hello world" ok)"
    [ "$out" = "hello world|ok" ]

    dam preset fullstack >/dev/null
    [ "$(wc -l < "$DAM_HOME/commands.db")" -ge 90 ]

    gs >/tmp/dam-verify-gs.out 2>&1 || true
    ! grep -q "git status -sb not found" /tmp/dam-verify-gs.out

    dam search route >/tmp/dam-verify-search.out
    grep -q "myroutes" /tmp/dam-verify-search.out

    dam daily install >/tmp/dam-verify-daily.out
    [ "$(wc -l < "$DAM_HOME/daily.db")" -ge 10 ]
    dam daily recommended >/tmp/dam-verify-recommended.out
    grep -q "projectdoctor" /tmp/dam-verify-recommended.out
    dam daily add myroutes >/dev/null
    grep -q "^myroutes|" "$DAM_HOME/daily.db"
    dam daily remove myroutes >/dev/null
    ! grep -q "^myroutes|" "$DAM_HOME/daily.db"
  '
}

run_behavior_test bash

if command -v zsh >/dev/null 2>&1; then
  run_behavior_test zsh
fi

tmp_home="$(mktemp -d)"
custom_home="$tmp_home/custom-dam"
HOME="$tmp_home" DAM_HOME="$custom_home" SHELL=/bin/bash ./install.sh --bash --no-wizard --no-reload-prompt >/tmp/dam-verify-install.out
grep -qF "$custom_home/dam.sh" "$tmp_home/.bashrc"
[ -f "$custom_home/dam.sh" ]
[ -f "$custom_home/presets/recommended-daily.tsv" ]
[ "$(wc -l < "$custom_home/commands.db")" -ge 90 ]

echo 'Shell syntax and behavior OK.'
