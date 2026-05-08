#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${DAM_HOME:-${XDG_CONFIG_HOME:-$HOME/.config}/dev-alias-manager}"
MODE="--auto"
RUN_WIZARD=1
CLEAN=0
PROMPT_RELOAD=1

if [ -t 1 ]; then
  DAM_RED="$(printf '\033[38;5;196m')"
  DAM_GREEN="$(printf '\033[38;5;46m')"
  DAM_ORANGE="$(printf '\033[38;5;208m')"
  DAM_PINK="$(printf '\033[38;5;203m')"
  DAM_YELLOW="$(printf '\033[38;5;220m')"
  DAM_GRAY="$(printf '\033[38;5;245m')"
  DAM_DIM="$(printf '\033[38;5;238m')"
  DAM_BOLD="$(printf '\033[1m')"
  DAM_RESET="$(printf '\033[0m')"
else
  DAM_RED=""; DAM_GREEN=""; DAM_ORANGE=""; DAM_PINK=""; DAM_YELLOW=""; DAM_GRAY=""; DAM_DIM=""; DAM_BOLD=""; DAM_RESET=""
fi

dam_install_action() {
  echo
  echo "${DAM_RED}${DAM_BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${DAM_RESET}"
  echo "${DAM_RED}${DAM_BOLD}Action Required${DAM_RESET}"
  echo "${DAM_RED}${DAM_BOLD}$1${DAM_RESET}"
  [ -n "${2:-}" ] && echo "${DAM_GRAY}$2${DAM_RESET}"
  echo "${DAM_RED}${DAM_BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${DAM_RESET}"
}

dam_install_panel() {
  echo
  echo "${DAM_RED}${DAM_BOLD}╭────────────────────────────────────────────────────────────╮${DAM_RESET}"
  printf "${DAM_RED}${DAM_BOLD}│${DAM_RESET} ${DAM_PINK}${DAM_BOLD}%-58.58s${DAM_RESET} ${DAM_RED}${DAM_BOLD}│${DAM_RESET}\n" "$1"
  [ -n "${2:-}" ] && echo "${DAM_GRAY}$2${DAM_RESET}"
  echo "${DAM_RED}${DAM_BOLD}╰────────────────────────────────────────────────────────────╯${DAM_RESET}"
}

dam_install_ok() {
  echo "${DAM_GREEN}✓${DAM_RESET} $1"
}

dam_install_warn() {
  echo "${DAM_YELLOW}!${DAM_RESET} $1"
}

dam_prompt_yes_no() {
  local prompt_label="$1"
  local answer

  while true; do
    printf "${DAM_RED}${DAM_BOLD}%s${DAM_RESET} " "$prompt_label"
    read -r answer

    case "$answer" in
      ""|y|Y|yes|YES|Yes)
        return 0
        ;;
      n|N|no|NO|No)
        return 1
        ;;
      *)
        echo
        dam_install_warn "Please answer with Enter/y/yes or n/no."
        echo "${DAM_GRAY}Example: press Enter for Yes, or type n for No.${DAM_RESET}"
        echo
        ;;
    esac
  done
}

for arg in "$@"; do
  case "$arg" in
    --zsh|--bash|--both|--auto) MODE="$arg" ;;
    --no-wizard) RUN_WIZARD=0 ;;
    --no-clean) CLEAN=0 ;;
    --clean) CLEAN=1 ;;
    --no-reload-prompt) PROMPT_RELOAD=0 ;;
    -h|--help)
      cat <<'EOF'
Usage: ./install.sh [--auto|--zsh|--bash|--both] [--clean] [--no-wizard] [--no-reload-prompt]

Default behavior:
  - installs or updates DAM
  - keeps existing aliases, Daily Favorites, and config
  - opens wizard
  - detects your current shell and writes the source block there
  - lets you choose Daily Favorites from installed aliases
  - asks whether to reload shell now

Options:
  --auto              detect zsh/bash from $SHELL and current process
  --zsh               configure ~/.zshrc
  --bash              configure ~/.bashrc
  --both              configure ~/.zshrc and ~/.bashrc
  --clean             remove existing DAM config before install
  --no-clean          keep existing DAM files
  --no-wizard         install without opening wizard
  --no-reload-prompt  do not ask to reload shell
EOF
      exit 0
      ;;
    *)
      echo "Unknown argument: $arg"
      echo "Use: ./install.sh --help"
      exit 1
      ;;
  esac
done

backup_rc() {
  local file="$1"
  [ -f "$file" ] || return 0
  cp "$file" "$file.dam-backup.$(date +%F-%H%M%S)"
}

clean_dam() {
  echo "Preparing fresh Dev Alias Manager install..."
  backup_rc "$HOME/.zshrc"
  backup_rc "$HOME/.bashrc"
  perl -0pi -e 's/\n?# >>> dev-alias-manager >>>.*?# <<< dev-alias-manager <<<\n?/\n/s' "$HOME/.zshrc" "$HOME/.bashrc" 2>/dev/null || true
  rm -rf "$CONFIG_DIR"
}

if [ "$CLEAN" = "1" ]; then clean_dam; fi

mkdir -p "$CONFIG_DIR"

if [ -f "$CONFIG_DIR/dam.sh" ]; then
  dam_install_panel "Existing DAM install found" "A backup will be created. Your aliases, Daily Favorites, and config stay in place."
  cp "$CONFIG_DIR/dam.sh" "$CONFIG_DIR/dam.sh.backup.$(date +%F-%H%M%S)"
fi

cp "$ROOT_DIR/core/dam.sh" "$CONFIG_DIR/dam.sh"
mkdir -p "$CONFIG_DIR/presets"
touch "$CONFIG_DIR/commands.sh" "$CONFIG_DIR/commands.db" "$CONFIG_DIR/custom-aliases.sh" "$CONFIG_DIR/daily.db"

add_source_block() {
  local rc_file="$1"
  local shell_source="$2"
  local source_path="$CONFIG_DIR/dam.sh"
  touch "$rc_file"

  if grep -q "dev-alias-manager/dam.sh" "$rc_file" || grep -qF "$source_path" "$rc_file"; then
    echo "Already configured: $rc_file"
    return 0
  fi

  cat >> "$rc_file" <<EOF

# >>> dev-alias-manager >>>
if [ -f "$source_path" ]; then
  ${shell_source} "$source_path"
fi
# <<< dev-alias-manager <<<
EOF

  echo "Configured: $rc_file"
}

detect_shell_mode() {
  case "${SHELL##*/}" in
    zsh) echo "--zsh"; return 0 ;;
    bash) echo "--bash"; return 0 ;;
  esac
  if [ -n "${ZSH_VERSION:-}" ]; then
    echo "--zsh"
  elif [ -n "${BASH_VERSION:-}" ]; then
    echo "--bash"
  else
    echo "--both"
  fi
}

if [ "$MODE" = "--auto" ]; then
  MODE="$(detect_shell_mode)"
fi

case "$MODE" in
  --zsh) add_source_block "$HOME/.zshrc" "source" ;;
  --bash) add_source_block "$HOME/.bashrc" "." ;;
  --both|"")
    add_source_block "$HOME/.zshrc" "source"
    add_source_block "$HOME/.bashrc" "."
    ;;
esac

echo
dam_install_ok "Dev Alias Manager installed."
echo "${DAM_GRAY}Only aliases/help were installed. External programs were not installed.${DAM_RESET}"
echo "${DAM_GRAY}Shell source target: ${DAM_ORANGE}${MODE#--}${DAM_RESET}"
echo

# shellcheck disable=SC1090
source "$CONFIG_DIR/dam.sh"

dam_install_conflict_preview() {
  [ -t 0 ] || return 0

  local names name existing found=0
  names="$(awk '$1 == "_dam_add_full" && $2 !~ /^\$/ {print $2}' "$ROOT_DIR/core/dam.sh" | sort -u)"

  for name in $names; do
    [ -n "$(_dam_db_find "$name")" ] && continue
    if command -v "$name" >/dev/null 2>&1; then
      if [ "$found" = "0" ]; then
        dam_install_panel "Alias name conflicts found" "Before setup saves aliases, you can skip/delete the DAM alias, replace/shadow the existing command, or rename it."
        printf "${DAM_RED}${DAM_BOLD}%-18s${DAM_RESET} %s\n" "Alias" "Existing command"
        echo "${DAM_DIM}────────────────────────────────────────────────────────────${DAM_RESET}"
        found=1
      fi
      existing="$(command -V "$name" 2>/dev/null | head -1)"
      printf "${DAM_ORANGE}%-18s${DAM_RESET} %s\n" "$name" "${existing:-already exists}"
    fi
  done

  if [ "$found" = "1" ]; then
    echo
    echo "${DAM_GRAY}You will be asked what to do for each conflict while installing selected packs.${DAM_RESET}"
  fi
}

dam_install_conflict_preview

if [ "$RUN_WIZARD" = "1" ] && [ -t 0 ]; then
  dam wizard || true
else
  dam repair || true
fi

if [ -t 0 ]; then
  dam_install_panel "Choose Daily Favorites? [Y/n]" "Optional. Pick aliases with checkboxes or add one later with: dam daily add NAME"
  if dam_prompt_yes_no "Open Daily chooser [Y/n]:"; then
    dam daily choose || true
  else
    dam_install_warn "Skipped Daily Favorites setup."
    echo
    echo "${DAM_RED}${DAM_BOLD}Run later:${DAM_RESET} dam daily choose"
    echo "${DAM_GRAY}Search first:${DAM_RESET} dam search sail"
  fi
else
  dam daily table || true
fi

reload_shell_prompt() {
  [ "$PROMPT_RELOAD" = "1" ] || return 0

  dam_install_action "Source/reload shell now? [Y/n]" "Asked after setup closes so this terminal can use dam, Daily Favorites, and aliases immediately. Press Enter for Yes."

  if [ -t 0 ]; then
    if dam_prompt_yes_no "Choose [Y/n]:"; then
      touch "$CONFIG_DIR/open-daily-after-reload"
      echo "${DAM_GREEN}Sourcing shell config by starting a fresh login shell...${DAM_RESET}"
      exec "$SHELL" -l
    else
      echo
      dam_install_warn "Shell was not reloaded."
      echo
      echo "${DAM_RED}${DAM_BOLD}Run manually now:${DAM_RESET}"
      echo "  source ~/.zshrc"
      echo "  # or"
      echo "  source ~/.bashrc"
      echo
      echo "${DAM_GRAY}Then test:${DAM_RESET}"
      echo "  dam help"
      echo "  dam daily"
    fi
  else
    echo "${DAM_RED}${DAM_BOLD}Run manually:${DAM_RESET}"
    echo "  source ~/.zshrc"
    echo "  # or"
    echo "  source ~/.bashrc"
  fi
}

reload_shell_prompt
