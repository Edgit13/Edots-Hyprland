#!/bin/bash

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
pkill -f 'qs .*quickshell-mangowm/bar/shell.qml' 2>/dev/null || true
qs -p "$SCRIPT_DIR/shell.qml" >/dev/null 2>&1 &
