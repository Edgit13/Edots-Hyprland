#!/bin/bash

pkill -f 'qs .*quickshell-mangowm/bar/shell.qml' 2>/dev/null || true
qs -p "$HOME/.config/quickshell-mangowm/bar" >/dev/null 2>&1 &
