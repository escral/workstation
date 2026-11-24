hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })

hl.config({
    general = {
        gaps_in = 4,
        gaps_out = 8,
        border_size = 2,
        layout = "dwindle",
        col = {
            active_border = { colors = { "rgba(7aa2f7ff)", "rgba(bb9af7ff)" }, angle = 45 },
            inactive_border = "rgba(292e42ff)",
        },
    },
    decoration = {
        rounding = 10,
        -- Focus reads from brightness, not only the border.
        inactive_opacity = 0.92,
        dim_inactive = true,
        dim_strength = 0.12,
        blur = { enabled = true, size = 8, passes = 3 },
    },
    input = {
        kb_layout = "us,ru",
        kb_options = "grp:alt_shift_toggle,caps:escape",
        numlock_by_default = true,
        repeat_delay = 400,
    },
    group = {
        col = {
            border_active = { colors = { "rgba(7aa2f7ff)", "rgba(bb9af7ff)" }, angle = 45 },
            border_inactive = "rgba(292e42ff)",
        },
        groupbar = {
            font_family = "FiraCode Nerd Font",
            font_size = 10,
            height = 18,
            gradients = true,
            col = {
                active = "rgba(7aa2f7ff)",
                inactive = "rgba(292e42ff)",
            },
            text_color = "rgba(1a1b26ff)",
            text_color_inactive = "rgba(a9b1d6ff)",
        },
    },
    binds = {
        movefocus_cycles_groupfirst = true,
    },
    misc = {
        force_default_wallpaper = 0,
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
        -- The Quickshell lock screen fades over the desktop, so Hyprland must
        -- draw what is under its transparent surface.
        session_lock_xray = true,
        -- A restarted Quickshell can take the lock over again after a crash.
        allow_session_lock_restore = true,
    },
})

-- Moves and resizes run on a stiff spring (damping ~0.87 of critical: a hint
-- of settle, no wobble). Fades and closing use a fixed ease-out.
hl.curve("outQuint", { type = "bezier", points = { {0.23, 1}, {0.32, 1} } })
hl.curve("spring", { type = "spring", mass = 1, stiffness = 600, damping = 43 })
hl.animation({ leaf = "global", enabled = true, speed = 4, spring = "spring" })
hl.animation({ leaf = "windows", enabled = true, speed = 4, spring = "spring" })
-- A new window slides in from the nearest screen edge, as if pushing the one
-- it splits from aside; the rule below makes a lone window pop in instead.
hl.animation({ leaf = "windowsIn", enabled = true, speed = 4, spring = "spring", style = "slide" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 1, bezier = "outQuint", style = "popin 90%" })
-- Mostly visible within the first frames, then eases out over about as long
-- as the neighbour takes to shrink, so the two read as one motion.
hl.animation({ leaf = "fadeIn", enabled = true, speed = 2, bezier = "outQuint" })
hl.animation({ leaf = "fadeOut", enabled = true, speed = 1, bezier = "outQuint" })
-- Switching workspaces should feel instant; a short fade only softens it.
hl.animation({ leaf = "workspaces", enabled = true, speed = 1, bezier = "outQuint", style = "fade" })
hl.animation({ leaf = "layers", enabled = true, speed = 1.2, bezier = "outQuint", style = "fade" })
hl.window_rule({
    name = "popin-when-alone",
    match = { workspace = "w[tv1]" },
    animation = "popin 85%",
})

-- `uwsm app --` gives each long-running app its own systemd unit.
hl.on("hyprland.start", function()
    hl.exec_cmd("uwsm app -- quickshell")
end)

for id, name in pairs({ [1] = "Code", [2] = "Terminals", [3] = "AI", [9] = "Browser", [10] = "Chat" }) do
    hl.workspace_rule({ workspace = tostring(id), default_name = name })
end

-- Where apps open. Rules for apps that aren't installed cost nothing, so the
-- list covers likely future apps too. Chat apps start in the background, so
-- they stay silent; the rest take focus along with them.
local function place(name, class, workspace)
    hl.window_rule({ name = name, match = { initial_class = class }, workspace = workspace })
end
place("vscode", "(?i)^(code|code-oss|com\\.microsoft\\.vscode|vscodium|codium)$", "1")
place("jetbrains", "^jetbrains-(idea|idea-ce|webstorm|phpstorm|pycharm|pycharm-ce|goland|rider|clion|rustrover|datagrip|rubymine)$", "1")
place("zed", "^dev\\.zed\\.Zed$", "1")
place("claude", "^com\\.anthropic\\.Claude$", "3")
place("cursor", "(?i)^cursor$", "3")
place("windsurf", "(?i)^windsurf$", "3")
place("chrome", "^(google-chrome|chromium)$", "9")
place("firefox", "^firefox$", "9")
place("telegram", "^org\\.telegram\\.desktop$", "10 silent")
place("slack", "(?i)^slack$", "10 silent")
place("discord", "(?i)^(discord|vesktop)$", "10 silent")

-- Modules drop hotkeys and launcher actions into actions.d/ (catalog.lua)
-- and app autostart into apps.d/; profiles drop overrides into local/.
dofile(os.getenv("HOME") .. "/.config/hypr/catalog.lua")

local function load_dir(name)
    local dir = os.getenv("HOME") .. "/.config/hypr/" .. name
    local ls = io.popen('ls "' .. dir .. '"/*.lua 2>/dev/null')
    if not ls then return end
    for file in ls:lines() do dofile(file) end
    ls:close()
end

load_dir("actions.d")
load_dir("apps.d")
load_dir("local")
catalog_export()
