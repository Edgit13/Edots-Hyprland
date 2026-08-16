hl.config({
    input = {
        kb_layout          = "us,ua",
        kb_options         = "grp:alt_space_toggle",
        follow_mouse       = 1,
        sensitivity        = -0.3,
        accel_profile      = "flat",
        repeat_rate        = 40,
        repeat_delay       = 400,
        numlock_by_default = true, -- Changed to true for your 100% keyboard
        touchpad = {
            natural_scroll = true,
        },
    },
    cursor = {
        no_hardware_cursors = true,
    },
})

hl.gesture({
    fingers = 3,
    direction = "horizontal",
    action = "workspace"
})

-- Example per-device config
-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Devices/ for more
hl.device({
    name        = "epic-mouse-v1",
    sensitivity = -0.5,
})
