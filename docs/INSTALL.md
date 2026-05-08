# Install

```bash
chmod +x install.sh
./install.sh
```

The installer detects zsh or bash automatically and writes the DAM source block to the matching shell config.

Force a shell target when needed:

```bash
./install.sh --zsh
./install.sh --bash
./install.sh --both
```

After install, choose alias packs in the wizard and optionally pick your own Daily Favorites with checkboxes.

Fresh reinstall:

```bash
./install.sh --clean
```
