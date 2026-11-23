local terminal = "kitty"

hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })

hl.config({
    general = {
        gaps_in = 4,
        gaps_out = 8,
        border_size = 2,
        layout = "dwindle",
    },
    decoration = {
        rounding = 8,
    },
    input = {
        kb_layout = "us,ru",
        kb_options = "grp:alt_shift_toggle,caps:escape",
        numlock_by_default = true,
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

require("binds")({ terminal = terminal })

-- Profile overlays drop files here; load all of them, in name order.
local dir = os.getenv("HOME") .. "/.config/hypr/local"
local ls = io.popen('ls "' .. dir .. '"/*.lua 2>/dev/null')
if ls then
    for file in ls:lines() do dofile(file) end
    ls:close()
end
