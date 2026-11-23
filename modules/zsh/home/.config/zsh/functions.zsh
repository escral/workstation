increaseWatchers() {
    sudo sysctl fs.inotify.max_user_watches=65536
    sudo sysctl -p
}

addToPath() {
    [[ ":$PATH:" == *":$1:"* ]] || export PATH="$PATH:$1"
}

addToPathFront() {
    [[ ":$PATH:" == *":$1:"* ]] || export PATH="$1:$PATH"
}

# ssh with an fzf host picker when called without arguments
unalias s 2>/dev/null
s() {
    if (( $# )); then
        ssh "$@"
        return
    fi
    local host
    host=$(grep -h "^Host " ~/.ssh/config ~/.ssh/config.local 2>/dev/null \
        | awk '{print $2}' | grep -v '^\*$' | fzf --prompt="SSH > ")
    [[ -n $host ]] && ssh "$host"
}
