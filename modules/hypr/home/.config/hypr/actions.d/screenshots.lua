-- All to clipboard
local window = [[grim -g "$(hyprctl activewindow -j | jq -r '"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"')" - | wl-copy]]

action {
    title = "Screenshot region",
    group = "Screenshot",
    glyph = "\u{F0100}",
    words = { "capture", "snip" },
    keys = { "Print", "SHIFT + F12" },
    run = [[grim -g "$(slurp)" - | wl-copy]],
}

action {
    title = "Screenshot window",
    group = "Screenshot",
    glyph = "\u{F0100}",
    words = { "capture" },
    keys = "SUPER + Print",
    run = window,
}

action {
    title = "Screenshot screen",
    group = "Screenshot",
    glyph = "\u{F0100}",
    words = { "capture" },
    keys = "SHIFT + Print",
    run = [[grim - | wl-copy]],
}
