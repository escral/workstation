# fnm's default alias, not `fnm env`: that makes a per-shell path that GUI
# apps would lose. Shells switch versions on cd via conf.d/node.zsh.
export FNM_DIR="$HOME/.local/share/fnm"
ws_path "$FNM_DIR/aliases/default/bin"

export PNPM_HOME="$HOME/.local/share/pnpm"
ws_path "$PNPM_HOME"
ws_path "$HOME/.local/.npm-global/bin"

export NODE_OPTIONS="${NODE_OPTIONS:---max-old-space-size=4096}"
