# Swaylock style notes

This lockscreen is tuned for a glass/minimal look using `swaylock-effects`.

## Current visual direction

- current wallpaper as fullscreen background
- strong blur for depth
- grayscale + vignette for focus
- large centered clock
- low-noise transparent indicator ring
- palette-driven colors generated from `mango/scripts/wallcolors.py`

## Dynamic helpers

Helper scripts are available at:

- `~/.config/mango/scripts/swaylock-weather.sh`
- `~/.config/mango/scripts/swaylock-music.sh`
- `~/.config/mango/scripts/swaylock-status.sh`

If your installed `swaylock-effects` build supports extra label/text overlays beyond the currently used directives, these can be plugged in to show weather/media directly on the lockscreen.
