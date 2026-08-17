#!/bin/bash
# gamemode.sh - toggle "Game Mode" for Hyprland
# Based on the official Hyprland wiki technique (Uncommon tips & tricks):
# https://wiki.hypr.land/Configuring/Advanced-and-Cool/Uncommon-tips-and-tricks/
#
# Install to: ~/.config/quickshell/scripts/gamemode.sh
# chmod +x ~/.config/quickshell/scripts/gamemode.sh
#
# Called from: the bar's GameMode button AND the Super+F1 keybind
# (modules/binds.lua) — same script either way, so state never desyncs.

STATE_DIR="$HOME/.cache/quickshell"
STATE_FILE="$STATE_DIR/gamemode.state"
mkdir -p "$STATE_DIR"

CURRENTLY_ON=$(hyprctl getoption animations:enabled | awk 'NR==1{print $2}')

if [ "$CURRENTLY_ON" = "0" ]; then
    # ---- OFF: reload restores whatever YOUR config actually says for
    # gaps/rounding/border/blur/shadow — no guessed hardcoded values ----
    hyprctl reload

    swaync-client -df >/dev/null 2>&1   # disable DND -> notifications back on

    command -v cpupower >/dev/null 2>&1 && pkexec cpupower frequency-set -g schedutil >/dev/null 2>&1 &

    notify-send -a "GameMode" "Game Mode: OFF" "Config restored" -i input-gaming >/dev/null 2>&1

    echo "0" > "$STATE_FILE"
else
    # ---- ON: strip EVERYTHING that costs a frame — gaps, border,
    # animations, shadow, blur, and (importantly) rounding ----
    hyprctl --batch "\
        keyword general:gaps_in 0;\
        keyword general:gaps_out 0;\
        keyword general:border_size 0;\
        keyword animations:enabled 0;\
        keyword decoration:shadow:enabled 0;\
        keyword decoration:blur:enabled 0;\
        keyword decoration:rounding 0;\
        keyword misc:vfr 0;\
        keyword misc:no_direct_scanout true"

    swaync-client -dn >/dev/null 2>&1   # enable DND -> silence notifications

    command -v cpupower >/dev/null 2>&1 && pkexec cpupower frequency-set -g performance >/dev/null 2>&1 &

    command -v gamemoded >/dev/null 2>&1 && gamemoded -r >/dev/null 2>&1 &

    notify-send -a "GameMode" "Game Mode: ON" "Rounding, blur, shadow, gaps, border — all off" -i input-gaming >/dev/null 2>&1

    echo "1" > "$STATE_FILE"
fi
