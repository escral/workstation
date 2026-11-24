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
| Snapshots | Maybe later: snapper + snap-pac, bootable snapshots | A broken upgrade can also be a reinstall: `ws install` + `ws restore` |
| Updates | No unattended upgrades. `ws update` + notifier (checkupdates) + paccache.timer | Rolling release should be upgraded while watched |
| Firewall | ufw: deny incoming, allow outgoing | Simple; note Docker bypasses ufw — bind to 127.0.0.1 |
| Install | Plain bash + `ws` CLI. No Ansible, no mise | Most Ansible tasks were `shell:` anyway; less to learn, fewer deps |
| Packages | Per-module `packages` / `aur` lists, `pacman --needed` / `paru` | Declarative enough, readable |
| Baseline | `base` = only what the layer needs to operate (git, stow, curl, base-devel, `ws` on PATH). Every feature — even network/audio — is a module | Simple parts and their advanced config live together in one module |
| Dotfiles | GNU Stow, `--no-folding`, symlinks into this repo | Live editing, Quickshell hot reload |
| Runtimes | fnm (Node), official installer (Bun), pacman (PHP) | Each tool's native way |
| Secrets | Bitwarden (`rbw`): `ws secrets` after install writes the vault folder `workstation` into ~ | Repo stays public, nothing encrypted in git |
| App state | `ws backup` / `ws restore` to a USB drive (found and mounted by itself, or a folder given): restic repository `ws-backup`, encrypted with a password asked each run and kept nowhere. One snapshot per module, paths in its `state` file, caches in `state-exclude`. Running apps are offered to close | Config in git, state on the drive. Never in git. Chromium apps encrypt cookies and passwords with a key from the keyring, so the keyring goes too; it opens only under the same login password |
| Theme | One token file → generated configs for every app | Theme switch = one change |
| Bindings | Action catalog: `bind {}` / `action {}` in each module's `hypr/actions.d/*.lua`. Hyprland binds the keys and writes `~/.cache/ws/actions.json` for the launcher and the help; they run an entry via `hyprctl dispatch 'ws_action(...)'` | One source of truth, no generator step; Lua actions run too |
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
  state                 app state paths under ~ for `ws backup`; caches in state-exclude
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
| vpn | L2TP/IPsec plugin (networkmanager-l2tp, strongswan); `vpn NAME` toggles a saved connection, `vpn --status NAME` | all |
| audio | pipewire, wireplumber, pavucontrol | all |
| secrets | rbw; `ws secrets` writes the Bitwarden folder `workstation` into ~, each item named by its path: SSH key items give the key and `.pub` (`.ssh/id_rsa`), notes their text (`.ssh/config.local`, `.config/git/identity`) | all |
| ssh | openssh, ssh-agent (systemd user socket, keys added on first use), `~/.ssh/config` including `config.local` (hosts, from Bitwarden) | all |
| git | `~/.config/git/config` (Bitbucket over ssh); name and email in `identity`, from Bitwarden | all |
| cli | fzf, fzf-marks, ripgrep, fd, jq, unzip, man-db, btop, `ide` (opens a project in PhpStorm/WebStorm), `marks-sync DIR[:PREFIX]...` (bookmarks the folders inside each DIR) | all |
| firewall | ufw | all |
| maintenance | pacman-contrib, paccache.timer | all |
| time | `TIMEZONE` from the profile, NTP via systemd-timesyncd | all |
| backup | restic, udisks2; `ws backup` / `ws restore` save and bring back what modules list in `state` (chrome, telegram, slack, keyring) | all |
| keyring | gnome-keyring, unlocked at login by PAM (greetd); holds the Chrome/Slack/Claude storage keys. After `ws restore keyring`, sign out and back in so the daemon reads it | all |
| login | greetd + cage running the Quickshell login screen → uwsm Hyprland | all |
| fonts | FiraCode Nerd, Noto, emoji | all |
| zsh | zsh, oh-my-zsh without plugins, autosuggestions, starship; chsh | all |
| hypr | Hyprland, portals, polkit agent, screenshots, xdg-user-dirs | all |
| quickshell | Bar, shader background, lock screen + idle lock/DPMS, notification popups, volume OSD, mute/offline/load indicators, calendar popup (click the date), red attention pills for apps with unread (LauncherEntry counts, else notifications from apps with a desktop entry; script notify-send only pops up), plus a dot on their workspace (no tray), launcher (Super+Space all, Super+D apps, Super+P projects from fzf-marks, Super+Ctrl+P actions; also windows, calculator, web), app glyphs instead of an icon theme | all |
| kitty | kitty (config to port) | all |
| claude | Claude desktop app (AUR repack of the official .deb; opens on the AI workspace, dark by its own flag), Claude Code CLI (native installer, updates itself), `~/.claude/settings.json` in the repo | home, work, vm |
| docker | docker, compose, buildx; socket-activated daemon, user in the docker group, published ports on localhost unless bound explicitly (docker bypasses ufw) | home, work, vm |
| chrome | Google Chrome, opens on the Browser workspace | vm |
| telegram / slack | Telegram, Slack: start with the session on the Chat workspace | vm |
| bluetooth | bluez, blueman | home |
| nvidia | nvidia-open + Wayland bits | home |
| intel / virtio | The GPU's Vulkan driver (vulkan-intel; vulkan-swrast in the VM, where virgl is GL only), so Vulkan apps don't pull nvidia-utils | work / vm |
| dev-node / dev-bun / dev-php | fnm / bun / php+composer | home, work |
| jetbrains | Toolbox from JetBrains' latest release (updates itself and the IDEs); PhpStorm/WebStorm installed from it; its scripts on PATH for `ide`; kept out of XDG autostart (no tray here) | home, work, vm |
| zed | Zed as the quick plain editor: Tokyo Night, FiraCode 18, line height 1.4; minimal chrome, no AI, no language servers, telemetry off | home, work, vm |

## Action catalog

```lua
-- modules/<name>/home/.config/hypr/actions.d/<topic>.lua
bind { title = "Chrome", group = "Apps", keys = "SUPER + C", run = "uwsm app -- google-chrome-stable" }
action { title = "Sync project marks", run = "marks-sync /var/www", terminal = true }
```

- `bind` is a hotkey: in the help, not in the launcher. `action` is in the
  launcher, and in the help when it has keys. `launcher` / `help` override.
- `run` is a shell command, a `hl.dsp` dispatcher or a Lua function. An entry
  without it only documents keys bound elsewhere (workspace loops, submaps,
  an app's own keys with `app = "<class>"`).
- The loader (`hypr/catalog.lua`) warns about duplicate titles and keys.
- Personal actions that stay out of the repo: any `.lua` in
  `~/.config/hypr/actions.d/`.
- App-internal keys (Ghostty, Zed, IDEs) stay in each app's config; the
  catalog only describes them for the help. A generator that writes them is
  for later, with the theme generator (item 6), if the two copies drift.
- Later: `confirm = true` for Log out / Power off; providers for actions with
  a parameter from the system (one per VPN connection, one per theme).

## Help overlay (planned)

- Hold Super ~300ms → overlay of Super binds; adding Shift filters live.
- Leader: key to pick (Super+Space is the launcher) → Hyprland submaps (`w` window, `s` screenshot, `a` AI...),
  which-key popup at each step.

## Roadmap

1. [x] Skeleton, `ws` CLI, bootstrap, starter modules/profiles
2. [x] VM: `ws vm base` + `ws vm fresh` green, Hyprland (Lua config) + Quickshell bar running
2b. [x] Time: NTP sync (systemd-timesyncd) and timezone per profile
3. [~] Port from `~/.dotfiles`: zsh ✓, fzf ✓, kitty → ghostty ✓, git ✓, scripts ✓ (`marks-sync`, `vpn`; the rest replaced or dropped); nvim left
4. [x] Desktop polish before more modules: Tokyo Night + glass windows ✓, shader background ✓, workspace bar ✓, window animations ✓, lock screen ✓, login screen ✓, notification popups ✓, volume OSD + bar mute icon ✓, offline network icon ✓, CPU/RAM/disk indicators ✓, app placement + autostart (`apps.d`) ✓, launcher ✓, app glyphs ✓, calendar popup ✓, "no results" line in the launcher ✓, attention indicator in place of a tray (LauncherEntry unread counts, our notifications, urgent windows, SNI NeedsAttention) ✓
5. [~] Action catalog, designed together with 6: `bind {}` / `action {}` in `actions.d/` ✓, launcher's Actions from it ✓, existing hotkeys moved over ✓; left: help overlay
6. [ ] Theme tokens + generators: mainly one place for the colours every app uses; switching themes (an action) is a nice extra
7. [x] Secrets from Bitwarden (`ws secrets`: SSH keys, ssh hosts, git identity) ✓; app state backup/restore to a USB drive (`ws backup` / `ws restore`) ✓
8. [ ] AI module (embeddings search, first in the launcher; whisper dictation, piper)
9. [ ] Install on home PC (wipe Linux partition, keep Windows). Windows keeps the hardware clock in local time and Linux in UTC: set Windows to UTC (`RealTimeIsUniversal`) or the clock jumps by 2h between them. Moving from the current Ubuntu: its `~/.local/share/keyrings` opens here if the login password is the same; else move the `<App> Safe Storage` keys by hand (`secret-tool`)
10. [ ] IDE-aware Super+Enter: JetBrains (title → recentProjects.xml), Zed
11. [ ] Timers module (pomodoro, reminders via systemd timers)
