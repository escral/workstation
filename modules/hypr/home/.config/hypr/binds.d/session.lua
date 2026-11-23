local mod = "SUPER"

hl.bind(mod .. " + SHIFT + C", hl.dsp.reload_config())

-- Exit asks first: Y confirms, anything else cancels.
hl.bind(mod .. " + SHIFT + E", function()
    hl.notification.create({ text = "Exit Hyprland?  Y to confirm, any other key cancels", duration = 5000 })
    hl.dispatch(hl.dsp.submap("exit"))
end)
hl.define_submap("exit", function()
    hl.bind("Y", hl.dsp.exit())
    hl.bind("catchall", hl.dsp.submap("reset"))
end)
