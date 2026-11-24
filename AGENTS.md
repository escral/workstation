# AGENTS.md

Personal Arch + Hyprland + Quickshell layer. One command on bare Arch
(`boot.sh` → `ws install --profile <name>`). Decisions and roadmap: `PLAN.md`.

## Principles

- **Lean baseline.** `base` holds only what the layer needs to run. Every
  feature, even network or audio, is its own module.
- **One feature at a time.** The owner decides each feature. Don't add
  modules, packages or config that weren't asked for.
- **No examples or placeholders.** No sample files, no commented-out sample
  config, no stubs for features not built yet. Planned work goes in `PLAN.md`.
- **Comments explain why, never what.** Write a comment only for something the
  code can't say: a non-obvious reason, a gotcha, a constraint. No headers
  restating the filename, no narrating code.
- **Human-readable first.** Short files, plain bash, obvious names. Prefer
  removing code over adding abstraction.

## Layout

```
boot.sh          entry on bare Arch
bin/ws           CLI
lib/             shared bash (common.sh: log/warn/die/have/read_list)
modules/<name>/  packages, aur, home/ (stowed into $HOME), setup.sh,
                 state + state-exclude (app state for ws backup)
profiles/<name>/ profile.sh (extends, modules+=, flags), home/ overlay
vm/              QEMU test harness
```

## Rules

- **Packages:** one per line in `packages` (pacman) or `aur` (paru).
- **`setup.sh`:** bash with `set -euo pipefail`. Must be idempotent, since it
  runs on every `ws install`. Gets `WS_ROOT`, `WS_MODULE`, `WS_MODULE_DIR` and
  the profile flags.
- **Overlays only add files.** A profile never replaces a module's file (stow
  would conflict). Modules expose include points instead, e.g.
  `~/.config/hypr/local/*.lua`.
- **Hyprland config is Lua** (0.57+): `hyprland.lua`, API under `hl.*`.
  `hyprland.conf` is ignored.
- **Hotkeys and launcher actions live with their module** in
  `home/.config/hypr/actions.d/<topic>.lua`: `bind {}` for a hotkey (listed
  in the help), `action {}` for something to run from the launcher (fields in
  `modules/hypr/home/.config/hypr/catalog.lua`). Raw `hl.bind` only for loops
  and inside submaps, with a `bind {}` without `run` documenting them.
- **Environment goes in `home/.config/env.d/NN-name.sh`** (POSIX sh, `ws_path`
  for PATH). Shells and the desktop session (IDEs) both load it.
- **No secrets in git.** The repo is public. Secrets come from Bitwarden
  (`ws secrets`, vault folder `workstation`); app state comes from the
  restic backup.
- **Test in the VM**, never by installing on the host.
- **Commits:** imperative, scoped (`hypr: ...`, `vm: ...`). Commit or push
  only when asked.

## VM

| Command | Does |
|---|---|
| `ws vm base` | build clean Arch image (once) |
| `ws vm fresh` | reset to clean image, install committed tree |
| `ws vm run` | boot with a window (the owner usually has it open) |
| `ws vm sync` | push working tree into running VM, run `ws install` |
| `ws vm shot` | screenshot of the session → `.vm/shot.png` |
| `ws vm key <combo>...` | press keys, e.g. `meta_l+ret` (QEMU qcodes) |
| `ws vm ssh -- <cmd>` | run a command inside |
| `ws vm stop` | clean shutdown |

- Login: your user, password `ws`. The window grabs the keyboard while the
  pointer is over it, so Super combos reach Hyprland, not the host WM.
  Ctrl+Alt+G toggles the grab manually. On an NVIDIA host the window is SDL
  (GTK+GL renders black there) and grabs on click instead.
- `hyprctl` over ssh needs
  `HYPRLAND_INSTANCE_SIGNATURE=$(ls -t $XDG_RUNTIME_DIR/hypr | head -1)`.
- Hyprland changes: `ws vm sync` (reloads and prints config errors).
- Quickshell changes: restart it with
  `pkill quickshell; hyprctl dispatch 'hl.dsp.exec_cmd("uwsm app -- quickshell")'`.
  Current log: newest `$XDG_RUNTIME_DIR/quickshell/by-id/*/log.log`
  (`quickshell log` may show an older instance).
- The owner may be using the VM window at the same time. Windows appearing
  or disappearing may be them.
- The firewall blocks ssh unless the profile sets `FIREWALL_ALLOW="ssh"`
  (the vm profile does).
