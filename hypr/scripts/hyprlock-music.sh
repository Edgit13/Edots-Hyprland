#!/usr/bin/env bash

if command -v playerctl &>/dev/null && playerctl status &>/dev/null; then
  status=$(playerctl status 2>/dev/null)
  artist=$(playerctl metadata artist 2>/dev/null)
  title=$(playerctl metadata title 2>/dev/null)

  # Іконка змінюється залежно від статусу (потребує Nerd Fonts)
  icon="󰎆"
  if [[ "$status" == "Playing" ]]; then
    icon="󰎈"
  fi

  pos=$(playerctl position 2>/dev/null)
  length_us=$(playerctl metadata mpris:length 2>/dev/null)

  bar=""
  if [[ -n "$pos" && -n "$length_us" && "$length_us" -gt 0 ]]; then
    length_s=$(echo "$length_us / 1000000" | bc -l 2>/dev/null)
    if [[ -n "$length_s" ]]; then
      percent=$(echo "$pos / $length_s * 100" | bc -l 2>/dev/null)
      percent=${percent%.*}
      [[ -z "$percent" ]] && percent=0
      ((percent < 0)) && percent=0
      ((percent > 100)) && percent=100

      # Налаштування вигляду повзунка (Material Design)
      total_chars=18 # Довжина повзунка
      filled_chars=$((percent * total_chars / 100))

      # Кольори для Pango Markup (зміни hex на свої улюблені)
      color_accent="#cba6f7" # Колір заповнення і кружечка
      color_track="#585b70"  # Колір порожньої лінії

      filled_str=""
      for ((i = 0; i < filled_chars; i++)); do filled_str+="━"; done

      empty_str=""
      for ((i = filled_chars + 1; i < total_chars; i++)); do empty_str+="─"; done

      thumb="●"

      # Збираємо повзунок з кольорами
      bar="<span foreground='${color_accent}'>${filled_str}${thumb}</span><span foreground='${color_track}'>${empty_str}</span>"
    fi
  fi

  label=""
  if [[ -n "$artist" && -n "$title" ]]; then
    # Назва пісні жирним, автор звичайним
    label="<b>$title</b> — $artist"
  elif [[ -n "$title" ]]; then
    label="<b>$title</b>"
  fi

  if [[ -n "$label" ]]; then
    if [[ -n "$bar" ]]; then
      echo "$icon  $label   $bar"
    else
      echo "$icon  $label"
    fi
  else
    echo ""
  fi
else
  echo ""
fi
