# zsh

oh-my-zsh (from the AUR, updated by pacman) with a starship prompt.

## Where things go

| You want… | Put it in |
|---|---|
| Env var or PATH for shells **and** GUI apps (IDEs) | `~/.config/env.d/NN-name.sh` (POSIX sh, use `ws_path DIR` for PATH) |
| A token / secret | `~/.config/env.d/90-secrets.sh` (untracked, `chmod 600`) |
| An alias for every machine | `aliases.zsh` |
| A function | `functions.zsh` |
| Something only this machine needs | `~/.config/zsh/local.zsh` (untracked) |
| A tool's shell setup (fnm, fzf, …) | that tool's module: `home/.config/zsh/conf.d/<tool>.zsh` |
| An oh-my-zsh plugin or fpath entry | `conf.d/<tool>.pre.zsh` (runs before oh-my-zsh) |
| Prompt | `~/.config/starship.toml` |

Repo files live under `modules/*/home/` and are linked into `~`; the untracked
ones are created by hand on each machine.

## Load order

1. `~/.zshenv` → `~/.config/env.sh` → every `~/.config/env.d/*.sh`.
   The desktop session loads the same files (uwsm), so IDEs see the same env.
2. `~/.zshrc` → `zshrc`: `conf.d/*.pre.zsh`, oh-my-zsh, autosuggestions,
   `aliases.zsh`, `functions.zsh`, `conf.d/*.zsh`, keys, starship, `local.zsh`.

## Installers

`~/.zshenv` and `~/.zshrc` are real files with one loader line, not links.
Installers that append to them keep working and never touch the repo.
`ws drift` lists what they added, so you can move it into a module or keep it.

## Prompt extras

`*` after the branch = uncommitted changes; `took 12s` = last command ran
longer than 3s. To drop either, delete its section from `starship.toml`
(`[git_status]`, `[cmd_duration]`) and its `$…` from `format`.
