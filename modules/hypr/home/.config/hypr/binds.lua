return function(apps)
    local mod = "SUPER"

    hl.bind(mod .. " + Return", hl.dsp.exec_cmd(apps.terminal))
    hl.bind(mod .. " + Q", hl.dsp.window.close())
    hl.bind(mod .. " + SHIFT + E", hl.dsp.exit())
    hl.bind(mod .. " + F", hl.dsp.window.fullscreen())
    hl.bind(mod .. " + V", hl.dsp.window.float({ action = "toggle" }))

    for key, dir in pairs({ H = "left", L = "right", K = "up", J = "down" }) do
        hl.bind(mod .. " + " .. key, hl.dsp.focus({ direction = dir }))
    end

    for i = 1, 9 do
        hl.bind(mod .. " + " .. i, hl.dsp.focus({ workspace = i }))
        hl.bind(mod .. " + SHIFT + " .. i, hl.dsp.window.move({ workspace = i }))
    end

    hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
    hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })
end
