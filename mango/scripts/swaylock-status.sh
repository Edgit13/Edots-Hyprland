#!/usr/bin/env bash

weather=$("$HOME/.config/mango/scripts/swaylock-weather.sh" 2>/dev/null)
music=$("$HOME/.config/mango/scripts/swaylock-music.sh" 2>/dev/null)

[ -z "$weather" ] && weather="Weather unavailable"
[ -z "$music" ] && music="No media playing"

printf '%s\n%s\n' "$weather" "$music"
