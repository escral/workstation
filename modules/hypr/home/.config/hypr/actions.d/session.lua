bind {
    title = "Reload Hyprland",
    group = "Session",
    keys = "SUPER + SHIFT + C",
    run = hl.dsp.reload_config(),
}

-- Exit asks first: Y confirms, anything else cancels.
bind {
    title = "Exit Hyprland",
    group = "Session",
    keys = "SUPER + SHIFT + E",
    run = function()
        hl.notification.create({ text = "Exit Hyprland?  Y to confirm, any other key cancels", duration = 5000 })
        hl.dispatch(hl.dsp.submap("exit"))
    end,
}
hl.define_submap("exit", function()
    hl.bind("Y", hl.dsp.exit())
    hl.bind("catchall", hl.dsp.submap("reset"))
end)

action {
    title = "Log out",
    group = "Session",
    glyph = "\u{F0343}",
    words = { "exit", "sign out", "logout" },
    run = "uwsm stop",
}

action {
    title = "Suspend",
    group = "Session",
    glyph = "\u{F04B2}",
    words = { "sleep" },
    run = "systemctl suspend",
}

action {
    title = "Reboot",
    group = "Session",
    glyph = "\u{F0709}",
    words = { "restart" },
    run = "systemctl reboot",
}

action {
    title = "Power off",
    group = "Session",
    glyph = "\u{F0425}",
    words = { "shutdown", "shut down", "turn off" },
    run = "systemctl poweroff",
}
