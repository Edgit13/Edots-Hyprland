#!/usr/bin/env bash

if command -v playerctl >/dev/null 2>&1 && playerctl status >/dev/null 2>&1; then
  status=$(playerctl status 2>/dev/null)
  artist=$(playerctl metadata artist 2>/dev/null)
  title=$(playerctl metadata title 2>/dev/null)

  icon="󰎆"
  if [ "$status" = "Playing" ]; then
    icon="󰎈"
  fi

  pos=$(playerctl position 2>/dev/null)
  length_us=$(playerctl metadata mpris:length 2>/dev/null)

  bar=""
  if [ -n "$pos" ] && [ -n "$length_us" ] && [ "$length_us" -gt 0 ] 2>/dev/null; then
    length_s=$(echo "$length_us / 1000000" | bc -l 2>/dev/null)
    if [ -n "$length_s" ]; then
      percent=$(echo "$pos / $length_s * 100" | bc -l 2>/dev/null)
      percent=${percent%.*}
      [ -z "$percent" ] && percent=0
      [ "$percent" -lt 0 ] 2>/dev/null && percent=0
      [ "$percent" -gt 100 ] 2>/dev/null && percent=100

      total_chars=18
      filled_chars=$((percent * total_chars / 100))

      color_accent="#cba6f7"
      color_track="#585b70"

      filled_str=""
      i=0
      while [ "$i" -lt "$filled_chars" ]; do
        filled_str="${filled_str}━"
        i=$((i + 1))
      done

      empty_str=""
      i=$((filled_chars + 1))
      while [ "$i" -lt "$total_chars" ]; do
        empty_str="${empty_str}─"
        i=$((i + 1))
      done

      thumb="●"
      bar="<span foreground='${color_accent}'>${filled_str}${thumb}</span><span foreground='${color_track}'>${empty_str}</span>"
    fi
  fi

  label=""
  if [ -n "$artist" ] && [ -n "$title" ]; then
    label="<b>$title</b> — $artist"
  elif [ -n "$title" ]; then
    label="<b>$title</b>"
  fi

  if [ -n "$label" ]; then
    if [ -n "$bar" ]; then
      printf '%s\n' "$icon  $label   $bar"
    else
      printf '%s\n' "$icon  $label"
    fi
  else
    printf '\n'
  fi
else
  printf '\n'
fi
