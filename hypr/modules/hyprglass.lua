-- HyprGlass (liquid-glass plugin) config.
-- Safe to require even if the plugin isn't loaded/enabled — the guard
-- below just no-ops. Toggled at runtime by the "Сучасний" menu item
-- in the Quickshell bar, which runs `hyprpm enable/disable hyprglass`.
--
-- One-time setup (once per machine):
--   hyprpm add https://github.com/hyprnux/hyprglass
--   uncomment hl.permission(...) for hyprpm in hyprland.lua, restart Hyprland

if hl.plugin.hyprglass then
    local hg = hl.plugin.hyprglass

    hg.config({
        default_theme  = "dark",
        default_preset = "clear",

        -- Teal tint matching the Ricelin accent (Colors.qml's fallback #3dd1b0)
        tint_color = 0x3dd1b022,

        brightness = 0.9,
        dark  = { brightness = 0.82 },
        light = { adaptive_boost = 0.5 },

        -- Glass on layer surfaces (bar, notifications), not just windows
        layers = { enabled = 1 },
    })

    -- Quickshell bar + its dropdown panels (Menu, Power, Tray, Clipboard, Wallpaper).
    -- These all sit on the "quickshell" layer namespace by default — check with
    -- `hyprctl layers` and adjust the namespace string below if yours differs.
    hg.layer("quickshell", { preset = "subtle", mask_threshold = 0.05 })

    -- swaync notification popups
    hg.layer("swaync", { preset = "subtle", mask_threshold = 0.05 })

    -- Presets tuned for the Ricelin dark palette
    hg.preset("clear", {
        glass_opacity = 0.8,
        blur_strength = 1.5,
        dark  = { brightness = 0.7 },
        light = { brightness = 1.2 },
    })

    hg.preset("subtle", {
        glass_opacity = 0.6,
        blur_strength = 1.0,
        refraction_strength = 0.3,
        dark = { brightness = 0.85 },
    })

    -- Skip the effect on things where it'd just be noise
    hl.window_rule({ match = { class = "mpv" },     tag = "+hyprglass_disabled" })
    hl.window_rule({ match = { fullscreen = true }, tag = "+hyprglass_disabled" })
end

