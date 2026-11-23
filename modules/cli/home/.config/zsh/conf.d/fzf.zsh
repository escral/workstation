source <(fzf --zsh)

_fzf_compgen_path() { fd --hidden --follow --exclude ".git" . "$1"; }
_fzf_compgen_dir() { fd --type d --hidden --follow --exclude ".git" . "$1"; }

# Bookmarks: `mark` adds the current dir, `ff` (fzm) jumps
source ~/.local/share/fzf-marks/fzf-marks.plugin.zsh
alias ff='fzm'
