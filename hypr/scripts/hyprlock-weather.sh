#!/usr/bin/env bash
curl -s --max-time 3 "wttr.in/?format=%c+%t" 2>/dev/null || echo "—"
