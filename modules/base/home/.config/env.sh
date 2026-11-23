# Environment shared by the desktop session (uwsm, so GUI apps like IDEs get
# it) and every zsh. POSIX sh: uwsm sources it with sh.
ws_path() {
  case ":$PATH:" in
    *":$1:"*) ;;
    *) PATH="$1:$PATH" ;;
  esac
}

for f in "$HOME"/.config/env.d/*.sh; do
  [ -r "$f" ] && . "$f"
done
unset f
export PATH
