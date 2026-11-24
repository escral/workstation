for i, key in ipairs({ "1", "2", "3", "4", "5", "6", "7", "8", "9", "0" }) do
    hl.bind("SUPER + " .. key, hl.dsp.focus({ workspace = i }))
    hl.bind("SUPER + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

bind {
    title = "Go to workspace",
    group = "Workspaces",
    keys = "SUPER + 1..0",
}

bind {
    title = "Move window to workspace",
    group = "Workspaces",
    keys = "SUPER + SHIFT + 1..0",
}

bind {
    title = "Browser workspace",
    group = "Workspaces",
    keys = "SUPER + grave",
    run = hl.dsp.focus({ workspace = 9 }),
}

bind {
    title = "Move window to the browser workspace",
    group = "Workspaces",
    keys = "SUPER + SHIFT + grave",
    run = hl.dsp.window.move({ workspace = 9 }),
}

bind {
    title = "Previous workspace",
    group = "Workspaces",
    keys = "ALT + Tab",
    run = hl.dsp.focus({ workspace = "previous" }),
}

bind {
    title = "Next workspace",
    group = "Workspaces",
    keys = "SUPER + mouse_down",
    run = hl.dsp.focus({ workspace = "e+1" }),
}

bind {
    title = "Previous workspace (wheel)",
    group = "Workspaces",
    keys = "SUPER + mouse_up",
    run = hl.dsp.focus({ workspace = "e-1" }),
}

bind {
    title = "Scratchpad",
    group = "Workspaces",
    keys = "SUPER + minus",
    run = hl.dsp.workspace.toggle_special("scratchpad"),
}

bind {
    title = "Move window to the scratchpad",
    group = "Workspaces",
    keys = "SUPER + SHIFT + minus",
    run = hl.dsp.window.move({ workspace = "special:scratchpad" }),
}
