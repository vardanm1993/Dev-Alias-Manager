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

    function takenalias { :; }
    dam add takenalias system true "Should skip conflict" >/tmp/dam-verify-conflict.out
    ! grep -q "^takenalias	" "$DAM_HOME/commands.db"

    dam preset fullstack >/dev/null
    [ "$(wc -l < "$DAM_HOME/commands.db")" -ge 125 ]
    grep -q "^srector	" "$DAM_HOME/commands.db"
    grep -q "^spint	" "$DAM_HOME/commands.db"
    grep -q "^spest	" "$DAM_HOME/commands.db"
    grep -q "^snpm	" "$DAM_HOME/commands.db"
    grep -q "^smig	" "$DAM_HOME/commands.db"
    grep -q "^sqa	" "$DAM_HOME/commands.db"

    gst >/tmp/dam-verify-gst.out 2>&1 || true
    ! grep -q "git status -sb not found" /tmp/dam-verify-gst.out

    dam search route >/tmp/dam-verify-search.out
    grep -q "myroutes" /tmp/dam-verify-search.out

    dam daily add myroutes routes >/dev/null
    grep -q "^myroutes|" "$DAM_HOME/daily.db"
    grep -q "^routes|" "$DAM_HOME/daily.db"
    dam daily add sup >/dev/null
    grep -q "^sup|" "$DAM_HOME/daily.db"
    printf "art routes\n" | dam daily browse >/tmp/dam-verify-daily-browse.out
    grep -q "^art|" "$DAM_HOME/daily.db"
    dam daily move sup 1 >/tmp/dam-verify-daily-move.out
    [ "$(_head="$(sed -n 1p "$DAM_HOME/daily.db")"; printf "%s" "${_head%%|*}")" = "sup" ]
    dam daily down 1 >/tmp/dam-verify-daily-down.out
    [ "$(_head="$(sed -n 2p "$DAM_HOME/daily.db")"; printf "%s" "${_head%%|*}")" = "sup" ]
    dam daily up sup >/tmp/dam-verify-daily-up.out
    [ "$(_head="$(sed -n 1p "$DAM_HOME/daily.db")"; printf "%s" "${_head%%|*}")" = "sup" ]
    dam daily remove myroutes >/dev/null
    ! grep -q "^myroutes|" "$DAM_HOME/daily.db"
    dam daily delete sup art >/dev/null
    ! grep -q "^sup|" "$DAM_HOME/daily.db"
    ! grep -q "^art|" "$DAM_HOME/daily.db"
    dam daily add sup art myroutes >/dev/null
    dam daily delete 1 2 >/dev/null
    ! grep -q "^sup|" "$DAM_HOME/daily.db"
    ! grep -q "^art|" "$DAM_HOME/daily.db"
    grep -q "^myroutes|" "$DAM_HOME/daily.db"
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
[ "$(wc -l < "$custom_home/commands.db")" -ge 125 ]

printf "custom|Keep me\n" > "$custom_home/daily.db"
HOME="$tmp_home" DAM_HOME="$custom_home" SHELL=/bin/bash ./install.sh --bash --no-wizard --no-reload-prompt </dev/null >/tmp/dam-verify-reinstall-keep.out
grep -q "^custom|" "$custom_home/daily.db"

printf "n\n" | HOME="$tmp_home" DAM_HOME="$custom_home" SHELL=/bin/bash ./install.sh --bash --no-wizard --no-reload-prompt >/tmp/dam-verify-reinstall-interactive-keep.out
grep -q "^custom|" "$custom_home/daily.db"

printf "y\n" | HOME="$tmp_home" DAM_HOME="$custom_home" SHELL=/bin/bash ./install.sh --bash --no-wizard --no-reload-prompt >/tmp/dam-verify-reinstall-delete.out
! grep -q "^custom|" "$custom_home/daily.db"

echo 'Shell syntax and behavior OK.'
