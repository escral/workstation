-- Super+/ opens the help and Esc (or Super+/ again) closes it. While it is
-- up, the modifiers pressed since mark what they reach. The state goes to a
-- file the help watches: writes keep their order, so a close can't land
-- before the open it follows.
--
-- Keys go by keycode: Alt+Shift switches the layout here, and then one of
-- the two reports ISO_Next_Group instead of its own name, so a release bound
-- by name never comes. ignore_mods: a modifier's own press and release come
-- with other modifiers already in the mask. transparent: a plain release
-- bind does not fire after a combo like Super+H.

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
    ["code:133"] = "SUPER", -- Super_L
    ["code:50"] = "SHIFT", -- Shift_L
    ["code:62"] = "SHIFT", -- Shift_R
    ["code:37"] = "CTRL", -- Control_L
    ["code:105"] = "CTRL", -- Control_R
    ["code:64"] = "ALT", -- Alt_L
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

-- The keys that open it are still held, so nothing is lit until the next
-- press. With Shift too, as Super+?: by keycode, since the key's symbol is
-- then "question", which a bind by name does not match.
local function toggle()
    open = not open
    for m in pairs(held) do
        held[m] = false
    end
    write()
end
hl.bind("SUPER + code:61", toggle)
hl.bind("SUPER + SHIFT + code:61", toggle)

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
    keys = "SUPER + /",
}
