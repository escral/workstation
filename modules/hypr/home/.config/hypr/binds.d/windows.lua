local mod = "SUPER"

-- Focus (also cycles through tabs of a group first)
hl.bind(mod .. " + H", hl.dsp.focus({ direction = "left" }))
hl.bind(mod .. " + J", hl.dsp.focus({ direction = "down" }))
hl.bind(mod .. " + K", hl.dsp.focus({ direction = "up" }))
hl.bind(mod .. " + L", hl.dsp.focus({ direction = "right" }))
hl.bind(mod .. " + left", hl.dsp.focus({ direction = "left" }))
hl.bind(mod .. " + down", hl.dsp.focus({ direction = "down" }))
hl.bind(mod .. " + up", hl.dsp.focus({ direction = "up" }))
hl.bind(mod .. " + right", hl.dsp.focus({ direction = "right" }))

-- Move
hl.bind(mod .. " + SHIFT + H", hl.dsp.window.move({ direction = "left" }))
hl.bind(mod .. " + SHIFT + J", hl.dsp.window.move({ direction = "down" }))
hl.bind(mod .. " + SHIFT + K", hl.dsp.window.move({ direction = "up" }))
hl.bind(mod .. " + SHIFT + L", hl.dsp.window.move({ direction = "right" }))
hl.bind(mod .. " + SHIFT + left", hl.dsp.window.move({ direction = "left" }))
hl.bind(mod .. " + SHIFT + down", hl.dsp.window.move({ direction = "down" }))
hl.bind(mod .. " + SHIFT + up", hl.dsp.window.move({ direction = "up" }))
hl.bind(mod .. " + SHIFT + right", hl.dsp.window.move({ direction = "right" }))

-- Resize: directly with Ctrl, or Super+R mode with plain keys
local function resize(x, y)
    return hl.dsp.window.resize({ x = x, y = y, relative = true })
end
local repeating = { repeating = true }

hl.bind(mod .. " + CTRL + H", resize(-40, 0), repeating)
hl.bind(mod .. " + CTRL + J", resize(0, 40), repeating)
hl.bind(mod .. " + CTRL + K", resize(0, -40), repeating)
hl.bind(mod .. " + CTRL + L", resize(40, 0), repeating)

hl.bind(mod .. " + R", hl.dsp.submap("resize"))
hl.define_submap("resize", function()
    hl.bind("H", resize(-40, 0), repeating)
    hl.bind("J", resize(0, 40), repeating)
    hl.bind("K", resize(0, -40), repeating)
    hl.bind("L", resize(40, 0), repeating)
    hl.bind("left", resize(-40, 0), repeating)
    hl.bind("down", resize(0, 40), repeating)
    hl.bind("up", resize(0, -40), repeating)
    hl.bind("right", resize(40, 0), repeating)
    hl.bind("Return", hl.dsp.submap("reset"))
    hl.bind("Escape", hl.dsp.submap("reset"))
end)

-- Layout
hl.bind(mod .. " + F", hl.dsp.window.fullscreen())
hl.bind(mod .. " + M", hl.dsp.window.fullscreen({ mode = "maximized" }))
hl.bind(mod .. " + E", hl.dsp.layout("togglesplit"))
hl.bind(mod .. " + W", hl.dsp.group.toggle())
hl.bind(mod .. " + SHIFT + space", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mod .. " + SHIFT + F", hl.dsp.window.pin())
hl.bind(mod .. " + SHIFT + Q", hl.dsp.window.close())

-- Mouse
hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })
