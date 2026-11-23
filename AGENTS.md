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
modules/<name>/  packages, aur, home/ (stowed into $HOME), setup.sh
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
  `~/.config/hypr/local/*.conf`.
- **No secrets in git.** The repo is public. Secrets come from Bitwarden; app
  state comes from the restic backup.
- **Test in the VM:** `ws vm fresh` for a full reinstall from the committed
  tree, `ws vm sync` for working-tree changes. Don't test by installing on the
  host.
- **Commits:** imperative, scoped (`hypr: ...`, `vm: ...`). Commit or push
  only when asked.
