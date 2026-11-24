-- Opens where the focused app is working (ghostty-here: an IDE's project,
-- else a shell's cwd). Ghostty runs all windows in one process, so the
-- focused shell can't be found by pid: let it split itself.
local function terminal_here()
    local w = hl.get_active_window()
    local cmd = os.getenv("HOME") .. "/.local/bin/ghostty-here"
    if w and w.class == "com.mitchellh.ghostty" then
        hl.dispatch(hl.dsp.send_shortcut({ mods = "CTRL SHIFT", key = "Return" }))
    elseif w then
        hl.exec_cmd(cmd .. " " .. w.pid .. " " .. shell_quote(w.class) .. " " .. shell_quote(w.title))
    else
        hl.exec_cmd(cmd)
    end
end

bind {
    title = "Terminal here",
    group = "Apps",
    keys = "SUPER + Return",
    run = terminal_here,
}

bind {
    title = "New window here",
    group = "Ghostty",
    app = "com.mitchellh.ghostty",
    keys = "CTRL + SHIFT + Return",
}

bind {
    title = "Copy, or interrupt with no selection",
    group = "Ghostty",
    app = "com.mitchellh.ghostty",
    keys = "CTRL + C",
}

bind {
    title = "Interrupt",
    group = "Ghostty",
    app = "com.mitchellh.ghostty",
    keys = "CTRL + SHIFT + C",
}
