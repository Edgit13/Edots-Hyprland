#!/bin/sh

STATE_DIR="${HOME}/.cache/quickshell-mangowm"
STATE_FILE="${STATE_DIR}/gamemode.state"
mkdir -p "${STATE_DIR}"

current_state="0"
if [ -f "${STATE_FILE}" ]; then
    current_state=$(tr -d ' \n\r\t' < "${STATE_FILE}" 2>/dev/null)
fi

if [ "${current_state}" = "1" ]; then
    printf '0\n' > "${STATE_FILE}"
    notify-send -a "MangoWM" "Game Mode: OFF" "MangoWM fork stub disabled game mode" >/dev/null 2>&1 || true
    exit 0
fi

printf '1\n' > "${STATE_FILE}"
notify-send -a "MangoWM" "Game Mode: ON" "MangoWM fork stub enabled game mode" >/dev/null 2>&1 || true
exit 0
