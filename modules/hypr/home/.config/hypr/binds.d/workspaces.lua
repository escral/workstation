local mod = "SUPER"

-- Super+1..9, Super+0 = 10; with Shift moves the window there
for i, key in ipairs({ "1", "2", "3", "4", "5", "6", "7", "8", "9", "0" }) do
    hl.bind(mod .. " + " .. key, hl.dsp.focus({ workspace = i }))
    hl.bind(mod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

hl.bind(mod .. " + grave", hl.dsp.focus({ workspace = 9 }))
hl.bind(mod .. " + SHIFT + grave", hl.dsp.window.move({ workspace = 9 }))

hl.bind("ALT + Tab", hl.dsp.focus({ workspace = "previous" }))
hl.bind(mod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))

-- Scratchpad
hl.bind(mod .. " + minus", hl.dsp.workspace.toggle_special("scratchpad"))
hl.bind(mod .. " + SHIFT + minus", hl.dsp.window.move({ workspace = "special:scratchpad" }))
