# Dev Alias Manager
# Laravel/PHP fullstack alias manager for Bash and Zsh.
# Installs aliases, help, daily favorites, and UI helpers only.

export DAM_HOME="${DAM_HOME:-${XDG_CONFIG_HOME:-$HOME/.config}/dev-alias-manager}"
export PATH="$HOME/.local/bin:$HOME/.config/composer/vendor/bin:$PATH"

mkdir -p "$DAM_HOME"
touch "$DAM_HOME/commands.sh" "$DAM_HOME/commands.db" "$DAM_HOME/daily.db" "$DAM_HOME/custom-aliases.sh"

if [ ! -f "$DAM_HOME/config.sh" ]; then
  cat > "$DAM_HOME/config.sh" <<'EOF_DAM_CONFIG'
# Dev Alias Manager config.
export DAM_SAIL_BIN="${DAM_SAIL_BIN:-./vendor/bin/sail}"
export DAM_ARTISAN_BIN="${DAM_ARTISAN_BIN:-artisan}"
export DAM_VENDOR_BIN="${DAM_VENDOR_BIN:-./vendor/bin}"
export DAM_AUTO_SAIL="${DAM_AUTO_SAIL:-1}"
EOF_DAM_CONFIG
fi

# shellcheck disable=SC1090
. "$DAM_HOME/config.sh"

_dam_c_reset=$'\033[0m'
_dam_c_red=$'\033[38;5;196m'
_dam_c_red2=$'\033[38;5;203m'
_dam_c_orange=$'\033[38;5;208m'
_dam_c_pink=$'\033[38;5;204m'
_dam_c_blue=$'\033[38;5;39m'
_dam_c_white=$'\033[38;5;255m'
_dam_c_gray=$'\033[38;5;250m'
_dam_c_muted=$'\033[38;5;245m'
_dam_c_dim=$'\033[38;5;238m'
_dam_c_green=$'\033[38;5;46m'
_dam_c_yellow=$'\033[38;5;220m'

_dam_color_off_if_needed() {
  [ -t 1 ] && return 0
  _dam_c_reset=""; _dam_c_red=""; _dam_c_red2=""; _dam_c_white=""
  _dam_c_gray=""; _dam_c_muted=""; _dam_c_dim=""; _dam_c_green=""; _dam_c_yellow=""
  _dam_c_orange=""; _dam_c_pink=""; _dam_c_blue=""
}
_dam_color_off_if_needed

_dam_ok() { printf "%sOK%s %s\n" "$_dam_c_green" "$_dam_c_reset" "$1"; }
_dam_warn() { printf "%sWARN%s %s\n" "$_dam_c_yellow" "$_dam_c_reset" "$1"; }
_dam_err() { printf "%sERR%s %s\n" "$_dam_c_red" "$_dam_c_reset" "$1"; }

_dam_panel() {
  printf "\n%s╭────────────────────────────────────────────────────────────╮%s\n" "$_dam_c_red" "$_dam_c_reset"
  printf "%s│%s %s%-58.58s%s %s│%s\n" "$_dam_c_red" "$_dam_c_reset" "$_dam_c_pink" "$1" "$_dam_c_reset" "$_dam_c_red" "$_dam_c_reset"
  if [ -n "${2:-}" ]; then
    printf "%s│%s %s%-58.58s%s %s│%s\n" "$_dam_c_red" "$_dam_c_reset" "$_dam_c_gray" "$2" "$_dam_c_reset" "$_dam_c_red" "$_dam_c_reset"
  fi
  printf "%s╰────────────────────────────────────────────────────────────╯%s\n" "$_dam_c_red" "$_dam_c_reset"
}

_dam_rule() {
  printf "%s%s%s\n" "$_dam_c_dim" "────────────────────────────────────────────────────────────────────────────────────────────" "$_dam_c_reset"
}

_dam_tty() {
  [ -t 0 ] && [ -t 1 ]
}

_dam_has_sail() {
  [ "${USE_SAIL:-auto}" != "0" ] && [ "${DAM_AUTO_SAIL:-1}" != "0" ] && [ -f "$DAM_SAIL_BIN" ]
}

_dam_sail_command() {
  local subcommand="$1"
  shift
  if [ -f "$DAM_SAIL_BIN" ]; then
    "$DAM_SAIL_BIN" "$subcommand" "$@"
  else
    _dam_missing "Sail not found. Install it with: php artisan sail:install, or edit DAM_SAIL_BIN with: dam config"
  fi
}

dam_mode() {
  if _dam_has_sail; then
    echo "sail"
  else
    echo "local"
  fi
}

mode() { dam_mode; }

_dam_missing() {
  echo "$1"
  return 1
}

_dam_split_command() {
  local command_text="$1"
  eval "set -- $command_text"
  printf '%s\n' "$@"
}

_dam_run_words() {
  local exe="$1"; shift
  if command -v "$exe" >/dev/null 2>&1; then
    "$exe" "$@"
  else
    _dam_missing "$exe not found. Install it first, then run this alias."
  fi
}

_dam_run() {
  local kind="$1"; shift
  local command_text="$1"; shift
  local -a passthrough
  passthrough=("$@")

  case "$kind" in
    artisan)
      if _dam_has_sail; then
        eval '"$DAM_SAIL_BIN" artisan '"$command_text"' "$@"'
      elif [ -f "$DAM_ARTISAN_BIN" ]; then
        eval 'php "$DAM_ARTISAN_BIN" '"$command_text"' "$@"'
      else
        _dam_missing "artisan not found. Run inside a Laravel project or edit paths with: dam config"
      fi
      ;;
    npm)
      if _dam_has_sail; then
        eval '"$DAM_SAIL_BIN" npm '"$command_text"' "$@"'
      elif command -v npm >/dev/null 2>&1; then
        eval 'npm '"$command_text"' "$@"'
      else
        _dam_missing "npm not found. Install Node/npm first."
      fi
      ;;
    composer)
      if _dam_has_sail; then
        eval '"$DAM_SAIL_BIN" composer '"$command_text"' "$@"'
      elif command -v composer >/dev/null 2>&1; then
        eval 'composer '"$command_text"' "$@"'
      else
        _dam_missing "composer not found. Install Composer first."
      fi
      ;;
    php)
      if _dam_has_sail; then
        eval '"$DAM_SAIL_BIN" php '"$command_text"' "$@"'
      elif command -v php >/dev/null 2>&1; then
        eval 'php '"$command_text"' "$@"'
      else
        _dam_missing "php not found. Install PHP first."
      fi
      ;;
    vendor)
      eval "set -- $command_text"
      local bin_name="$1"; shift
      local bin_path="$DAM_VENDOR_BIN/$bin_name"
      if [ ! -f "$bin_path" ]; then
        _dam_missing "$bin_name not found in $DAM_VENDOR_BIN. Install it in the project or edit paths with: dam config"
        return 1
      fi
      if _dam_has_sail; then
        "$DAM_SAIL_BIN" php "$bin_path" "$@" "${passthrough[@]}"
      else
        "$bin_path" "$@" "${passthrough[@]}"
      fi
      ;;
    system)
      eval "set -- $command_text"
      local exe="$1"; shift
      _dam_run_words "$exe" "$@" "${passthrough[@]}"
      ;;
    raw)
      eval "$command_text \"\$@\""
      ;;
    *)
      _dam_err "Unknown alias kind: $kind"
      echo "Allowed kinds: artisan, npm, composer, php, vendor, system, raw"
      return 1
      ;;
  esac
}

_dam_validate_name() {
  local name="$1"
  if ! printf '%s\n' "$name" | grep -Eq '^[A-Za-z_][A-Za-z0-9_]*$'; then
    _dam_err "Invalid alias name: $name"
    echo "Use letters, numbers, underscore. The name must not start with a number."
    return 1
  fi

  case "$name" in
    dam|help|alias|unalias|source|cd|exit|return|eval|exec|function)
      _dam_err "Reserved alias name: $name"
      return 1
      ;;
  esac
}

_dam_validate_field() {
  case "$1" in
    *$'\t'*|*$'\n'*|*$'\r'*)
      _dam_err "Values cannot contain tabs or newlines."
      return 1
      ;;
  esac
}

_dam_escape_double() {
  local value="$1"
  value="${value//\\/\\\\}"
  value="${value//\"/\\\"}"
  printf '%s' "$value"
}

_dam_db_row() {
  printf "%s\t%s\t%s\t%s\t%s\n" "$1" "$2" "$3" "$4" "$5"
}

_dam_db_find() {
  local name="$1"
  awk -F '\t' -v n="$name" 'NF >= 5 && $1 == n {print; exit}' "$DAM_HOME/commands.db" 2>/dev/null
}

_dam_parse_db_line() {
  local line="$1" tab=$'\t' rest
  _dam_db_name="${line%%$tab*}"
  [ "$line" != "$_dam_db_name" ] || return 1
  rest="${line#*$tab}"
  _dam_db_category="${rest%%$tab*}"
  [ "$rest" != "$_dam_db_category" ] || return 1
  rest="${rest#*$tab}"
  _dam_db_kind="${rest%%$tab*}"
  [ "$rest" != "$_dam_db_kind" ] || return 1
  rest="${rest#*$tab}"
  _dam_db_command="${rest%%$tab*}"
  [ "$rest" != "$_dam_db_command" ] || return 1
  _dam_db_description="${rest#*$tab}"
}

_dam_alias_exists() {
  [ -n "$(_dam_db_find "$1")" ] || command -v "$1" >/dev/null 2>&1
}

_dam_add_full() {
  [ "$#" -ge 5 ] || { _dam_help_add; return 1; }

  local name="$1" category="$2" kind="$3" command_text="$4" description="$5"
  _dam_validate_name "$name" || return 1
  _dam_validate_field "$category" && _dam_validate_field "$kind" && _dam_validate_field "$command_text" && _dam_validate_field "$description" || return 1

  case "$kind" in
    artisan|npm|composer|php|vendor|system|raw) ;;
    *) _dam_err "Unknown kind: $kind"; echo "Allowed: artisan, npm, composer, php, vendor, system, raw"; return 1 ;;
  esac

  local commands_file="$DAM_HOME/commands.sh"
  local db_file="$DAM_HOME/commands.db"
  local safe_command
  safe_command="$(_dam_escape_double "$command_text")"

  touch "$commands_file" "$db_file"
  perl -0pi -e "s/# command:${name}\nfunction ${name} \\{.*?\\n\\}\n//s" "$commands_file" 2>/dev/null || true
  awk -F '\t' -v n="$name" 'NF < 5 || $1 != n {print}' "$db_file" > "$db_file.tmp" 2>/dev/null || true
  mv "$db_file.tmp" "$db_file"

  cat >> "$commands_file" <<EOF_DAM_CMD
# command:${name}
function ${name} {
  _dam_run "${kind}" "${safe_command}" "\$@"
}
EOF_DAM_CMD

  _dam_db_row "$name" "$category" "$kind" "$command_text" "$description" >> "$db_file"
  # shellcheck disable=SC1090
  . "$commands_file"
  _dam_ok "Saved alias: $name"
}

_dam_add() {
  [ "$#" -ge 3 ] || { _dam_help_add; return 1; }
  _dam_add_full "$1" custom "$2" "$3" "${4:-Custom alias}"
}

_dam_add_to() {
  [ "$#" -ge 5 ] || { echo "Usage: dam add-to CATEGORY NAME KIND 'COMMAND' 'DESCRIPTION'"; return 1; }
  _dam_add_full "$2" "$1" "$3" "$4" "$5"
}

_dam_remove() {
  local name="${1:-}"
  [ -n "$name" ] || { echo "Usage: dam remove NAME"; return 1; }
  _dam_validate_name "$name" || return 1

  perl -0pi -e "s/# command:${name}\nfunction ${name} \\{.*?\\n\\}\n//s" "$DAM_HOME/commands.sh" 2>/dev/null || true
  awk -F '\t' -v n="$name" 'NF < 5 || $1 != n {print}' "$DAM_HOME/commands.db" > "$DAM_HOME/commands.db.tmp" 2>/dev/null || true
  mv "$DAM_HOME/commands.db.tmp" "$DAM_HOME/commands.db"
  grep -v "^${name}|" "$DAM_HOME/daily.db" > "$DAM_HOME/daily.db.tmp" 2>/dev/null || true
  mv "$DAM_HOME/daily.db.tmp" "$DAM_HOME/daily.db"
  unset -f "$name" 2>/dev/null || true
  _dam_ok "Removed alias: $name"
}

_dam_category_color() {
  case "$1" in
    laravel) printf '%s' "$_dam_c_red2" ;;
    sail) printf '%s' "$_dam_c_orange" ;;
    docker) printf '%s' "$_dam_c_blue" ;;
    frontend) printf '%s' "$_dam_c_green" ;;
    php) printf '%s' "$_dam_c_yellow" ;;
    quality|security) printf '%s' "$_dam_c_pink" ;;
    git|github) printf '%s' "$_dam_c_gray" ;;
    *) printf '%s' "$_dam_c_muted" ;;
  esac
}

_dam_table_header() {
  printf "%s%-18s %-12s %-9s %-30s %s%s\n" "$_dam_c_red2" "Alias" "Pack" "Kind" "Command" "Subtitle" "$_dam_c_reset"
  _dam_rule
}

_dam_table_row() {
  local name="$1" category="$2" kind="$3" command_text="$4" description="$5" c
  c="$(_dam_category_color "$category")"
  printf "%s%-18s%s %s%-12s%s %s%-9s%s %-30.30s %s\n" \
    "$_dam_c_white" "$name" "$_dam_c_reset" \
    "$c" "$category" "$_dam_c_reset" \
    "$_dam_c_orange" "$kind" "$_dam_c_reset" \
    "$command_text" "$description"
}

_dam_print_alias_rows() {
  local line last_category=""
  while IFS= read -r line; do
    _dam_parse_db_line "$line" || continue
    [ -n "$_dam_db_name" ] || continue
    if [ "$_dam_db_category" != "$last_category" ]; then
      printf "\n%s%s aliases%s\n" "$(_dam_category_color "$_dam_db_category")" "$_dam_db_category" "$_dam_c_reset"
      last_category="$_dam_db_category"
    fi
    _dam_table_row "$_dam_db_name" "$_dam_db_category" "$_dam_db_kind" "$_dam_db_command" "$_dam_db_description"
  done < "$DAM_HOME/commands.db"
}

_dam_list() {
  if [ ! -s "$DAM_HOME/commands.db" ]; then
    _dam_warn "No aliases installed yet."
    echo "Run: dam wizard"
    return 0
  fi
  _dam_panel "Installed Aliases" "Mode: $(dam_mode). Search: dam search WORD. Explain: dam help alias NAME."
  _dam_table_header
  _dam_print_alias_rows
}

_dam_category() {
  local category="${1:-}"
  [ -n "$category" ] || { echo "Usage: dam category CATEGORY"; return 1; }
  _dam_panel "$category Aliases" "Install/check aliases by pack with subtitles."
  _dam_table_header
  local line
  while IFS= read -r line; do
    _dam_parse_db_line "$line" || continue
    [ "$_dam_db_category" = "$category" ] || continue
    _dam_table_row "$_dam_db_name" "$_dam_db_category" "$_dam_db_kind" "$_dam_db_command" "$_dam_db_description"
  done < "$DAM_HOME/commands.db"
}

_dam_search() {
  local query="${1:-}"
  [ -n "$query" ] || { echo "Usage: dam search WORD"; return 1; }
  _dam_panel "Search: $query" "Matches aliases, categories, commands, and descriptions."
  _dam_table_header
  local line q found=0
  q="$(printf '%s' "$query" | tr '[:upper:]' '[:lower:]')"
  while IFS= read -r line; do
    _dam_parse_db_line "$line" || continue
    line="$(printf '%s' "$_dam_db_name $_dam_db_category $_dam_db_kind $_dam_db_command $_dam_db_description" | tr '[:upper:]' '[:lower:]')"
    case "$line" in
      *"$q"*) _dam_table_row "$_dam_db_name" "$_dam_db_category" "$_dam_db_kind" "$_dam_db_command" "$_dam_db_description"; found=1 ;;
    esac
  done < "$DAM_HOME/commands.db"
  [ "$found" = "1" ] || echo "No matches."
}

_dam_note_for_alias() {
  local name="$1" row
  row="$(_dam_db_find "$name")"
  if [ -n "$row" ]; then
    printf '%s\n' "$row" | awk -F '\t' '{print $5}'
  else
    echo "Daily command"
  fi
}

_dam_daily_contains() {
  grep -q "^${1}|" "$DAM_HOME/daily.db" 2>/dev/null
}

_dam_daily_add() {
  local name="${1:-}" note="${2:-}"
  [ -n "$name" ] || { echo "Usage: dam daily add NAME ['NOTE']"; return 1; }
  _dam_validate_name "$name" || return 1
  if ! _dam_alias_exists "$name"; then
    _dam_err "Alias not found: $name"
    echo "Search first: dam search $name"
    return 1
  fi
  [ -n "$note" ] || note="$(_dam_note_for_alias "$name")"
  grep -v "^${name}|" "$DAM_HOME/daily.db" > "$DAM_HOME/daily.db.tmp" 2>/dev/null || true
  mv "$DAM_HOME/daily.db.tmp" "$DAM_HOME/daily.db"
  printf "%s|%s\n" "$name" "$note" >> "$DAM_HOME/daily.db"
  _dam_ok "Added to Daily: $name"
}

_dam_daily_remove() {
  local name="${1:-}"
  [ -n "$name" ] || { echo "Usage: dam daily remove NAME"; return 1; }
  grep -v "^${name}|" "$DAM_HOME/daily.db" > "$DAM_HOME/daily.db.tmp" 2>/dev/null || true
  mv "$DAM_HOME/daily.db.tmp" "$DAM_HOME/daily.db"
  _dam_ok "Removed from Daily: $name"
}

_dam_daily_show() {
  _dam_panel "Daily Favorites" "Your short list for commands you use or forget often."
  if [ ! -s "$DAM_HOME/daily.db" ]; then
    echo "No Daily Favorites yet."
    echo "Add one:     dam daily add ALIAS"
    echo "Search:      dam daily search WORD"
    echo "Checkbox UI: dam daily choose"
    return 0
  fi
  local n=1
  while IFS='|' read -r name note; do
    printf "%s%2s%s  %s%-18s%s %s\n" "$_dam_c_orange" "$n" "$_dam_c_reset" "$_dam_c_red2" "$name" "$_dam_c_reset" "$note"
    n=$((n + 1))
  done < "$DAM_HOME/daily.db"
}

_dam_daily_run() {
  [ -s "$DAM_HOME/daily.db" ] || { _dam_warn "Daily is empty. Run: dam daily choose"; return 1; }
  local name note
  while IFS='|' read -r name note; do
    _dam_panel "Running: $name" "$note"
    command -v "$name" >/dev/null 2>&1 || { _dam_err "$name not found"; return 1; }
    "$name" || return 1
  done < "$DAM_HOME/daily.db"
}

_dam_daily_choose_text() {
  _dam_list
  echo
  echo "Type aliases to add to Daily, separated by spaces. Leave empty to exit."
  printf "Aliases: "
  local line name
  read -r line
  for name in $line; do
    _dam_daily_add "$name"
  done
}

_dam_daily_choose_dialog() {
  local backend="$1"
  local -a opts
  local line selected

  while IFS= read -r line; do
    _dam_parse_db_line "$line" || continue
    [ -n "$_dam_db_name" ] || continue
    if _dam_daily_contains "$_dam_db_name"; then
      opts+=("$_dam_db_name" "$_dam_db_category - $_dam_db_description" "on")
    else
      opts+=("$_dam_db_name" "$_dam_db_category - $_dam_db_description" "off")
    fi
  done < "$DAM_HOME/commands.db"

  [ "${#opts[@]}" -gt 0 ] || { _dam_warn "No aliases installed. Run: dam wizard"; return 1; }

  if [ "$backend" = "dialog" ]; then
    selected=$(dialog --stdout --title "Laravel Alias Manager" --checklist "Choose Daily Favorites from installed aliases" 24 100 16 "${opts[@]}") || return 0
  else
    selected=$(whiptail --title "Laravel Alias Manager" --checklist "Choose Daily Favorites from installed aliases" 24 100 16 "${opts[@]}" 3>&1 1>&2 2>&3) || return 0
  fi

  selected="${selected//\"/}"
  : > "$DAM_HOME/daily.db"
  for name in $selected; do
    _dam_daily_add "$name" >/dev/null || true
  done
  _dam_daily_show
}

_dam_ui_backend() {
  if command -v dialog >/dev/null 2>&1; then
    echo dialog
  elif command -v whiptail >/dev/null 2>&1; then
    echo whiptail
  else
    echo text
  fi
}

_dam_daily_choose() {
  case "$(_dam_ui_backend)" in
    dialog) _dam_daily_choose_dialog dialog ;;
    whiptail) _dam_daily_choose_dialog whiptail ;;
    *) _dam_daily_choose_text ;;
  esac
}

_dam_daily_menu() {
  while true; do
    _dam_daily_show
    echo
    printf "%s1%s choose   %s2%s add one   %s3%s search   %s4%s run   %s5%s clear   %s0%s exit\n" \
      "$_dam_c_red2" "$_dam_c_reset" "$_dam_c_orange" "$_dam_c_reset" "$_dam_c_blue" "$_dam_c_reset" "$_dam_c_green" "$_dam_c_reset" "$_dam_c_yellow" "$_dam_c_reset" "$_dam_c_muted" "$_dam_c_reset"
    printf "Choose: "
    local choice query name
    read -r choice
    case "$choice" in
      ""|0|q|quit|exit) break ;;
      1|choose) _dam_daily_choose ;;
      2|add) printf "Alias: "; read -r name; _dam_daily_add "$name" ;;
      3|search) printf "Search: "; read -r query; _dam_search "$query"; echo; printf "Add alias from results (empty to skip): "; read -r name; [ -n "$name" ] && _dam_daily_add "$name" ;;
      4|run) _dam_daily_run ;;
      5|clear) : > "$DAM_HOME/daily.db"; _dam_ok "Daily cleared." ;;
      *) echo "Unknown choice." ;;
    esac
    echo
    printf "Press Enter to continue..."
    read -r _
  done
}

_dam_daily() {
  local action="${1:-show}"
  shift 2>/dev/null || true
  case "$action" in
    show|list|"") if _dam_tty; then _dam_daily_menu; else _dam_daily_show; fi ;;
    table|compact|print) _dam_daily_show ;;
    choose|select|1) _dam_daily_choose ;;
    add) _dam_daily_add "$@" ;;
    remove|rm|delete) _dam_daily_remove "$@" ;;
    run|4) _dam_daily_run ;;
    search|find|3) _dam_search "$@" ;;
    clear) : > "$DAM_HOME/daily.db"; _dam_ok "Daily cleared." ;;
    edit) "${EDITOR:-nano}" "$DAM_HOME/daily.db" ;;
    help) _dam_help_daily ;;
    *) echo "Usage: dam daily [choose|add|remove|run|search|clear|edit]" ;;
  esac
}

_dam_help_table() {
  local title="$1" subtitle="$2"
  shift 2
  _dam_panel "$title" "$subtitle"
  local row cmd desc
  for row in "$@"; do
    cmd="${row%%|*}"
    desc="${row#*|}"
    printf "%s%-28s%s %s\n" "$_dam_c_red2" "$cmd" "$_dam_c_reset" "$desc"
  done
}

_dam_help_add() {
  _dam_help_table "Add / Change Aliases" "Create, replace, search, and remove aliases." \
    "dam add NAME kind 'cmd' 'desc'|add custom alias" \
    "dam add-to laravel NAME artisan 'cmd' 'desc'|add alias to category" \
    "dam change quality pest vendor 'pest' 'Run Pest'|replace alias" \
    "dam remove NAME|delete alias" \
    "dam search WORD|search aliases"
}

_dam_help_daily() {
  _dam_help_table "Daily Favorites" "A small personal list for commands you use most." \
    "dam daily|open Daily menu" \
    "dam daily choose|checkbox chooser from installed aliases" \
    "dam daily add NAME|add one alias" \
    "dam daily search WORD|search aliases before adding" \
    "dam daily remove NAME|remove one alias" \
    "dam daily run|run all Daily commands in order"
}

_dam_help_alias() {
  local name="${1:-}" row
  [ -n "$name" ] || { echo "Usage: dam help alias NAME"; return 1; }
  row="$(_dam_db_find "$name")"
  [ -n "$row" ] || { _dam_err "Alias not found: $name"; return 1; }
  printf '%s\n' "$row" | awk -F '\t' '{printf "Alias: %s\nCategory: %s\nKind: %s\nCommand: %s\nDescription: %s\nUsage: %s [args]\n", $1, $2, $3, $4, $5, $1}'
}

_dam_help() {
  local topic="${1:-home}"
  shift 2>/dev/null || true
  case "$topic" in
    home|help|"")
      _dam_help_table "Dev Alias Manager" "Laravel/PHP fullstack aliases with search, Daily Favorites, and checkbox UI." \
        "dam wizard|install alias packs with checkboxes" \
        "dam list|show installed aliases" \
        "dam search route|find aliases by word" \
        "dam daily|open Daily Favorites" \
        "dam help alias myroutes|explain one alias" \
        "dam check|check local project tools" \
        "dam help topics|show help topics"
      ;;
    topics)
      _dam_help_table "Help Topics" "Use: dam help TOPIC" \
        "quick|first steps" "daily|Daily Favorites" "add|custom aliases" \
        "laravel|Laravel aliases" "sail|Laravel Sail aliases" "quality|Pest/Pint/Rector/PHPStan" \
        "frontend|npm/Vite aliases" "docker|Docker aliases" "git|Git aliases" \
        "github|GitHub CLI aliases" "php|PHP and Composer aliases" "linux|Linux helpers" \
        "security|security checks" "workflow|project workflow aliases" "config|paths"
      ;;
    search|find) _dam_search "$@" ;;
    aliases|list) _dam_list ;;
    quick)
      _dam_help_table "Quick Start" "Good first commands after install." \
        "dam wizard|install fullstack alias packs" "dam daily choose|pick your Daily Favorites" \
        "dam search route|find route aliases" "projectdoctor|inspect project" "sup|start Sail" \
        "nrd|start Vite dev server" "qa|run quality pipeline"
      ;;
    daily) _dam_help_daily ;;
    add|custom|change) _dam_help_add ;;
    alias) _dam_help_alias "${1:-}" ;;
    laravel)
      _dam_help_table "Laravel" "Artisan, routes, DB, queues, logs, and generators." \
        "art <cmd>|run any artisan command" "myroutes|route:list" "dbmigrate|migrate" \
        "dbfresh|migrate:fresh --seed" "qwork|queue:work" "logs|tail Laravel log" \
        "mkc UserController|make controller" "mkm User|make model" "mkmig create_posts_table|make migration"
      ;;
    sail)
      _dam_help_table "Laravel Sail" "Sail lifecycle and container helpers." \
        "sup|sail up -d" "supb|sail up -d --build" "sdown|sail down" "sps|sail ps" \
        "slog|sail logs -f" "sshapp|sail shell" "snrd|sail npm run dev"
      ;;
    quality|qa)
      _dam_help_table "Quality" "Common project checks." \
        "pint|format PHP" "pinttest|check formatting" "pest|run tests" "rcheck|Rector dry-run" \
        "rfix|Rector apply" "stan|PHPStan analyse" "qa|full quality pipeline"
      ;;
    frontend|npm|vite)
      _dam_help_table "Frontend" "npm/Vite workflow." \
        "ni|npm install" "nrd|npm run dev" "nrb|npm run build" "nrt|npm run typecheck" \
        "nrl|npm run lint" "npreview|npm run preview"
      ;;
    docker)
      _dam_help_table "Docker" "Docker Compose helpers." \
        "dc|docker compose" "dcu|docker compose up -d" "dcub|up with build" \
        "dcd|down" "dcl|logs -f" "dps|docker ps" "dprune|system prune -af"
      ;;
    git)
      _dam_help_table "Git" "Daily Git aliases." \
        "gs|git status -sb" "ga FILE|git add" "gaa|git add -A" "gcm 'msg'|commit" \
        "gcam 'msg'|add all and commit" "gp|push" "gpf|force-with-lease"
      ;;
    github|gh)
      _dam_help_table "GitHub CLI" "Pull request and GitHub Actions helpers." \
        "ghpr|create pull request" "ghprv|open current pull request" \
        "ghprs|show pull request status" "ghruns|list workflow runs" "ghwatch|watch a workflow run"
      ;;
    php|composer)
      _dam_help_table "PHP / Composer" "PHP and Composer helpers." \
        "phpv|show PHP version" "ci|composer install" "cu|composer update" \
        "creq vendor/package|composer require" "creqd vendor/package|composer require --dev" \
        "cda|composer dump-autoload" "cval|composer validate --strict" "caudit|composer audit"
      ;;
    linux|ubuntu)
      _dam_help_table "Linux" "Small terminal and system helpers." \
        "cls|clear terminal" "update|apt update and upgrade" "cleanup|apt autoremove and autoclean" \
        "ports|show listening ports" "disk|show disk usage" "mem|show memory usage"
      ;;
    security|audit)
      _dam_help_table "Security" "Checks for Laravel project safety." \
        "secenv|check .env and git tracking" "seckey|show generated Laravel app key" \
        "secaudit|composer audit" "secnpm|npm audit" "secperms|check writable Laravel directories"
      ;;
    workflow|project)
      _dam_help_table "Workflow" "Project start, stop, and check helpers." \
        "doctor|run projectdoctor" "start|start Sail, npm dev, or artisan serve" \
        "stop|stop Sail project" "devflow|projectdoctor then frontend dev" "checkall|run qa"
      ;;
    config)
      _dam_help_table "Config" "Path config lives in $DAM_HOME/config.sh" \
        "dam config|edit config" "DAM_SAIL_BIN|default ./vendor/bin/sail" \
        "DAM_ARTISAN_BIN|default artisan" "DAM_VENDOR_BIN|default ./vendor/bin" \
        "DAM_AUTO_SAIL=0|disable Sail auto mode"
      ;;
    *) _dam_help_alias "$topic" 2>/dev/null || { echo "Unknown help topic: $topic"; echo "Try: dam help topics"; } ;;
  esac
}

_dam_packs() {
  _dam_help_table "Alias Packs" "Install with: dam preset PACK or dam wizard" \
    "linux|terminal and Ubuntu helpers" "git|Git aliases" "github|GitHub CLI aliases" \
    "docker|Docker Compose aliases" "php|PHP and Composer aliases" "frontend|npm/Vite aliases" \
    "laravel|Artisan/Laravel workflow" "sail|Laravel Sail aliases" "quality|Pest/Pint/Rector/PHPStan" \
    "security|audit and env checks" "workflow|project start/check aliases" "fullstack|all-in-one Laravel/PHP pack"
}

_dam_preset_linux() {
  _dam_add_full cls linux system 'clear' 'Clear terminal'
  _dam_add_full update linux raw 'sudo apt update && sudo apt upgrade -y' 'Update Ubuntu packages'
  _dam_add_full cleanup linux raw 'sudo apt autoremove -y && sudo apt autoclean' 'Clean apt packages'
  _dam_add_full ports linux raw 'lsof -i -P -n | grep LISTEN' 'Show listening ports'
  _dam_add_full disk linux system 'df -h' 'Show disk usage'
  _dam_add_full mem linux system 'free -h' 'Show memory usage'
}

_dam_preset_git() {
  _dam_add_full gs git system 'git status -sb' 'Git status'
  _dam_add_full ga git system 'git add' 'Git add files'
  _dam_add_full gaa git system 'git add -A' 'Git add all'
  _dam_add_full gcm git system 'git commit -m' 'Commit with message'
  _dam_add_full gcam git raw 'git add -A && git commit -m' 'Add all and commit with message'
  _dam_add_full gp git system 'git push' 'Push branch'
  _dam_add_full gpf git system 'git push --force-with-lease' 'Force push safely'
  _dam_add_full glog git system 'git log --oneline --graph --decorate --all' 'Graph log'
}

_dam_preset_github() {
  _dam_add_full ghpr github system 'gh pr create' 'Create pull request'
  _dam_add_full ghprv github system 'gh pr view --web' 'Open current PR'
  _dam_add_full ghprs github system 'gh pr status' 'PR status'
  _dam_add_full ghruns github system 'gh run list' 'List GitHub Actions runs'
  _dam_add_full ghwatch github system 'gh run watch' 'Watch GitHub Actions run'
}

_dam_preset_docker() {
  _dam_add_full dc docker system 'docker compose' 'Docker Compose'
  _dam_add_full dcu docker system 'docker compose up -d' 'Compose up detached'
  _dam_add_full dcub docker system 'docker compose up -d --build' 'Compose up with build'
  _dam_add_full dcd docker system 'docker compose down' 'Compose down'
  _dam_add_full dcl docker system 'docker compose logs -f' 'Compose logs'
  _dam_add_full dcr docker system 'docker compose restart' 'Restart services'
  _dam_add_full dps docker system 'docker ps' 'Running containers'
  _dam_add_full dpa docker system 'docker ps -a' 'All containers'
  _dam_add_full dprune docker system 'docker system prune -af' 'Clean Docker system'
}

_dam_preset_php() {
  _dam_add_full phpv php php '-v' 'PHP version'
  _dam_add_full phpi php php '-i' 'PHP info'
  _dam_add_full phpm php php '-m' 'Loaded PHP modules'
  _dam_add_full ci php composer 'install' 'Composer install'
  _dam_add_full cu php composer 'update' 'Composer update'
  _dam_add_full creq php composer 'require' 'Composer require'
  _dam_add_full creqd php composer 'require --dev' 'Composer require dev'
  _dam_add_full cda php composer 'dump-autoload' 'Dump autoload'
  _dam_add_full cval php composer 'validate --strict' 'Validate composer.json'
  _dam_add_full caudit php composer 'audit' 'Composer audit'
  _dam_add_full coutdated php composer 'outdated --direct' 'Show direct outdated packages'
  _dam_add_full cwhy php composer 'why' 'Explain why package is installed'
  _dam_add_full cwhy_not php composer 'why-not' 'Explain package constraint conflict'
}

_dam_preset_frontend() {
  _dam_add_full ni frontend npm 'install' 'Install npm dependencies'
  _dam_add_full nrd frontend npm 'run dev' 'Start frontend dev server'
  _dam_add_full vite frontend npm 'run dev' 'Start Vite dev server'
  _dam_add_full nrb frontend npm 'run build' 'Build frontend assets'
  _dam_add_full nrt frontend npm 'run typecheck' 'Run typecheck'
  _dam_add_full nrl frontend npm 'run lint' 'Run lint'
  _dam_add_full nrf frontend npm 'run format' 'Run formatter'
  _dam_add_full npreview frontend npm 'run preview' 'Preview production build'
}

_dam_preset_laravel() {
  _dam_add_full art laravel artisan '' 'Run any artisan command'
  _dam_add_full projectdoctor laravel raw 'echo "Mode: $(dam_mode)"; echo "PWD: $(pwd)"; command -v php >/dev/null && php -v | head -1 || echo "php not found"; command -v composer >/dev/null && composer --version || echo "composer not found"; command -v node >/dev/null && node -v || true; command -v npm >/dev/null && npm -v || true; [ -f "$DAM_ARTISAN_BIN" ] && _dam_run artisan "about" || echo "artisan not found"' 'Inspect current Laravel/PHP project'
  _dam_add_full serve laravel artisan 'serve' 'Start Laravel local server'
  _dam_add_full myroutes laravel artisan 'route:list' 'Show Laravel routes'
  _dam_add_full routes laravel artisan 'route:list' 'Show Laravel routes'
  _dam_add_full about laravel artisan 'about' 'Show Laravel app info'
  _dam_add_full tinker laravel artisan 'tinker' 'Open Tinker'
  _dam_add_full clearcache laravel artisan 'optimize:clear' 'Clear Laravel caches'
  _dam_add_full optimize laravel artisan 'optimize' 'Cache framework bootstrap'
  _dam_add_full configcache laravel artisan 'config:cache' 'Cache config'
  _dam_add_full routecache laravel artisan 'route:cache' 'Cache routes'
  _dam_add_full viewclear laravel artisan 'view:clear' 'Clear compiled views'
  _dam_add_full storage laravel artisan 'storage:link' 'Create storage symlink'
  _dam_add_full sailinstall laravel artisan 'sail:install' 'Install Laravel Sail'
  _dam_add_full dbmigrate laravel artisan 'migrate' 'Run migrations'
  _dam_add_full dbfresh laravel artisan 'migrate:fresh --seed' 'Fresh DB with seed'
  _dam_add_full dbseed laravel artisan 'db:seed' 'Run seeders'
  _dam_add_full dbrollback laravel artisan 'migrate:rollback' 'Rollback migrations'
  _dam_add_full dbstatus laravel artisan 'migrate:status' 'Migration status'
  _dam_add_full qwork laravel artisan 'queue:work' 'Run queue worker'
  _dam_add_full qlisten laravel artisan 'queue:listen' 'Listen for jobs'
  _dam_add_full qrestart laravel artisan 'queue:restart' 'Restart queue workers'
  _dam_add_full qfailed laravel artisan 'queue:failed' 'List failed jobs'
  _dam_add_full qretry laravel artisan 'queue:retry all' 'Retry failed jobs'
  _dam_add_full logs laravel raw 'tail -f storage/logs/laravel.log' 'Follow Laravel log'
  _dam_add_full logclear laravel raw ': > storage/logs/laravel.log && echo "Laravel log cleared."' 'Clear Laravel log'
  _dam_add_full mkc laravel artisan 'make:controller' 'Make controller'
  _dam_add_full mkci laravel artisan 'make:controller --invokable' 'Make invokable controller'
  _dam_add_full mkcr laravel artisan 'make:controller --resource' 'Make resource controller'
  _dam_add_full mkm laravel artisan 'make:model' 'Make model'
  _dam_add_full mkmig laravel artisan 'make:migration' 'Make migration'
  _dam_add_full mkf laravel artisan 'make:factory' 'Make factory'
  _dam_add_full mks laravel artisan 'make:seeder' 'Make seeder'
  _dam_add_full mkreq laravel artisan 'make:request' 'Make form request'
  _dam_add_full mkres laravel artisan 'make:resource' 'Make API resource'
  _dam_add_full mktest laravel artisan 'make:test' 'Make feature test'
  _dam_add_full mktestu laravel artisan 'make:test --unit' 'Make unit test'
  _dam_add_full mkmid laravel artisan 'make:middleware' 'Make middleware'
  _dam_add_full mkjob laravel artisan 'make:job' 'Make queued job'
  _dam_add_full mkevent laravel artisan 'make:event' 'Make event'
  _dam_add_full mklistener laravel artisan 'make:listener' 'Make listener'
  _dam_add_full mkmail laravel artisan 'make:mail' 'Make mailable'
  _dam_add_full mkpolicy laravel artisan 'make:policy' 'Make policy'
  _dam_add_full mkcommand laravel artisan 'make:command' 'Make Artisan command'
}

_dam_preset_sail() {
  _dam_add_full sup sail raw '[ -f "$DAM_SAIL_BIN" ] && "$DAM_SAIL_BIN" up -d || echo "Sail not found. Edit DAM_SAIL_BIN with: dam config"' 'Start Sail detached'
  _dam_add_full devup sail raw '[ -f "$DAM_SAIL_BIN" ] && "$DAM_SAIL_BIN" up -d || echo "Sail not found. Edit DAM_SAIL_BIN with: dam config"' 'Start Sail'
  _dam_add_full supb sail raw '[ -f "$DAM_SAIL_BIN" ] && "$DAM_SAIL_BIN" up -d --build || echo "Sail not found. Edit DAM_SAIL_BIN with: dam config"' 'Start Sail with build'
  _dam_add_full sdown sail raw '[ -f "$DAM_SAIL_BIN" ] && "$DAM_SAIL_BIN" down || echo "Sail not found. Edit DAM_SAIL_BIN with: dam config"' 'Stop Sail'
  _dam_add_full sstop sail raw '[ -f "$DAM_SAIL_BIN" ] && "$DAM_SAIL_BIN" stop || echo "Sail not found. Edit DAM_SAIL_BIN with: dam config"' 'Stop Sail services'
  _dam_add_full srestart sail raw '[ -f "$DAM_SAIL_BIN" ] && "$DAM_SAIL_BIN" down && "$DAM_SAIL_BIN" up -d || echo "Sail not found. Edit DAM_SAIL_BIN with: dam config"' 'Restart Sail'
  _dam_add_full sps sail raw '[ -f "$DAM_SAIL_BIN" ] && "$DAM_SAIL_BIN" ps || echo "Sail not found. Edit DAM_SAIL_BIN with: dam config"' 'Sail ps'
  _dam_add_full slog sail raw '[ -f "$DAM_SAIL_BIN" ] && "$DAM_SAIL_BIN" logs -f || echo "Sail not found. Edit DAM_SAIL_BIN with: dam config"' 'Sail logs'
  _dam_add_full sshapp sail raw '[ -f "$DAM_SAIL_BIN" ] && "$DAM_SAIL_BIN" shell || echo "Sail not found. Edit DAM_SAIL_BIN with: dam config"' 'Open Sail shell'
  _dam_add_full sroot sail raw '[ -f "$DAM_SAIL_BIN" ] && "$DAM_SAIL_BIN" root-shell || echo "Sail not found. Edit DAM_SAIL_BIN with: dam config"' 'Open Sail root shell'
  _dam_add_full sart sail raw '_dam_sail_command artisan' 'Run Artisan through Sail'
  _dam_add_full sphp sail raw '_dam_sail_command php' 'Run PHP through Sail'
  _dam_add_full scomposer sail raw '_dam_sail_command composer' 'Run Composer through Sail'
  _dam_add_full snrd sail raw '[ -f "$DAM_SAIL_BIN" ] && "$DAM_SAIL_BIN" npm run dev || echo "Sail not found. Edit DAM_SAIL_BIN with: dam config"' 'Run npm dev through Sail'
  _dam_add_full snrb sail raw '[ -f "$DAM_SAIL_BIN" ] && "$DAM_SAIL_BIN" npm run build || echo "Sail not found. Edit DAM_SAIL_BIN with: dam config"' 'Run npm build through Sail'
  _dam_add_full stest sail raw '[ -f "$DAM_SAIL_BIN" ] && "$DAM_SAIL_BIN" test || echo "Sail not found. Edit DAM_SAIL_BIN with: dam config"' 'Run tests through Sail'
}

_dam_preset_quality() {
  _dam_add_full pint quality vendor 'pint' 'Format PHP code'
  _dam_add_full pinttest quality vendor 'pint --test' 'Check PHP formatting'
  _dam_add_full pest quality vendor 'pest' 'Run tests'
  _dam_add_full pestf quality vendor 'pest --filter' 'Run Pest with filter'
  _dam_add_full pestcov quality vendor 'pest --coverage' 'Run coverage'
  _dam_add_full rcheck quality vendor 'rector process --dry-run' 'Preview Rector changes'
  _dam_add_full rfix quality vendor 'rector process' 'Apply Rector changes'
  _dam_add_full stan quality vendor 'phpstan analyse' 'Static analysis'
  _dam_add_full stanmax quality vendor 'phpstan analyse --memory-limit=1G' 'Static analysis with more memory'
  _dam_add_full qa quality raw 'pint && rcheck && stan && pest && { [ -f package.json ] && npm run typecheck --if-present && npm run build --if-present || true; }' 'Full quality pipeline'
}

_dam_preset_security() {
  _dam_add_full secenv security raw '[ -f .env ] && echo ".env exists" || echo ".env missing"; git ls-files --error-unmatch .env >/dev/null 2>&1 && echo "WARNING: .env is tracked by git" || echo ".env is not tracked by git"' 'Check .env safety'
  _dam_add_full seckey security artisan 'key:generate --show' 'Show generated app key'
  _dam_add_full secaudit security composer 'audit' 'Composer audit'
  _dam_add_full secnpm security npm 'audit' 'npm audit'
  _dam_add_full secperms security raw 'ls -ld storage bootstrap/cache 2>/dev/null || echo "storage/bootstrap cache paths not found"' 'Check writable paths'
}

_dam_preset_workflow() {
  _dam_add_full doctor workflow raw 'projectdoctor' 'Run project doctor'
  _dam_add_full start workflow raw 'if [ -f "$DAM_SAIL_BIN" ]; then "$DAM_SAIL_BIN" up -d; elif [ -f package.json ]; then npm run dev; elif [ -f "$DAM_ARTISAN_BIN" ]; then php "$DAM_ARTISAN_BIN" serve; else echo "No known start command found."; fi' 'Start project'
  _dam_add_full stop workflow raw 'if [ -f "$DAM_SAIL_BIN" ]; then "$DAM_SAIL_BIN" down; else echo "No Sail stop command found."; fi' 'Stop project'
  _dam_add_full devflow workflow raw 'projectdoctor && { [ -f package.json ] && npm run dev || true; }' 'Doctor then npm dev'
  _dam_add_full checkall workflow raw 'qa' 'Run quality pipeline'
}

_dam_preset_fullstack() {
  _dam_preset_linux
  _dam_preset_git
  _dam_preset_docker
  _dam_preset_php
  _dam_preset_frontend
  _dam_preset_laravel
  _dam_preset_sail
  _dam_preset_quality
  _dam_preset_security
  _dam_preset_workflow
}

_dam_preset() {
  case "${1:-}" in
    linux|ubuntu|system) _dam_preset_linux ;;
    git) _dam_preset_git ;;
    github|gh) _dam_preset_github ;;
    docker) _dam_preset_docker ;;
    php|composer) _dam_preset_php ;;
    frontend|npm|vite) _dam_preset_frontend ;;
    laravel) _dam_preset_laravel ;;
    sail) _dam_preset_sail ;;
    quality|qa) _dam_preset_quality ;;
    security|audit) _dam_preset_security ;;
    workflow|project) _dam_preset_workflow ;;
    fullstack|all|"") _dam_preset_fullstack ;;
    *) _dam_err "Unknown pack: ${1:-}"; _dam_packs; return 1 ;;
  esac
}

_dam_repair_quiet() {
  _dam_preset_fullstack >/dev/null
}

_dam_repair() {
  _dam_panel "Repair / Install Fullstack Pack" "Reinstalling Laravel/PHP fullstack aliases."
  _dam_preset_fullstack
  _dam_ok "Fullstack aliases are ready."
}

_dam_check() {
  _dam_panel "Environment Check" "Checks only. DAM does not install external developer tools."
  command -v git >/dev/null 2>&1 && _dam_ok "git: $(git --version)" || _dam_warn "git not found"
  command -v gh >/dev/null 2>&1 && _dam_ok "gh: $(gh --version | head -1)" || _dam_warn "GitHub CLI gh not found"
  command -v docker >/dev/null 2>&1 && _dam_ok "docker: $(docker --version)" || _dam_warn "docker not found"
  command -v php >/dev/null 2>&1 && _dam_ok "php: $(php -v | head -1)" || _dam_warn "php not found"
  command -v composer >/dev/null 2>&1 && _dam_ok "composer: $(composer --version)" || _dam_warn "composer not found"
  command -v node >/dev/null 2>&1 && _dam_ok "node: $(node -v)" || _dam_warn "node not found"
  command -v npm >/dev/null 2>&1 && _dam_ok "npm: $(npm -v)" || _dam_warn "npm not found"
  [ -f "$DAM_ARTISAN_BIN" ] && _dam_ok "artisan: $DAM_ARTISAN_BIN" || _dam_warn "artisan not found in current directory"
  [ -f "$DAM_SAIL_BIN" ] && _dam_ok "Sail: $DAM_SAIL_BIN" || _dam_warn "Sail not found: $DAM_SAIL_BIN"
}

_dam_wizard_text() {
  _dam_panel "Dev Alias Manager Setup" "No dialog/whiptail found. Install dialog for checkbox UI: sudo apt install dialog"
  echo "1) Laravel/PHP fullstack pack"
  echo "2) Laravel + Sail + Frontend + Quality"
  echo "3) Git + Docker + PHP"
  echo "0) Exit"
  printf "Choose: "
  local choice
  read -r choice
  case "$choice" in
    1|"") _dam_preset_fullstack ;;
    2) _dam_preset_laravel; _dam_preset_sail; _dam_preset_frontend; _dam_preset_quality ;;
    3) _dam_preset_git; _dam_preset_docker; _dam_preset_php ;;
    0|q|quit|exit) return 0 ;;
  esac
}

_dam_wizard_checklist() {
  local backend="$1" selected
  local -a opts
  opts=(
    linux "Linux / Ubuntu helpers" on
    git "Git aliases" on
    github "GitHub CLI aliases" off
    docker "Docker Compose aliases" on
    php "PHP / Composer aliases" on
    frontend "npm / Vite aliases" on
    laravel "Laravel Artisan aliases" on
    sail "Laravel Sail aliases" on
    quality "Pest / Pint / Rector / PHPStan" on
    security "Security and audit checks" on
    workflow "Project workflow aliases" on
  )

  if [ "$backend" = "dialog" ]; then
    selected=$(dialog --stdout --title "Laravel Alias Manager" --checklist "Choose alias packs to install. Only aliases/help are installed." 24 100 14 "${opts[@]}") || return 0
  else
    selected=$(whiptail --title "Laravel Alias Manager" --checklist "Choose alias packs to install. Only aliases/help are installed." 24 100 14 "${opts[@]}" 3>&1 1>&2 2>&3) || return 0
  fi

  selected="${selected//\"/}"
  local pack
  for pack in $selected; do
    _dam_preset "$pack"
  done
  _dam_ok "Selected alias packs installed."
  echo "Next: dam daily choose"
}

dam_wizard() {
  case "$(_dam_ui_backend)" in
    dialog) _dam_wizard_checklist dialog ;;
    whiptail) _dam_wizard_checklist whiptail ;;
    *) _dam_wizard_text ;;
  esac
}

_dam_add_interactive() {
  _dam_panel "Add / Change Alias" "Create or replace one alias."
  local category name kind command_text description add_daily
  printf "Category [custom]: "; read -r category; category="${category:-custom}"
  printf "Alias name: "; read -r name
  printf "Kind [artisan/npm/composer/php/vendor/system/raw]: "; read -r kind
  printf "Command: "; read -r command_text
  printf "Description: "; read -r description
  _dam_add_full "$name" "$category" "$kind" "$command_text" "$description" || return 1
  printf "Add to Daily? [y/N]: "; read -r add_daily
  case "$add_daily" in y|Y|yes|YES) _dam_daily_add "$name" "$description" ;; esac
}

dam() {
  local action="${1:-help}"
  shift 2>/dev/null || true
  case "$action" in
    wizard|setup|menu) dam_wizard ;;
    repair|install-fullstack) _dam_repair ;;
    preset|pack) _dam_preset "$@" ;;
    packs|presets) _dam_packs ;;
    list|ls|aliases) _dam_list ;;
    category|cat) _dam_category "$@" ;;
    search|find) _dam_search "$@" ;;
    add|install) _dam_add "$@" ;;
    add-to|addto|change|set) _dam_add_to "$@" ;;
    new) _dam_add_interactive ;;
    remove|rm|delete) _dam_remove "$@" ;;
    daily) _dam_daily "$@" ;;
    check|doctor) _dam_check ;;
    help|h) _dam_help "$@" ;;
    config) "${EDITOR:-nano}" "$DAM_HOME/config.sh" ;;
    edit) "${EDITOR:-nano}" "$DAM_HOME/commands.sh" ;;
    editdb) "${EDITOR:-nano}" "$DAM_HOME/commands.db" ;;
    custom) "${EDITOR:-nano}" "$DAM_HOME/custom-aliases.sh" ;;
    reload)
      if [ -n "${ZSH_VERSION:-}" ]; then
        # shellcheck disable=SC1090
        . "$HOME/.zshrc"
      elif [ -n "${BASH_VERSION:-}" ]; then
        # shellcheck disable=SC1090
        . "$HOME/.bashrc"
      else
        # shellcheck disable=SC1090
        . "$DAM_HOME/dam.sh"
      fi
      ;;
    *) _dam_help "$action" ;;
  esac
}

# shellcheck disable=SC1090
[ -f "$DAM_HOME/commands.sh" ] && . "$DAM_HOME/commands.sh"
# shellcheck disable=SC1090
[ -f "$DAM_HOME/custom-aliases.sh" ] && . "$DAM_HOME/custom-aliases.sh"

alias aliases='dam list'
alias daily='dam daily'
alias damcheck='dam check'

_dam_open_daily_after_reload() {
  local flag="$DAM_HOME/open-daily-after-reload"
  [ -f "$flag" ] || return 0
  case "$-" in
    *i*) ;;
    *) return 0 ;;
  esac
  rm -f "$flag"
  _dam_panel "Dev Alias Manager is ready" "Daily Favorites are open below."
  dam daily
}

_dam_open_daily_after_reload
