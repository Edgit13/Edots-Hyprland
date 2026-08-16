#!/bin/bash
# gamemode.sh - toggle "Game Mode" for Hyprland
# Install to: ~/.config/quickshell/scripts/gamemode.sh
# chmod +x ~/.config/quickshell/scripts/gamemode.sh

STATE_DIR="$HOME/.cache/quickshell"
STATE_FILE="$STATE_DIR/gamemode.state"
mkdir -p "$STATE_DIR"

CURRENT=$(cat "$STATE_FILE" 2>/dev/null)

if [ "$CURRENT" = "1" ]; then
    # ---- OFF: restore normal desktop ----
    hyprctl keyword animations:enabled 1
    hyprctl keyword decoration:blur:enabled 1
    hyprctl keyword general:gaps_in 5
    hyprctl keyword general:gaps_out 10
    hyprctl keyword misc:vfr 1
    hyprctl keyword misc:no_direct_scanout false

    swaync-client -df >/dev/null 2>&1   # disable DND -> notifications back on

    # CPU governor back to balanced (needs a NOPASSWD sudoers/polkit rule
    # for cpupower, otherwise this will just silently fail/prompt)
    command -v cpupower >/dev/null 2>&1 && pkexec cpupower frequency-set -g schedutil >/dev/null 2>&1 &

    notify-send -a "GameMode" "Game Mode: OFF" "Animations & blur restored" -i input-gaming >/dev/null 2>&1

    echo "0" > "$STATE_FILE"
else
    # ---- ON: strip overhead, silence distractions ----
    hyprctl keyword animations:enabled 0
    hyprctl keyword decoration:blur:enabled 0
    hyprctl keyword general:gaps_in 0
    hyprctl keyword general:gaps_out 0
    hyprctl keyword misc:vfr 0
    hyprctl keyword misc:no_direct_scanout true

    swaync-client -dn >/dev/null 2>&1   # enable DND -> silence notifications

    # CPU governor to performance (same caveat as above)
    command -v cpupower >/dev/null 2>&1 && pkexec cpupower frequency-set -g performance >/dev/null 2>&1 &

    # optional: launch Feral GameMode daemon reference if you use `gamemoderun`
    # per-game instead, you can drop this line
    command -v gamemoded >/dev/null 2>&1 && gamemoded -r >/dev/null 2>&1 &

    notify-send -a "GameMode" "Game Mode: ON" "Animations off, notifications silenced" -i input-gaming >/dev/null 2>&1

    echo "1" > "$STATE_FILE"
fi
