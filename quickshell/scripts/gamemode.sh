#!/usr/bin/env bash
# gamemode.sh - toggle lightweight "Game Mode" for MangoWM/Quickshell

STATE_DIR="$HOME/.cache/quickshell"
STATE_FILE="$STATE_DIR/gamemode.state"
LOG_FILE="$STATE_DIR/gamemode.log"
mkdir -p "$STATE_DIR"

exec > >(tee -a "$LOG_FILE") 2>&1
echo "--- $(date) ---"

CURRENTLY_ON=$(cat "$STATE_FILE" 2>/dev/null)

if [ "$CURRENTLY_ON" = "1" ]; then
  swaync-client -df >/dev/null 2>&1 || true
  command -v cpupower >/dev/null 2>&1 && pkexec cpupower frequency-set -g schedutil >/dev/null 2>&1 &
  notify-send -a "GameMode" "Game Mode: OFF" "Restored default notification and CPU behavior" -i input-gaming >/dev/null 2>&1 || true
  echo "0" > "$STATE_FILE"
  exit 0
fi

swaync-client -dn >/dev/null 2>&1 || true
command -v cpupower >/dev/null 2>&1 && pkexec cpupower frequency-set -g performance >/dev/null 2>&1 &
command -v gamemoded >/dev/null 2>&1 && gamemoded -r >/dev/null 2>&1 &
notify-send -a "GameMode" "Game Mode: ON" "Notifications muted and performance governor requested" -i input-gaming >/dev/null 2>&1 || true
echo "1" > "$STATE_FILE"
