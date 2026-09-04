#!/usr/bin/env bash

# Шлях до файлу кольорів GTK4
TARGET_FILE="$HOME/.config/gtk-4.0/gtk-colors.css"

# Очікуємо створення файлу, якщо його ще немає
while [ ! -f "$TARGET_FILE" ]; do
  sleep 1
done

# Якщо встановлено inotifywait (з пакета inotify-tools), використовуємо події файлової системи
if command -v inotifywait &>/dev/null; then
  inotifywait -q -m -e close_write "$TARGET_FILE" | while read -r path event file; do
    # Невелика затримка для гарантованого збереження файлу
    sleep 0.3
    # Перезапускаємо Nautilus для підхоплення нових стилів
    nautilus -q &>/dev/null
  done
else
  # Резервний метод опитування через stat, якщо inotifywait відсутній
  LAST_MOD=0
  while true; do
    if [ -f "$TARGET_FILE" ]; then
      CURRENT_MOD=$(stat -c %Y "$TARGET_FILE" 2>/dev/null || echo 0)
      if [ "$CURRENT_MOD" -ne "$LAST_MOD" ] && [ "$LAST_MOD" -ne 0 ]; then
        sleep 0.3
        nautilus -q &>/dev/null
      fi
      LAST_MOD=$CURRENT_MOD
    fi
    sleep 2
  done
fi
