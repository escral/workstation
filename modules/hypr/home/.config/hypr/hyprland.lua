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
    },
    input = {
        kb_layout = "us,ru",
        kb_options = "grp:alt_shift_toggle,caps:escape",
        numlock_by_default = true,
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
    },
})

-- `uwsm app --` gives each long-running app its own systemd unit.
hl.on("hyprland.start", function()
    hl.exec_cmd("uwsm app -- quickshell")
end)

for id, name in pairs({ [1] = "Code", [2] = "Terminals", [3] = "AI", [9] = "Browser", [10] = "Chat" }) do
    hl.workspace_rule({ workspace = tostring(id), default_name = name })
end

-- Modules drop bindings into binds.d/, profiles drop overrides into local/.
local function load_dir(name)
    local dir = os.getenv("HOME") .. "/.config/hypr/" .. name
    local ls = io.popen('ls "' .. dir .. '"/*.lua 2>/dev/null')
    if not ls then return end
    for file in ls:lines() do dofile(file) end
    ls:close()
end

load_dir("binds.d")
load_dir("local")
