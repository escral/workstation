-- The help shows once Super is held past the key repeat delay (a long_press
-- bind, so quick combos never show it), and lights up what the other held
-- modifiers reach. They are tracked here and reach Quickshell only while the
-- help is up: Shift goes up and down all through typing.
--
-- ignore_mods: a modifier's own press and release come with other modifiers
-- already in the mask. transparent: a plain release bind does not fire after
-- a combo like Super+H, which would leave the help on screen.

local held = { SUPER = false, SHIFT = false, CTRL = false, ALT = false }
local open = false

local function send(call)
    hl.exec_cmd("quickshell ipc call help " .. call)
end

local function update()
    if not open then
        return
    end
    local mods = {}
    for _, m in ipairs({ "SHIFT", "CTRL", "ALT" }) do
        if held[m] then
            mods[#mods + 1] = m
        end
    end
    send("hold " .. (#mods > 0 and table.concat(mods, ",") or "none"))
end

local function long_press()
    if held.SUPER then
        open = true
        update()
    end
end

local keys = {
    Super_L = "SUPER",
    Shift_L = "SHIFT",
    Shift_R = "SHIFT",
    Control_L = "CTRL",
    Control_R = "CTRL",
    Alt_L = "ALT",
}

for key, mod in pairs(keys) do
    hl.bind(key, function()
        held[mod] = true
        update()
    end, { non_consuming = true, transparent = true, ignore_mods = true })

    hl.bind(key, long_press, { long_press = true, non_consuming = true, ignore_mods = true })

    hl.bind(key, function()
        held[mod] = false
        if mod ~= "SUPER" then
            return update()
        end
        if open then
            send("release")
        end
        open = false
    end, { release = true, non_consuming = true, transparent = true, ignore_mods = true })
end

bind {
    title = "This help: hold Super",
    group = "Launcher",
    keys = "SUPER",
}
