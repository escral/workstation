-- Opens where the focused app is working. Ghostty runs all windows in one
-- process, so the focused shell can't be found by pid: let it split itself.
hl.bind("SUPER + Return", function()
    local w = hl.get_active_window()
    if w and w.class == "com.mitchellh.ghostty" then
        hl.dispatch(hl.dsp.send_shortcut({ mods = "CTRL SHIFT", key = "Return" }))
    else
        hl.exec_cmd(os.getenv("HOME") .. "/.local/bin/ghostty-here" .. (w and (" " .. w.pid) or ""))
    end
end)
