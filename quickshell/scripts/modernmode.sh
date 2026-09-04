#!/bin/bash
# modernmode.sh - toggle a local visual mode flag for Quickshell

STATE_DIR="$HOME/.cache/quickshell"
STATE_FILE="$STATE_DIR/modernmode.state"
mkdir -p "$STATE_DIR"

CURRENTLY_ON=$(cat "$STATE_FILE" 2>/dev/null)

if [ "$CURRENTLY_ON" = "1" ]; then
    echo "0" > "$STATE_FILE"
    notify-send -a "Modern" "Modern Mode: OFF" "Stored Quickshell visual mode disabled" \
        -i preferences-desktop-theme >/dev/null 2>&1 || true
else
    echo "1" > "$STATE_FILE"
    notify-send -a "Modern" "Modern Mode: ON" "Stored Quickshell visual mode enabled" \
        -i preferences-desktop-theme >/dev/null 2>&1 || true
fi
