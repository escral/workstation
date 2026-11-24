hl.config({
    general = {
        col = {
            active_border = { colors = { "rgba({{accent}}ff)", "rgba({{magenta}}ff)" }, angle = 45 },
            inactive_border = "rgba({{highlight}}ff)",
        },
    },
    group = {
        col = {
            border_active = { colors = { "rgba({{accent}}ff)", "rgba({{magenta}}ff)" }, angle = 45 },
            border_inactive = "rgba({{highlight}}ff)",
        },
        groupbar = {
            col = {
                active = "rgba({{accent}}ff)",
                inactive = "rgba({{highlight}}ff)",
            },
            text_color = "rgba({{bg}}ff)",
            text_color_inactive = "rgba({{subtext}}ff)",
        },
    },
})
