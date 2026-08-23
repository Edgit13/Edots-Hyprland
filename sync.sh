#!/usr/bin/env bash
#
# sync.sh — синхронізатор Edots-Hyprland
#
# Лінкує конфіги з репозиторію напряму в ~/.config через symlink.
# Завдяки цьому редагування файлу в репо (~/Dotfiles/...) і в
# ~/.config/... — це редагування ОДНОГО й того самого файлу.
# Ручне копіювання в дві теки більше не потрібне.
#
# Використання:
#   ./sync.sh install   — створити symlink'и (з бекапом старих конфігів)
#   ./sync.sh status     — показати стан кожного конфігу
#   ./sync.sh unlink      — прибрати symlink'и, повернути з .bak (якщо є)
#
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
BACKUP_DIR="$HOME/.config-backup-$(date +%Y%m%d-%H%M%S)"

# формат: "шлях_у_репо:ціль_symlink'у"
LINKS=(
  "alacritty:$CONFIG_HOME/alacritty"
  "fastfetch:$CONFIG_HOME/fastfetch"
  "fish:$CONFIG_HOME/fish"
  "ghostty:$CONFIG_HOME/ghostty"
  "gtk-3.0:$CONFIG_HOME/gtk-3.0"
  "gtk-4.0:$CONFIG_HOME/gtk-4.0"
  "hypr:$CONFIG_HOME/hypr"
  "kitty:$CONFIG_HOME/kitty"
  "nvim:$CONFIG_HOME/nvim"
  "quickshell:$CONFIG_HOME/quickshell"
  "rofi:$CONFIG_HOME/rofi"
  "swaync:$CONFIG_HOME/swaync"
  "dolphinrc:$CONFIG_HOME/dolphinrc"
  "kdeglobals:$CONFIG_HOME/kdeglobals"
  "edots-hypr:$HOME/edots-hypr"
)

# інструменти, що лінкуються в /usr/local/bin (потребують sudo)
# формат: "шлях_у_репо:ціль_symlink'у"
BIN_LINKS=(
  "edots-hypr/tool-manager/upkg:/usr/local/bin/upkg"
  "edots-hypr/tool-manager/utimer:/usr/local/bin/utimer"
)

c_green="\033[0;32m"; c_yellow="\033[0;33m"; c_red="\033[0;31m"; c_reset="\033[0m"
info()  { echo -e "${c_green}[ok]${c_reset}   $*"; }
warn()  { echo -e "${c_yellow}[!!]${c_reset}   $*"; }
err()   { echo -e "${c_red}[err]${c_reset}  $*"; }

cmd_install() {
  mkdir -p "$CONFIG_HOME"
  local backed_up=0

  for pair in "${LINKS[@]}"; do
    src="$REPO_DIR/${pair%%:*}"
    dst="${pair##*:}"

    if [ ! -e "$src" ]; then
      warn "нема в репо, пропускаю: $src"
      continue
    fi

    if [ -L "$dst" ]; then
      if [ "$(readlink -f "$dst")" = "$(readlink -f "$src")" ]; then
        info "вже залінковано: $dst"
        continue
      else
        rm "$dst"
      fi
    elif [ -e "$dst" ]; then
      mkdir -p "$BACKUP_DIR"
      mv "$dst" "$BACKUP_DIR/$(basename "$dst")"
      backed_up=1
      warn "старий конфіг перенесено в $BACKUP_DIR/$(basename "$dst")"
    fi

    ln -s "$src" "$dst"
    info "залінковано: $dst -> $src"
  done

  [ "$backed_up" -eq 1 ] && echo -e "\nБекап старих конфігів: $BACKUP_DIR"

  echo
  chmod +x "$REPO_DIR"/quickshell/bar/reload.sh 2>/dev/null || true
  chmod +x "$REPO_DIR"/quickshell/scripts/*.sh 2>/dev/null || true
  chmod +x "$REPO_DIR"/hypr/scripts/*.sh 2>/dev/null || true
  chmod +x "$REPO_DIR"/edots-hypr/tool-manager/upkg "$REPO_DIR"/edots-hypr/tool-manager/utimer 2>/dev/null || true
  info "виставлено +x на скрипти"

  echo
  for pair in "${BIN_LINKS[@]}"; do
    src="$REPO_DIR/${pair%%:*}"
    dst="${pair##*:}"

    if [ ! -e "$src" ]; then
      warn "нема в репо, пропускаю: $src"
      continue
    fi

    if [ -L "$dst" ] && [ "$(readlink -f "$dst")" = "$(readlink -f "$src")" ]; then
      info "вже залінковано: $dst"
      continue
    fi

    sudo ln -sf "$src" "$dst"
    info "залінковано (sudo): $dst -> $src"
  done

  if command -v python3 >/dev/null; then
    python3 "$REPO_DIR/hypr/scripts/wallcolors.py" || warn "wallcolors.py впав, запусти вручну"
  fi

  echo
  info "готово. qs -p $CONFIG_HOME/quickshell/bar"
}

cmd_status() {
  for pair in "${LINKS[@]}"; do
    src="$REPO_DIR/${pair%%:*}"
    dst="${pair##*:}"

    if [ -L "$dst" ] && [ "$(readlink -f "$dst")" = "$(readlink -f "$src")" ]; then
      info "$dst -> $src"
    elif [ -L "$dst" ]; then
      warn "$dst symlink, але веде в інше місце ($(readlink -f "$dst"))"
    elif [ -e "$dst" ]; then
      err "$dst існує, але НЕ symlink (звичайна копія)"
    else
      warn "$dst не існує"
    fi
  done

  echo
  for pair in "${BIN_LINKS[@]}"; do
    src="$REPO_DIR/${pair%%:*}"
    dst="${pair##*:}"

    if [ -L "$dst" ] && [ "$(readlink -f "$dst")" = "$(readlink -f "$src")" ]; then
      info "$dst -> $src"
    elif [ -L "$dst" ]; then
      warn "$dst symlink, але веде в інше місце ($(readlink -f "$dst"))"
    elif [ -e "$dst" ]; then
      err "$dst існує, але НЕ symlink (звичайна копія)"
    else
      warn "$dst не існує"
    fi
  done
}

cmd_unlink() {
  for pair in "${LINKS[@]}"; do
    src="$REPO_DIR/${pair%%:*}"
    dst="${pair##*:}"

    if [ -L "$dst" ] && [ "$(readlink -f "$dst")" = "$(readlink -f "$src")" ]; then
      rm "$dst"
      info "видалено symlink: $dst"
    fi
  done

  for pair in "${BIN_LINKS[@]}"; do
    src="$REPO_DIR/${pair%%:*}"
    dst="${pair##*:}"

    if [ -L "$dst" ] && [ "$(readlink -f "$dst")" = "$(readlink -f "$src")" ]; then
      sudo rm "$dst"
      info "видалено symlink (sudo): $dst"
    fi
  done

  echo "Бекапи (~/.config-backup-*) поверни вручну за потреби."
}

case "${1:-}" in
  install) cmd_install ;;
  status)  cmd_status ;;
  unlink)  cmd_unlink ;;
  *)
    echo "Використання: $0 {install|status|unlink}"
    exit 1
    ;;
esac
