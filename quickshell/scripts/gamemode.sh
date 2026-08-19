#!/bin/bash
# gamemode.sh - toggle "Game Mode" for Hyprland (Lua-config build)
#
# Your Hyprland uses the Lua config parser (hyprland.lua), which REJECTS
# `hyprctl keyword` entirely ("keyword can't work with non-legacy parsers.
# Use eval."). Everything here goes through `hyprctl eval` and Lua's
# hl.config({...}) table syntax instead.
#
# ON/OFF state is tracked via our own state file (not by querying Hyprland
# live) — hyprctl getoption -j didn't reliably parse in testing, and we
# already fully control the state file, so it's the more trustworthy source.
#
# Install to: ~/.config/quickshell/scripts/gamemode.sh
# chmod +x ~/.config/quickshell/scripts/gamemode.sh

STATE_DIR="$HOME/.cache/quickshell"
STATE_FILE="$STATE_DIR/gamemode.state"
SNAPSHOT_FILE="$STATE_DIR/gamemode_snapshot.env"
LOG_FILE="$STATE_DIR/gamemode.log"
mkdir -p "$STATE_DIR"

exec > >(tee -a "$LOG_FILE") 2>&1
echo "--- $(date) ---"

# Reads a live Lua config value, e.g. get_val general.gaps_in
get_val() {
    hyprctl getoption "$1" | awk '
        /^(int|float|bool|str):/ { print $2; exit }
        /css gap data:/ { print $4; exit }
    '
}

CURRENTLY_ON=$(cat "$STATE_FILE" 2>/dev/null)

if [ "$CURRENTLY_ON" = "1" ]; then
    # ---- OFF: restore the exact values captured before turning on ----
    if [ -f "$SNAPSHOT_FILE" ]; then
        source "$SNAPSHOT_FILE"
        hyprctl eval "hl.config({
            general = { gaps_in = ${SNAP_GAPS_IN:-5}, gaps_out = ${SNAP_GAPS_OUT:-10}, border_size = ${SNAP_BORDER:-1} },
            animations = { enabled = ${SNAP_ANIM:-1} },
            decoration = {
                shadow = { enabled = ${SNAP_SHADOW:-1} },
                blur = { enabled = ${SNAP_BLUR:-1} },
                rounding = ${SNAP_ROUNDING:-30},
            },
            misc = {},
        })"
        rm -f "$SNAPSHOT_FILE"
    else
        # No snapshot (e.g. first-ever run got interrupted) — fall back to
        # your actual real defaults from decorations.lua as a safety net.
        hyprctl eval "hl.config({
            general = { gaps_in = 5, gaps_out = 10, border_size = 1 },
            animations = { enabled = 1 },
            decoration = { shadow = { enabled = 1 }, blur = { enabled = 1 }, rounding = 30 },
            misc = {},
        })"
    fi

    swaync-client -df >/dev/null 2>&1
    command -v cpupower >/dev/null 2>&1 && pkexec cpupower frequency-set -g schedutil >/dev/null 2>&1 &
    notify-send -a "GameMode" "Game Mode: OFF" "Restored captured values" -i input-gaming >/dev/null 2>&1

    echo "0" > "$STATE_FILE"
else
    # ---- ON: capture live values FIRST, then zero everything out ----
    {
        echo "SNAP_GAPS_IN=$(get_val general:gaps_in)"
        echo "SNAP_GAPS_OUT=$(get_val general:gaps_out)"
        echo "SNAP_BORDER=$(get_val general:border_size)"
        echo "SNAP_ANIM=$(get_val animations:enabled)"
        echo "SNAP_SHADOW=$(get_val decoration:shadow:enabled)"
        echo "SNAP_BLUR=$(get_val decoration:blur:enabled)"
        echo "SNAP_ROUNDING=$(get_val decoration:rounding)"
    } > "$SNAPSHOT_FILE"

    cat "$SNAPSHOT_FILE"   # goes into the log, so we can see what got captured

    hyprctl eval "hl.config({
        general = { gaps_in = 0, gaps_out = 0, border_size = 0 },
        animations = { enabled = 0 },
        decoration = { shadow = { enabled = 0 }, blur = { enabled = 0 }, rounding = 0 },
        misc = {},
    })"

    swaync-client -dn >/dev/null 2>&1
    command -v cpupower >/dev/null 2>&1 && pkexec cpupower frequency-set -g performance >/dev/null 2>&1 &
    command -v gamemoded >/dev/null 2>&1 && gamemoded -r >/dev/null 2>&1 &
    notify-send -a "GameMode" "Game Mode: ON" "Rounding, blur, shadow, gaps, border — all off" -i input-gaming >/dev/null 2>&1

    echo "1" > "$STATE_FILE"
fi
