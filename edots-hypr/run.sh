#!/usr/bin/env bash

# Отримуємо абсолютний шлях до папки зі скриптом
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Надаємо права на виконання для update.sh
chmod +x "$SCRIPT_DIR/update.sh"

# Запускаємо фоновий процес відстеження
"$SCRIPT_DIR/update.sh" &
