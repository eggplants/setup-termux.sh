# AGENTS.md

## What this repo is

The global [mise](https://mise.jdx.dev) config for [Termux](https://termux.dev). It is cloned as `~/.config/mise`, and `mise bootstrap` sets the device up from it: Termux packages, CLI tools, dotfiles, login shell, and a few imperative steps.

## Apply the config

```bash
mise bootstrap --dry-run   # preview
mise bootstrap             # apply (zsh alias: mb)
```

## Test in Docker

```bash
docker run -d --name termux termux/termux-docker:latest sleep infinity
docker cp . termux:/data/data/com.termux/files/home/.config/mise
docker exec termux chown -R 1000:1000 /data/data/com.termux/files/home/.config
docker exec -it termux /entrypoint.sh bash -lc 'pkg upgrade -y && pkg install -y mise git rust && mise trust -a && ~/.config/mise/bootstrap.sh'
```

Run commands through `/entrypoint.sh` so they run as the Termux user; `pkg` refuses to run as root. The container has no Android framework, so `getprop` and `termux-setup-storage` fail there.

## Architecture

| File | Purpose |
|------|---------|
| `config.toml` | `[tools]`, `[bootstrap.packages]` (`pkg:`), `[bootstrap.repos]` (zsh plugins, nano syntax), `[dotfiles]`, shell activation, `bootstrap` task |
| `plugins/pkg/` | Package manager plugin that adds the `pkg:` manager (Termux `pkg` / `dpkg-query`) |
| `dotfiles/` | `[dotfiles]` sources (symlinked unless the entry says otherwise) |
| `tasks/setup/` | File tasks run by the `bootstrap` task: `shell`, `storage`, `gpg`, `git` |
| `bootstrap.sh` | Installs mise and git with `pkg`, clones this repo, links the `pkg` plugin, runs `mise bootstrap` |

### Key design decisions

- **Repo = global config** — relative `source` paths in `[dotfiles]` resolve from `~/.config/mise`. Tools in `[tools]` are global.
- **Declarative first, tasks for the rest** — use `[bootstrap.*]` / `[dotfiles]` when mise can check the state. The `bootstrap` task runs on every `mise bootstrap`, so its steps must be idempotent (guard every step).
- **`pkg:` plugin** — mise reports Termux as `android`, where the built-in `apt` manager is skipped, so `plugins/pkg` adds a `pkg:` manager. `[bootstrap.plugins]` only takes Git URLs, so `bootstrap.sh` runs `mise plugins link --force pkg plugins/pkg` instead.
- **pkg vs mise tools** — prebuilt mise tools target glibc Linux, not Android, so everything comes from `pkg`. Only `cargo:` tools (built locally) go in `[tools]`, such as `termscp`, which `pkg` lacks.
- **Packages before tools** — `mise bootstrap` installs `[tools]` before plugin packages, but `cargo:termscp` needs rust, perl, make, pkg-config, samba and dbus from `pkg`. The `pre-tools` hook runs `mise bootstrap packages apply` first.
- **Login shell** — `[bootstrap.user]` would use `sudo`, `/etc/shells` and `chsh -s <path>`, but Termux's `chsh` takes a shell name and only links `~/.termux/shell`. `setup:shell` runs `chsh -s zsh` (a dotfile symlink would fail before zsh is installed).
- **Git config** — `dotfiles/gitconfig` is static; `user.email` / `user.signingkey` are derived from the GPG keyring and written to `~/.gitconfig.local` by `setup:git`.
- **Shell** — `~/.zshrc` / `~/.zshenv` are whole-file dotfiles, so `~/.zshrc` activates mise itself; `[bootstrap.mise_shell_activate]` only writes shims into `~/.zprofile` / bash files.
