-- No hardware cursor under virtio-gpu; keep animations cheap.
hl.config({
    cursor = { no_hardware_cursors = true },
    animations = { enabled = false },
})
