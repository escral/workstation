-- Shown once Super is held past the key repeat delay. The release bind is
-- transparent: a plain one does not fire after a combo like Super+H, which
-- would leave the help on screen.
hl.bind("Super_L", hl.dsp.exec_cmd("quickshell ipc call help hold"), { long_press = true, non_consuming = true })
hl.bind("Super_L", hl.dsp.exec_cmd("quickshell ipc call help release"), { release = true, transparent = true, non_consuming = true })

bind {
    title = "This help: hold Super",
    group = "Launcher",
    keys = "SUPER",
}
