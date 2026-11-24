# The systemd user agent (ssh-agent.socket): a key's passphrase is asked once
# per session, and the desktop's apps (IDEs) share it.
export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent.socket"
