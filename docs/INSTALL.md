# Install

```bash
chmod +x install.sh
./install.sh
```

The installer asks which shell config to update:

```text
1) Auto detected
2) Zsh only
3) Bash only
4) Both zsh and bash
0) Cancel install
```

For scripts, force a shell target when needed:

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
