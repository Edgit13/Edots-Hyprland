hl.monitor({
    output   = "HDMI-A-1",
    mode     = "preferred",
    position = "0x0",
    scale    = 1,
})

hl.monitor({
    output   = "eDP-1",
    mode     = "preferred",
    position = "auto-right",
    scale    = 1,
})

-- HDMI-A-1 (main): workspaces 1–5
for i = 1, 5 do
    hl.workspace_rule({ workspace = tostring(i), monitor = "HDMI-A-1" })
end

-- eDP-1 (laptop): workspaces 6–10
for i = 6, 10 do
    hl.workspace_rule({ workspace = tostring(i), monitor = "eDP-1" })
end
