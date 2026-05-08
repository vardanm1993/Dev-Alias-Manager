# Dev Alias Manager

Dev Alias Manager is a Bash/Zsh alias manager for Laravel and PHP fullstack developers.

It provides a polished command layer for everyday Laravel, Sail, Composer, npm/Vite, Docker, Git, GitHub CLI, Pest, Pint, Rector, PHPStan, security checks, and project workflows.

DAM installs shell functions, aliases, help screens, and Daily Favorites only. It does not install Docker, PHP, Composer, Node, Laravel, Sail, or any third-party developer tool.

## Highlights

- Bash and Zsh support.
- Safe installer that keeps existing aliases, Daily Favorites, and config by default.
- Checkbox setup UI with `dialog` or `whiptail`, plus a text fallback.
- Searchable alias registry.
- Add, change, remove, list, and explain aliases.
- Daily Favorites for commands you use often or forget.
- Sail-aware execution for Laravel projects.
- Focused alias packs for Laravel/PHP fullstack work.

## Install

```bash
git clone https://github.com/vardanm1993/Dev-Alias-Manager.git
cd Dev-Alias-Manager
chmod +x install.sh uninstall.sh
./install.sh
```

Reload your terminal or source your shell config:

```bash
source ~/.zshrc
# or
source ~/.bashrc
```

For the best checkbox UI on Ubuntu/Debian:

```bash
sudo apt install dialog
```

If `dialog` is not available, DAM tries `whiptail`. If neither is available, DAM uses a simple text menu.

## Update

Run the installer again. Existing aliases, Daily Favorites, and config are kept.

```bash
./install.sh
```

For a fresh local reinstall:

```bash
./install.sh --clean
```

## Start Here

```bash
dam wizard          # choose alias packs with checkbox UI
dam daily install   # install recommended Daily Favorites
dam list            # show installed aliases
dam search route    # search aliases
dam help            # open the help center
dam check           # inspect local tool availability
```

## Daily Favorites

Daily Favorites are a small personal list for commands you use frequently or want to remember quickly.

```bash
dam daily                 # open Daily menu
dam daily install         # merge recommended favorites
dam daily choose          # choose favorites with checkbox UI
dam daily add myroutes    # add one alias
dam daily remove myroutes # remove one alias
dam daily run             # run Daily aliases in order
dam daily reset           # replace Daily with recommended defaults
```

Recommended Daily Favorites are defined in [`presets/recommended-daily.tsv`](presets/recommended-daily.tsv):

```text
projectdoctor  myroutes  sup  nrd  pint  pest  rcheck  stan  qa  gs  gcam  gp
```

## Manage Aliases

```bash
dam add hello system 'echo hello' 'Print hello'
dam add-to laravel mylogs raw 'tail -f storage/logs/laravel.log' 'Follow Laravel log'
dam change quality pest vendor 'pest' 'Run Pest tests'
dam remove hello
dam search pest
dam help alias pest
```

Alias kinds:

| Kind | Runs |
| --- | --- |
| `artisan` | `php artisan` or Sail artisan |
| `npm` | `npm` or Sail npm |
| `composer` | Composer or Sail composer |
| `php` | PHP or Sail PHP |
| `vendor` | Tools in `./vendor/bin` |
| `system` | Normal shell commands |
| `raw` | Advanced shell workflows |

## Included Packs

| Pack | Examples |
| --- | --- |
| Laravel | `myroutes`, `dbmigrate`, `dbfresh`, `qwork`, `logs`, `mkc`, `mkm`, `mkmig` |
| Sail | `sup`, `supb`, `sdown`, `slog`, `sshapp`, `snrd`, `snrb` |
| Quality | `pint`, `pinttest`, `pest`, `rcheck`, `rfix`, `stan`, `qa` |
| Frontend | `ni`, `nrd`, `nrb`, `nrt`, `nrl`, `npreview` |
| Git | `gs`, `ga`, `gaa`, `gcm`, `gcam`, `gp`, `gpf` |
| Docker | `dc`, `dcu`, `dcub`, `dcd`, `dcl`, `dps`, `dprune` |
| PHP / Composer | `phpv`, `ci`, `cu`, `creq`, `creqd`, `cda`, `cval`, `caudit` |
| Security | `secenv`, `seckey`, `secaudit`, `secnpm`, `secperms` |

## Laravel Examples

```bash
art make:controller UserController
myroutes
dbmigrate
dbfresh
qwork
logs
mkc UserController
mkm User
mkmig create_posts_table
```

## Configuration

Open config:

```bash
dam config
```

Defaults:

```bash
DAM_SAIL_BIN=./vendor/bin/sail
DAM_ARTISAN_BIN=artisan
DAM_VENDOR_BIN=./vendor/bin
DAM_AUTO_SAIL=1
```

Disable Sail auto-detection for one command:

```bash
USE_SAIL=0 myroutes
```

## Verify

```bash
make verify
```

The verification script checks Bash syntax, Zsh syntax, alias execution behavior, Daily Favorites, and installer behavior with custom `DAM_HOME`.

## Uninstall

Remove shell source blocks and keep config:

```bash
./uninstall.sh
```

Remove shell source blocks and config:

```bash
./uninstall.sh --purge
```

## License

MIT
