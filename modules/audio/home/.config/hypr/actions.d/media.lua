bind {
    title = "Volume up",
    group = "Media",
    keys = "XF86AudioRaiseVolume",
    run = "wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+",
    locked = true,
    repeating = true,
}

bind {
    title = "Volume down",
    group = "Media",
    keys = "XF86AudioLowerVolume",
    run = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-",
    locked = true,
    repeating = true,
}

bind {
    title = "Mute",
    group = "Media",
    keys = "XF86AudioMute",
    run = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle",
    locked = true,
}
