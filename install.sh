#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${DAM_HOME:-${XDG_CONFIG_HOME:-$HOME/.config}/dev-alias-manager}"
MODE="--both"
RUN_WIZARD=1
CLEAN=0
PROMPT_RELOAD=1

if [ -t 1 ]; then
  DAM_RED="$(printf '\033[38;5;196m')"
  DAM_GREEN="$(printf '\033[38;5;46m')"
  DAM_YELLOW="$(printf '\033[38;5;220m')"
  DAM_GRAY="$(printf '\033[38;5;245m')"
  DAM_BOLD="$(printf '\033[1m')"
  DAM_RESET="$(printf '\033[0m')"
else
  DAM_RED=""; DAM_GREEN=""; DAM_YELLOW=""; DAM_GRAY=""; DAM_BOLD=""; DAM_RESET=""
fi

dam_install_action() {
  echo
  echo "${DAM_RED}${DAM_BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${DAM_RESET}"
  echo "${DAM_RED}${DAM_BOLD}Action Required${DAM_RESET}"
  echo "${DAM_RED}${DAM_BOLD}$1${DAM_RESET}"
  [ -n "${2:-}" ] && echo "${DAM_GRAY}$2${DAM_RESET}"
  echo "${DAM_RED}${DAM_BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${DAM_RESET}"
}

dam_install_recommended() {
  echo
  echo "${DAM_RED}${DAM_BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${DAM_RESET}"
  echo "${DAM_RED}${DAM_BOLD}Recommended${DAM_RESET}"
  echo "${DAM_RED}${DAM_BOLD}$1${DAM_RESET}"
  [ -n "${2:-}" ] && echo "${DAM_GRAY}$2${DAM_RESET}"
  echo "${DAM_RED}${DAM_BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${DAM_RESET}"
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

dam_install_recommended_daily_preview() {
  echo
  echo "${DAM_RED}${DAM_BOLD}Recommended Daily Favorites that will be merged:${DAM_RESET}"
  echo "${DAM_GRAY}Your custom Daily Favorites will NOT be deleted.${DAM_RESET}"
  echo
  printf "  ${DAM_RED}%-16s${DAM_RESET} %s\n" "projectdoctor" "Check current Laravel project"
  printf "  ${DAM_RED}%-16s${DAM_RESET} %s\n" "myroutes"      "Show Laravel routes"
  printf "  ${DAM_RED}%-16s${DAM_RESET} %s\n" "sup"           "Start Sail"
  printf "  ${DAM_RED}%-16s${DAM_RESET} %s\n" "nrd"           "Start frontend dev server"
  printf "  ${DAM_RED}%-16s${DAM_RESET} %s\n" "pint"          "Format PHP code"
  printf "  ${DAM_RED}%-16s${DAM_RESET} %s\n" "pest"          "Run tests"
  printf "  ${DAM_RED}%-16s${DAM_RESET} %s\n" "rcheck"        "Preview Rector changes"
  printf "  ${DAM_RED}%-16s${DAM_RESET} %s\n" "stan"          "Static analysis"
  printf "  ${DAM_RED}%-16s${DAM_RESET} %s\n" "qa"            "Full quality pipeline"
  printf "  ${DAM_RED}%-16s${DAM_RESET} %s\n" "gs"            "Git status"
  printf "  ${DAM_RED}%-16s${DAM_RESET} %s\n" "gcam"          "Add all and commit with message"
  printf "  ${DAM_RED}%-16s${DAM_RESET} %s\n" "gp"            "Push branch"
  echo
  echo "${DAM_GRAY}You can edit later with:${DAM_RESET}"
  echo "  dam daily choose"
  echo "  dam daily add NAME"
  echo "  dam daily remove NAME"
  echo "  dam daily reset"
}

for arg in "$@"; do
  case "$arg" in
    --zsh|--bash|--both) MODE="$arg" ;;
    --no-wizard) RUN_WIZARD=0 ;;
    --no-clean) CLEAN=0 ;;
    --clean) CLEAN=1 ;;
    --no-reload-prompt) PROMPT_RELOAD=0 ;;
    -h|--help)
      cat <<'EOF'
Usage: ./install.sh [--zsh|--bash|--both] [--clean] [--no-wizard] [--no-reload-prompt]

Default behavior:
  - installs or updates DAM
  - keeps existing aliases, Daily Favorites, and config
  - opens wizard
  - shows recommended Daily Favorites preview
  - asks whether to install recommended Daily Favorites
  - asks whether to reload shell now

Options:
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
  cp "$CONFIG_DIR/dam.sh" "$CONFIG_DIR/dam.sh.backup.$(date +%F-%H%M%S)"
fi

cp "$ROOT_DIR/core/dam.sh" "$CONFIG_DIR/dam.sh"
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
echo

# shellcheck disable=SC1090
source "$CONFIG_DIR/dam.sh"

if [ "$RUN_WIZARD" = "1" ] && [ -t 0 ]; then
  dam wizard || true
else
  dam repair || true
fi

echo
dam_install_recommended_daily_preview

if [ -t 0 ]; then
  dam_install_recommended "⭐ Install recommended Daily Favorites now? [Y/n]" "Optional but useful. This MERGES defaults into your Daily list; custom favorites will NOT be deleted. Press Enter for Yes."
  if dam_prompt_yes_no "Choose [Y/n]:"; then
    dam daily install || true
  else
    dam_install_warn "Skipped recommended Daily Favorites."
    echo
    echo "${DAM_RED}${DAM_BOLD}Run later:${DAM_RESET}"
    echo "  dam daily install"
    echo "  dam daily recommended"
  fi
else
  dam daily table || true
fi

reload_shell_prompt() {
  [ "$PROMPT_RELOAD" = "1" ] || return 0

  dam_install_action "🔄 Reload shell now? [Y/n]" "Required for this current terminal. This makes dam, dam daily, and aliases work immediately. Press Enter for Yes."

  if [ -t 0 ]; then
    if dam_prompt_yes_no "Choose [Y/n]:"; then
      touch "$CONFIG_DIR/open-daily-after-reload"
      echo "${DAM_GREEN}Reloading shell...${DAM_RESET}"
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
