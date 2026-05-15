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

Recommended first commands:

```bash
dam help
dam preset fullstack
dam search sail
dam daily choose
```

For Laravel Sail projects, the Sail pack provides a direct wrapper and short aliases:

```bash
sail artisan migrate
sailup
sup
smig
```

Fresh reinstall:

```bash
./install.sh --clean
```
