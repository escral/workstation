-- All to clipboard
local region = [[grim -g "$(slurp)" - | wl-copy]]
local window = [[grim -g "$(hyprctl activewindow -j | jq -r '"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"')" - | wl-copy]]
local screen = [[grim - | wl-copy]]

hl.bind("Print", hl.dsp.exec_cmd(region))
hl.bind("SHIFT + F12", hl.dsp.exec_cmd(region))
hl.bind("SUPER + Print", hl.dsp.exec_cmd(window))
hl.bind("SHIFT + Print", hl.dsp.exec_cmd(screen))
