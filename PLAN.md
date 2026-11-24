# Plan

Personal Arch Linux layer: one command on a bare Arch install gives my full
workstation. Not a distro — a layer on top of Arch.

## Decisions

| Area | Choice | Why |
|---|---|---|
| Base | Arch Linux (`archinstall`, then `boot.sh`) | Rolling, AUR has Hyprland/Quickshell, fast iteration |
| Compositor | Hyprland | Biggest ecosystem; Quickshell works with it |
| Terminal | Ghostty (trial vs kitty): background service + D-Bus ≈130ms; splits/tabs are Hyprland windows/groups. Super+Enter opens where the focused app works (Ghostty: self-split; others: deepest interactive child's cwd) | One navigation system (Super+hjkl) for everything; context-aware terminal |
| Shell UI | Quickshell | Bar, launcher, notifications, OSD, help overlay — replaces dunst/rofi/i3status |
| GUI fallback | nm-connection-editor (VPN/proxy), pavucontrol, blueman | Configure things by GUI when no tool exists. Full GNOME session dropped (~1GB) — revisit if needed |
| Session | greetd + Quickshell login screen (in cage) → `uwsm start hyprland.desktop` | Login looks like the lock screen; uwsm = systemd-managed session: clean env, apps as units, proper logout |
| Filesystem | **btrfs** (archinstall default subvolumes) — required at install time | Enables snapshots; can't be added later without reinstall |
| Snapshots | snapper + snap-pac (snapshot before every pacman run), bootable snapshots | Rollback = Arch's replacement for "LTS stability" |
| Updates | No unattended upgrades. `ws update` + notifier (checkupdates) + paccache.timer | Rolling release should be upgraded while watched |
| Firewall | ufw: deny incoming, allow outgoing | Simple; note Docker bypasses ufw — bind to 127.0.0.1 |
| Install | Plain bash + `ws` CLI. No Ansible, no mise | Most Ansible tasks were `shell:` anyway; less to learn, fewer deps |
| Packages | Per-module `packages` / `aur` lists, `pacman --needed` / `paru` | Declarative enough, readable |
| Baseline | `base` = only what the layer needs to operate (git, stow, curl, base-devel, `ws` on PATH). Every feature — even network/audio — is a module | Simple parts and their advanced config live together in one module |
| Dotfiles | GNU Stow, `--no-folding`, symlinks into this repo | Live editing, Quickshell hot reload |
| Runtimes | fnm (Node), official installer (Bun), pacman (PHP) | Each tool's native way |
| Secrets | Bitwarden (`rbw`): `ws secrets` after install writes the vault folder `workstation` into ~ | Repo stays public, nothing encrypted in git |
| App state | restic backup of Chrome/Slack/Telegram + keyring, key in Bitwarden | Config in git, state in backup. Never in git |
| Theme | One token file → generated configs for every app | Theme switch = one change |
| Bindings | Action catalog (`actions.toml` per module) generates hypr/kitty bind files, help overlay, launcher catalog | One source of truth |
| Profiles | `profiles/<name>/` = modules + flags + overlay files (monitors, autostart, peripherals) | Whole-machine setup, not only hardware |
| Testing | QEMU VM with virgl. `ws vm base` builds a minimal btrfs Arch image unattended (cloud-init seed over HTTP → ssh into live ISO → `vm/install-base.sh`); `ws vm fresh` = clean overlay + full bootstrap | See a reinstall without reinstalling; catch drift. Host needs only QEMU + python3; TCG fallback without KVM (headless only) |
| AI | Small specialized local models (embeddings, whisper, piper, reranker), GPU tier optional via profile flag | Must run on CPU-only machines |

## Layout

```
boot.sh                 curl | bash entry on bare Arch
bin/ws                  CLI (install, sync, update, drift, vm, ...)
lib/                    shared bash helpers
modules/<name>/
  packages              pacman packages, one per line, # comments ok
  aur                   AUR packages
  home/                 stow package, mirrors $HOME
  setup.sh              optional idempotent hook (runs after packages + stow)
  actions.toml          optional bindings/actions for the catalog
profiles/<name>/
  profile.sh            extends, modules, flags
  home/                 overlay, stowed after modules
vm/                     VM harness
```

### Overlay rule

Overlays **add** files, never replace module files (stow would conflict).
Modules expose include points instead, e.g. `hyprland.lua` loads
`~/.config/hypr/local/*.lua`; a profile drops `local/<profile>.lua` there.

### Profile format

`profile.sh` is sourced bash (zero dependencies on a bare machine):

```bash
extends=base
modules+=(hypr kitty)
GPU=nvidia
AI_TIER=gpu
```

## Modules

| Module | Contents | Profiles |
|---|---|---|
| base | git, stow, curl, base-devel, pacman tweaks, `ws` on PATH | all |
| network | NetworkManager, nm-connection-editor | all |
| audio | pipewire, wireplumber, pavucontrol | all |
| secrets | rbw; `ws secrets` writes the Bitwarden folder `workstation` into ~, each item named by its path: SSH key items give the key and `.pub` (`.ssh/id_rsa`), notes their text (`.ssh/config.local`, `.config/git/identity`) | all |
| ssh | openssh, ssh-agent (systemd user socket, keys added on first use), `~/.ssh/config` including `config.local` (hosts, from Bitwarden) | all |
| git | `~/.config/git/config` (Bitbucket over ssh); name and email in `identity`, from Bitwarden | all |
| cli | fzf, fzf-marks, ripgrep, fd, jq, unzip, man-db, btop, `ide` (opens a project in PhpStorm/WebStorm) | all |
| firewall | ufw | all |
| maintenance | pacman-contrib, paccache.timer | all |
| login | greetd + cage running the Quickshell login screen → uwsm Hyprland | all |
| fonts | FiraCode Nerd, Noto, emoji | all |
| zsh | zsh + plugins, chsh (config to port) | all |
| hypr | Hyprland, portals, polkit agent, screenshots, xdg-user-dirs | all |
| quickshell | Bar, shader background, lock screen + idle lock/DPMS, notification popups, volume OSD, mute/offline/load indicators, calendar popup (click the date), red attention pills for apps with unread (LauncherEntry counts, else notifications), plus a dot on their workspace (no tray), launcher (Super+Space all, Super+D apps, Super+P projects from fzf-marks, Super+Ctrl+P actions; also windows, calculator, web), app glyphs instead of an icon theme | all |
| kitty | kitty (config to port) | all |
| claude | Claude desktop app (AUR repack of the official .deb; opens on the AI workspace, dark by its own flag), Claude Code CLI (native installer, updates itself), `~/.claude/settings.json` in the repo | home, work, vm |
| chrome | Google Chrome, opens on the Browser workspace | vm |
| telegram / slack | Telegram, Slack: start with the session on the Chat workspace | vm |
| bluetooth | bluez, blueman | home |
| nvidia | nvidia-open + Wayland bits | home |
| dev-node / dev-bun / dev-php | fnm / bun / php+composer | home, work |

## Action catalog (planned)

```toml
[[action]]
title = "New tab"
group = "terminal/tabs"
keys  = "ctrl+shift+t"
kitty = "new_tab_with_cwd"
```

Generator writes `~/.config/kitty/binds.conf`, `~/.config/hypr/binds.lua`,
help-overlay data and launcher catalog. App configs `include` the generated file.
Each target uses the app's native syntax — generator only translates keys.
Watcher regenerates and runs `kitty @ load-config` / `hyprctl reload`.
Lint warns about raw binds not in the catalog and key conflicts.
Help overlay is context-aware via `hyprctl activewindow`.
Ported from `~/.dotfiles/bin/.local/action-hub` (Bun/TS).

## Help overlay (planned)

- Hold Super ~300ms → overlay of Super binds; adding Shift filters live.
- Leader: key to pick (Super+Space is the launcher) → Hyprland submaps (`w` window, `s` screenshot, `a` AI...),
  which-key popup at each step.

## Roadmap

1. [x] Skeleton, `ws` CLI, bootstrap, starter modules/profiles
2. [x] VM: `ws vm base` + `ws vm fresh` green, Hyprland (Lua config) + Quickshell bar running
2a. [ ] Snapshots module: snapper + snap-pac + bootable snapshots
2b. [ ] Time: NTP sync (systemd-timesyncd) and timezone per profile; the VM base image is UTC with no NTP
3. [~] Port from `~/.dotfiles`: zsh ✓, fzf ✓, kitty → ghostty ✓; nvim, git, scripts left
4. [~] Desktop polish before more modules: Tokyo Night + glass windows ✓, shader background ✓, workspace bar ✓, window animations ✓, lock screen ✓, login screen ✓, notification popups ✓, volume OSD + bar mute icon ✓, offline network icon ✓, CPU/RAM/disk indicators ✓, app placement + autostart (`apps.d`) ✓, launcher ✓, app glyphs ✓, calendar popup ✓, attention indicator in place of a tray (LauncherEntry unread counts, our notifications, urgent windows, SNI NeedsAttention) ✓; left: a timers module (pomodoro, reminders via systemd timers)
5. [ ] Theme tokens + generators
6. [ ] Action catalog generator + help overlay; the catalog feeds the launcher's Actions
7. [~] Secrets from Bitwarden (`ws secrets`: SSH keys, ssh hosts, git identity) ✓; restic state backup/restore left
8. [ ] AI module (embeddings search, first in the launcher; whisper dictation, piper)
9. [ ] Install on home PC (wipe Linux partition, keep Windows)
10. [ ] IDE-aware Super+Enter: JetBrains (title → recentProjects.xml), VS Code/Cursor, when those modules exist
