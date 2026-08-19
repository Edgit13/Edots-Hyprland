#!/usr/bin/bash
set -e

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

alacritty --command bash -lc "./$SCRIPT_DIR/bup.sh"
