-- Super+? opens the help and Esc (or Super+? again) closes it. While it is
-- up, the held modifiers mark what they reach. The state goes to a file the
-- help watches: writes keep their order, where separate ipc calls could
-- arrive out of turn and leave it on screen.
--
-- ignore_mods: a modifier's own press and release come with other modifiers
-- already in the mask. transparent: a plain release bind does not fire after
-- a combo like Super+H.

local state = (os.getenv("XDG_RUNTIME_DIR") or "/tmp") .. "/ws-help"
local held = { SUPER = false, SHIFT = false, CTRL = false, ALT = false }
local open = false

local function write()
    local mods = {}
    for _, m in ipairs({ "SUPER", "SHIFT", "CTRL", "ALT" }) do
        if held[m] then
            mods[#mods + 1] = m
        end
    end
    local f = io.open(state, "w")
    if f then
        f:write(open and "open " .. table.concat(mods, ",") or "closed")
        f:close()
    end
end

-- Shift goes up and down all through typing; only an open help cares.
local function update()
    if open then
        write()
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

    hl.bind(key, function()
        held[mod] = false
        update()
    end, { release = true, non_consuming = true, transparent = true, ignore_mods = true })
end

-- By keycode: with Shift held the key's symbol is "question", which a bind
-- by name does not match.
hl.bind("SUPER + SHIFT + code:61", function()
    open = not open
    write()
end)

hl.bind("Escape", function()
    if open then
        open = false
        write()
    end
end, { non_consuming = true })

write()

bind {
    title = "This help, Esc closes",
    group = "Launcher",
    keys = "SUPER + ?",
}
