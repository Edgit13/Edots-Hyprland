#!/bin/bash

pkill -f 'qs .*bar/shell.qml' 2>/dev/null || true
qs -c bar &
