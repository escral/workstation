#!/usr/bin/env bash
# Toolbox comes from JetBrains, not the AUR: it updates itself and the IDEs in
# place, which a pacman-owned copy would fight. The IDEs are installed from
# Toolbox, which needs the JetBrains account for their licences anyway.
set -euo pipefail
source "$WS_ROOT/lib/common.sh"

dir=$HOME/.local/share/JetBrains/Toolbox
if [[ ! -x $dir/bin/jetbrains-toolbox ]]; then
  url=$(curl -fsSL 'https://data.services.jetbrains.com/products/releases?code=TBA&latest=true&type=release' \
    | jq -r '.TBA[0].downloads.linux.link')
  [[ $url == https://* ]] || die "no Toolbox download link from JetBrains"
  info "downloading ${url##*/}"
  # Unpacked aside and moved in whole: a download cut short must not leave
  # a half Toolbox that the check above takes for installed.
  rm -rf "$dir.part"
  mkdir -p "$dir.part"
  curl -fsSL "$url" | tar -xz -C "$dir.part" --strip-components=1
  rm -rf "$dir"
  mv "$dir.part" "$dir"
fi
ln -sfn "$dir/bin/jetbrains-toolbox" "$HOME/.local/bin/jetbrains-toolbox"

# Toolbox writes its own launcher entry on first run; until then the
# launcher would not find it.
entry=$HOME/.local/share/applications/jetbrains-toolbox.desktop
if [[ ! -f $entry ]]; then
  mkdir -p "${entry%/*}"
  printf '%s\n' '[Desktop Entry]' 'Type=Application' 'Name=JetBrains Toolbox' \
    "Exec=$dir/bin/jetbrains-toolbox" 'Categories=Development' \
    'StartupWMClass=jetbrains-toolbox' >"$entry"
fi

# IdeaVim in every IDE Toolbox installed. Its key settings are in
# ~/.config/ideavim, so the plugin is all an IDE needs. installPlugins starts
# the IDE headless, which fails while that IDE is open: then next time.
for product in "$HOME"/.local/share/JetBrains/Toolbox/apps/*/product-info.json; do
  [[ -f $product ]] || continue
  data=$(jq -r .dataDirectoryName "$product")
  [[ -d $HOME/.local/share/JetBrains/$data/IdeaVIM ]] && continue
  info "installing IdeaVim into $data"
  "${product%/*}/$(jq -r '.launch[0].launcherPath' "$product")" installPlugins IdeaVIM >/dev/null 2>&1 \
    || warn "could not install IdeaVim into $data (is it open?)"
done

# Toolbox re-adds itself to XDG autostart on every run, to start hidden in a
# tray this desktop does not have. Masking the unit uwsm would start for it
# keeps it from running unseen.
systemctl --user mask --quiet "app-$(systemd-escape jetbrains-toolbox)@autostart.service"
