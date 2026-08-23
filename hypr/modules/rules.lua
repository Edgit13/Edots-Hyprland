-- Window rules
hl.window_rule({
  name  = "suppress-maximize-events",
  match = { class = ".*" },
  suppress_event = "maximize",
})

hl.window_rule({
  name  = "fix-xwayland-drags",
  match = { class="^$", title="^$", xwayland=true, float=true, fullscreen=false, pin=false },
  no_focus = true,
})

hl.window_rule({
  name  = "move-hyprland-run",
  match = { class = "hyprland-run" },
  move  = "20 monitor_h-120",
  float = true,
})

-- Ghostty на Hyprland ігнорує власний background-opacity (відомий баг
-- альфа-каналу в GTK-білді під Wayland) — форсуємо прозорість напряму
-- через Hyprland замість покладатись на ghostty/config.
--
-- ВАЖЛИВО: Hyprland-опасіті блендить ВСЕ вікно цілком (текст теж), на
-- відміну від нативного background-opacity терміналів (той мав би чіпати
-- лише фон). Тому тримаємо opacity високою (0.90) — текст лишається
-- яскравим/читабельним. "Скляність" дає глобальний blur з decorations.lua
-- (blur.enabled = true), він і так застосовується до всіх вікон автоматично —
-- окреме blur-правило тут не потрібне (Hyprland не дозволяє міняти
-- size/passes per-window, тільки увімкнути/вимкнути через no_blur).
hl.window_rule({
  name  = "ghostty-opacity",
  match = { class = "com.mitchellh.ghostty" },
  opacity = "0.90 0.90",
})