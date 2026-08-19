-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------

-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Environment-variables/

hl.env("HYPRCURSOR_THEME", "Moga-Black")
hl.env("HYPRCURSOR_SIZE", "24")

-- Dolphin/Qt-застосунки: без цього Qt рендерить дефолтним стилем (Fusion)
-- і повністю ігнорує kdeglobals-кольори, незалежно від того, що там записано.
hl.env("QT_QPA_PLATFORMTHEME", "kde")
hl.env("QT_STYLE_OVERRIDE", "breeze")
