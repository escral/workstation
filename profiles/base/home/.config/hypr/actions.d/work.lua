action {
    title = "Sync project marks",
    group = "Projects",
    glyph = "\u{F024B}",
    words = { "fzf", "bookmarks", "www" },
    run = "marks-sync /var/www /var/www/tmg:tmg/ /var/www/c2b:c2b/",
    terminal = true,
}

action {
    title = "VPN TBC",
    group = "Network",
    glyph = "\u{F0582}",
    words = { "vpn", "toggle", "connect" },
    run = [[vpn TBC >/dev/null 2>&1; notify-send VPN "$(vpn --status TBC 2>&1)"]],
}
