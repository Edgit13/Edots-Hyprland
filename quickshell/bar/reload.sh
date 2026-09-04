#!/bin/bash

pkill -f 'qs .*bar/shell.qml' 2>/dev/null || true
qs -p "$HOME/.config/quickshell/bar/shell.qml" >/dev/null 2>&1 &
