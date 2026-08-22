#!/bin/bash
# modernmode.sh - toggle "Modern" (HyprGlass liquid-glass) theme
#
# One-time setup, run once manually before using this button:
#   hyprpm add https://github.com/hyprnux/hyprglass
#
# Install to: ~/.config/quickshell/scripts/modernmode.sh
# chmod +x ~/.config/quickshell/scripts/modernmode.sh

STATE_DIR="$HOME/.cache/quickshell"
STATE_FILE="$STATE_DIR/modernmode.state"
mkdir -p "$STATE_DIR"

# Make sure the plugin was actually added via hyprpm first
if ! hyprpm list 2>/dev/null | grep -q "Plugin hyprglass"; then
    notify-send -a "Modern" "HyprGlass not installed" \
        "Run: hyprpm add https://github.com/hyprnux/hyprglass" \
        -u critical >/dev/null 2>&1
    echo "0" > "$STATE_FILE"
    exit 1
fi

# Ask hyprpm for ground truth instead of trusting our own state file
CURRENTLY_ENABLED=$(hyprpm list | grep -A1 "Plugin hyprglass" | grep -oP 'enabled:\s*\K(true|false)')

if [ "$CURRENTLY_ENABLED" = "true" ]; then
    # ---- OFF ----
    hyprpm disable hyprglass >/dev/null 2>&1
    notify-send -a "Modern" "Modern Mode: OFF" "HyprGlass disabled" \
        -i preferences-desktop-theme >/dev/null 2>&1
    echo "0" > "$STATE_FILE"
else
    # ---- ON ----
    hyprpm enable hyprglass >/dev/null 2>&1
    notify-send -a "Modern" "Modern Mode: ON" "HyprGlass liquid-glass enabled" \
        -i preferences-desktop-theme >/dev/null 2>&1
    echo "1" > "$STATE_FILE"
fi
