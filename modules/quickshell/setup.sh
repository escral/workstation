#!/usr/bin/env bash
set -euo pipefail
source "$WS_ROOT/lib/common.sh"

# Qt 6 loads shaders only as precompiled .qsb, which stays out of git.
dir=$HOME/.config/quickshell/shaders
for src in "$dir"/*.frag; do
  out=$src.qsb
  [[ $out -nt $src ]] && continue
  /usr/lib/qt6/bin/qsb --glsl "100 es,120,150" --hlsl 50 --msl 12 -o "$out" "$src"
  info "compiled $(basename "$out")"
done

# The login screen runs as the greeter user, who can't read this home, so it
# gets its own copy of the config to sit in.
greeter=/etc/greetd/quickshell
sudo rm -rf "$greeter"
sudo cp -rL "$HOME/.config/quickshell" "$greeter"
sudo cp "$WS_MODULE_DIR/greeter.qml" "$greeter/"
