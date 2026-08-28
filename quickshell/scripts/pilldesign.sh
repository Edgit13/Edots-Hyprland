#!/bin/bash
# pilldesign.sh - toggle "Pill" bar design (hover-grow + glow, натхненний
# github.com/Gakuseei/Ricelin) проти дефолтного Notch-вигляду.
#
# Install to: ~/.config/quickshell/scripts/pilldesign.sh
# chmod +x ~/.config/quickshell/scripts/pilldesign.sh

STATE_DIR="$HOME/.cache/quickshell"
STATE_FILE="$STATE_DIR/pilldesign.state"
mkdir -p "$STATE_DIR"

CURRENT=$(cat "$STATE_FILE" 2>/dev/null || echo "0")

if [ "$CURRENT" = "1" ]; then
    echo "0" > "$STATE_FILE"
    notify-send -a "Дизайн" "Дизайн бару: Notch" -i preferences-desktop-theme >/dev/null 2>&1
else
    echo "1" > "$STATE_FILE"
    notify-send -a "Дизайн" "Дизайн бару: Pill" -i preferences-desktop-theme >/dev/null 2>&1
fi
