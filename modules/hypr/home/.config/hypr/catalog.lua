-- Files in actions.d/ declare bind{} (a hotkey the help lists) or action{}
-- (something to find in the launcher; a hotkey too when it has keys).
-- Hyprland binds the keys, and writes the list to ~/.cache/ws/actions.json
-- for the launcher and the help, which run an entry with
-- `hyprctl dispatch 'ws_action("<title>")'`.
--
--   title     unique; what the help and the launcher show
--   keys      "SUPER + C", or a list of them
--   run       a shell command, a hl.dsp dispatcher or a function. Without it
--             the entry only documents keys bound elsewhere: an app's own,
--             or a loop over workspaces.
--   terminal  runs the command in a window that stays open to read
--   group, glyph, words   how the launcher and the help sort, mark and find it
--   app       the window class whose keys these are, for the help
--   launcher, help        where it shows up, when the default is wrong
--   locked, repeating, mouse   passed on to hl.bind

local entries, by_title, by_keys = {}, {}, {}

local function warn(text)
    hl.notification.create({ text = "actions: " .. text, duration = 10000 })
end

local function quote(s)
    return "'" .. s:gsub("'", "'\\''") .. "'"
end

local function dispatcher(e)
    if type(e.run) ~= "string" then
        return e.run
    end
    return hl.dsp.exec_cmd(e.terminal and "term-run " .. quote(e.run) or e.run)
end

local function add(e, kind)
    if not e.title then
        return warn("an entry has no title")
    end
    if by_title[e.title] then
        return warn("two entries are titled " .. e.title)
    end
    e.kind = kind
    e.keys = type(e.keys) == "table" and e.keys or { e.keys }
    if e.launcher == nil then e.launcher = kind == "action" end
    if e.help == nil then e.help = #e.keys > 0 end
    by_title[e.title] = e
    entries[#entries + 1] = e
    if not e.run then
        return
    end
    for _, k in ipairs(e.keys) do
        local norm = k:upper():gsub("%s+", "")
        if by_keys[norm] then
            warn(k .. " is bound twice: " .. by_keys[norm] .. ", " .. e.title)
        end
        by_keys[norm] = e.title
        hl.bind(k, dispatcher(e), { locked = e.locked, repeating = e.repeating, mouse = e.mouse })
    end
end

function bind(e) add(e, "bind") end
function action(e) add(e, "action") end

function ws_action(title)
    local e = by_title[title]
    if e and e.run then
        return dispatcher(e)
    end
    return function() warn("nothing to run for " .. tostring(title)) end
end

local function json(v)
    local t = type(v)
    if t == "string" then
        return '"' .. (v:gsub('[%c"\\]', function(c) return string.format("\\u%04x", c:byte()) end)) .. '"'
    elseif t == "table" then
        local out = {}
        if v[1] ~= nil or next(v) == nil then
            for _, x in ipairs(v) do out[#out + 1] = json(x) end
            return "[" .. table.concat(out, ",") .. "]"
        end
        for k, x in pairs(v) do out[#out + 1] = json(k) .. ":" .. json(x) end
        return "{" .. table.concat(out, ",") .. "}"
    end
    return tostring(v)
end

function catalog_export()
    local rows = {}
    for _, e in ipairs(entries) do
        rows[#rows + 1] = {
            title = e.title, kind = e.kind, keys = e.keys, runs = e.run ~= nil,
            group = e.group or "", glyph = e.glyph or "", words = e.words or {},
            app = e.app or "", launcher = e.launcher, help = e.help,
        }
    end
    local dir = (os.getenv("XDG_CACHE_HOME") or os.getenv("HOME") .. "/.cache") .. "/ws"
    os.execute('mkdir -p "' .. dir .. '"')
    -- Written aside and renamed, so a reader never sees half a file.
    local f = assert(io.open(dir .. "/actions.json.tmp", "w"))
    f:write(json(rows))
    f:close()
    os.rename(dir .. "/actions.json.tmp", dir .. "/actions.json")
end
