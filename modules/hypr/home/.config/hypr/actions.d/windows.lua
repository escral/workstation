local function focus(dir)
    return hl.dsp.focus({ direction = dir })
end

local function move(dir)
    return hl.dsp.window.move({ direction = dir })
end

local function resize(x, y)
    return hl.dsp.window.resize({ x = x, y = y, relative = true })
end

-- Focus also cycles through the tabs of a group first.
bind {
    title = "Focus left",
    group = "Windows",
    keys = { "SUPER + H", "SUPER + left" },
    run = focus("left"),
}

bind {
    title = "Focus down",
    group = "Windows",
    keys = { "SUPER + J", "SUPER + down" },
    run = focus("down"),
}

bind {
    title = "Focus up",
    group = "Windows",
    keys = { "SUPER + K", "SUPER + up" },
    run = focus("up"),
}

bind {
    title = "Focus right",
    group = "Windows",
    keys = { "SUPER + L", "SUPER + right" },
    run = focus("right"),
}

bind {
    title = "Move left",
    group = "Windows",
    keys = { "SUPER + SHIFT + H", "SUPER + SHIFT + left" },
    run = move("left"),
}

bind {
    title = "Move down",
    group = "Windows",
    keys = { "SUPER + SHIFT + J", "SUPER + SHIFT + down" },
    run = move("down"),
}

bind {
    title = "Move up",
    group = "Windows",
    keys = { "SUPER + SHIFT + K", "SUPER + SHIFT + up" },
    run = move("up"),
}

bind {
    title = "Move right",
    group = "Windows",
    keys = { "SUPER + SHIFT + L", "SUPER + SHIFT + right" },
    run = move("right"),
}

bind {
    title = "Shrink width",
    group = "Windows",
    keys = "SUPER + CTRL + H",
    run = resize(-40, 0),
    repeating = true,
}

bind {
    title = "Grow height",
    group = "Windows",
    keys = "SUPER + CTRL + J",
    run = resize(0, 40),
    repeating = true,
}

bind {
    title = "Shrink height",
    group = "Windows",
    keys = "SUPER + CTRL + K",
    run = resize(0, -40),
    repeating = true,
}

bind {
    title = "Grow width",
    group = "Windows",
    keys = "SUPER + CTRL + L",
    run = resize(40, 0),
    repeating = true,
}

bind {
    title = "Resize mode: hjkl or arrows, Enter or Esc to leave",
    group = "Windows",
    keys = "SUPER + R",
    run = hl.dsp.submap("resize"),
}

hl.define_submap("resize", function()
    local repeating = { repeating = true }
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

bind {
    title = "Fullscreen",
    group = "Windows",
    keys = "SUPER + F",
    run = hl.dsp.window.fullscreen(),
}

bind {
    title = "Maximize",
    group = "Windows",
    keys = "SUPER + M",
    run = hl.dsp.window.fullscreen({ mode = "maximized" }),
}

bind {
    title = "Toggle split",
    group = "Windows",
    keys = "SUPER + E",
    run = hl.dsp.layout("togglesplit"),
}

bind {
    title = "Group into tabs",
    group = "Windows",
    keys = "SUPER + W",
    run = hl.dsp.group.toggle(),
}

bind {
    title = "Float",
    group = "Windows",
    keys = "SUPER + SHIFT + space",
    run = hl.dsp.window.float({ action = "toggle" }),
}

bind {
    title = "Pin on every workspace",
    group = "Windows",
    keys = "SUPER + SHIFT + F",
    run = hl.dsp.window.pin(),
}

bind {
    title = "Close window",
    group = "Windows",
    keys = "SUPER + SHIFT + Q",
    run = hl.dsp.window.close(),
}

bind {
    title = "Drag window",
    group = "Windows",
    keys = "SUPER + mouse:272",
    run = hl.dsp.window.drag(),
    mouse = true,
}

bind {
    title = "Resize with the mouse",
    group = "Windows",
    keys = "SUPER + mouse:273",
    run = hl.dsp.window.resize(),
    mouse = true,
}
