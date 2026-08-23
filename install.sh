#!/usr/bin/env bash
#
# install.sh — повний бутстрап Edots-Hyprland на Arch-based дистрибутивах
# (Arch, EndeavourOS, Manjaro, CachyOS...).
#
# Ставить усі пакети, шрифти й Python-залежності, потрібні цьому рису,
# бутстрапить yay якщо його нема, і в кінці передає естафету sync.sh.
#
# Використання:
#   curl -fsSL https://raw.githubusercontent.com/Edgit13/Edots-Hyprland/master/install.sh | bash
# або локально:
#   git clone https://github.com/Edgit13/Edots-Hyprland.git ~/Dotfiles
#   cd ~/Dotfiles && ./install.sh
#
set -uo pipefail

REPO_URL="https://github.com/Edgit13/Edots-Hyprland.git"
REPO_DIR="${EDOTS_DIR:-$HOME/Dotfiles}"

# ─────────────────────────── логування ────────────────────────────
c_info()  { printf '\033[36m[i]\033[0m %s\n' "$*"; }
c_warn()  { printf '\033[33m[!]\033[0m %s\n' "$*"; }
c_err()   { printf '\033[31m[x]\033[0m %s\n' "$*"; }
c_ok()    { printf '\033[32m[✓]\033[0m %s\n' "$*"; }

FAILED=()

# ───────────────────── перевірка дистрибутива ─────────────────────
if ! command -v pacman >/dev/null 2>&1; then
  c_err "pacman не знайдено — цей скрипт для Arch-based дистрибутивів (Arch/EndeavourOS/Manjaro/CachyOS)."
  exit 1
fi

if [ "$EUID" -eq 0 ]; then
  c_err "Не запускай від root — скрипт сам просить sudo де треба."
  exit 1
fi

c_info "sudo знадобиться кілька разів (pacman, yay-бутстрап, symlink /usr/local/bin)."
sudo -v

# ───────────────────────── клон репозиторію ─────────────────────────
if [ -d "$REPO_DIR/.git" ]; then
  c_info "Репо вже є в $REPO_DIR — пропускаю clone."
elif [ -d "$REPO_DIR" ]; then
  c_warn "$REPO_DIR існує, але це не git-репо. Клонуй вручну або онови REPO_DIR."
else
  c_info "Клоную репозиторій у $REPO_DIR..."
  git clone "$REPO_URL" "$REPO_DIR" || { c_err "git clone не вдався"; exit 1; }
fi
cd "$REPO_DIR" || exit 1

# ───────────────────────── pacman (офіційні репо) ─────────────────────────
PACMAN_PKGS=(
  # Ядро Hyprland
  hyprland hyprlock hypridle
  # Шрифти
  ttf-material-symbols-variable ttf-fira-code
  # CLI-інструменти бару
  networkmanager bluez bluez-utils power-profiles-daemon
  wl-clipboard brightnessctl iproute2 iputils
  # Термінали / застосунки
  alacritty ghostty kitty nautilus dolphin firefox
  # Допоміжні скрипти
  libnotify cpupower gamemode playerctl bc
  # edots-hypr еко-система
  figlet inotify-tools flatpak python-pip
  vlc
  # Термінал/шел/інше
  fish jq fastfetch neovim git ripgrep fd rofi tree
)

c_info "Синхронізую бази pacman..."
sudo pacman -Sy --noconfirm

c_info "Ставлю пакети з офіційних репо (${#PACMAN_PKGS[@]} шт.)..."
for pkg in "${PACMAN_PKGS[@]}"; do
  if pacman -Qi "$pkg" >/dev/null 2>&1; then
    continue
  fi
  if sudo pacman -S --needed --noconfirm "$pkg"; then
    c_ok "$pkg"
  else
    c_warn "не вдалося поставити $pkg (pacman) — перевір назву пакета вручну"
    FAILED+=("pacman:$pkg")
  fi
done

# ───────────────────────── бутстрап yay ─────────────────────────
if ! command -v yay >/dev/null 2>&1; then
  c_info "yay не знайдено — збираю з AUR..."
  sudo pacman -S --needed --noconfirm base-devel git
  tmpdir=$(mktemp -d)
  git clone https://aur.archlinux.org/yay.git "$tmpdir/yay" && \
    (cd "$tmpdir/yay" && makepkg -si --noconfirm) && \
    c_ok "yay встановлено" || { c_err "не вдалося зібрати yay — AUR-пакети доведеться ставити вручну"; FAILED+=("yay-bootstrap"); }
  rm -rf "$tmpdir"
fi

# ───────────────────────── AUR (через yay) ─────────────────────────
AUR_PKGS=(
  quickshell
  ttf-jetbrains-mono-nerd
  swaync
  cliphist
  awww
  zen-browser-bin
  matugen
)

if command -v yay >/dev/null 2>&1; then
  c_info "Ставлю AUR-пакети (${#AUR_PKGS[@]} шт.)..."
  for pkg in "${AUR_PKGS[@]}"; do
    if pacman -Qi "$pkg" >/dev/null 2>&1; then
      continue
    fi
    if yay -S --needed --noconfirm "$pkg"; then
      c_ok "$pkg"
    else
      c_warn "не вдалося поставити $pkg (AUR) — перевір точну назву пакета вручну"
      FAILED+=("aur:$pkg")
    fi
  done
else
  c_warn "yay недоступний — пропускаю AUR-пакети: ${AUR_PKGS[*]}"
  FAILED+=("aur:усі (немає yay)")
fi

# ───────────────────────── HyprGlass (опційний плагін) ─────────────────────────
if command -v hyprpm >/dev/null 2>&1; then
  c_info "Ставлю HyprGlass через hyprpm (опційно)..."
  hyprpm update >/dev/null 2>&1
  if hyprpm add https://github.com/hyprnux/hyprglass >/dev/null 2>&1; then
    hyprpm enable hyprglass >/dev/null 2>&1 && c_ok "HyprGlass" || c_warn "HyprGlass додано, але не увімкнувся — постав вручну: hyprpm enable hyprglass"
  else
    c_warn "hyprpm add hyprglass не вдався (не критично, це опційний ефект) — постав вручну за потреби"
    FAILED+=("hyprpm:hyprglass")
  fi
fi

# ───────────────────────── tui-player (Python venv) ─────────────────────────
TUI_DIR="$REPO_DIR/edots-hypr/tui-player"
if [ -d "$TUI_DIR" ]; then
  c_info "Ставлю venv для tui-player..."
  python3 -m venv "$TUI_DIR/.venv" 2>/dev/null || sudo pacman -S --needed --noconfirm python
  if [ -d "$TUI_DIR/.venv" ]; then
    "$TUI_DIR/.venv/bin/pip" install --quiet --upgrade pip
    "$TUI_DIR/.venv/bin/pip" install --quiet textual python-vlc mutagen && \
      c_ok "tui-player venv (textual, python-vlc, mutagen)" || {
        c_warn "pip install у tui-player venv не вдався"
        FAILED+=("pip:tui-player")
      }
  fi
fi

# ───────────────────────── pnpm (окремо, не завжди в офіційних репо) ─────────────────────────
if ! command -v pnpm >/dev/null 2>&1; then
  if command -v npm >/dev/null 2>&1; then
    c_info "Ставлю pnpm через npm..."
    sudo npm install -g pnpm >/dev/null 2>&1 && c_ok "pnpm" || { c_warn "не вдалося поставити pnpm"; FAILED+=("npm:pnpm"); }
  else
    c_warn "npm недоступний — pnpm пропущено (треба для fish alias/PATH, не критично)"
  fi
fi

# ───────────────────────── SF Pro Display (опційно, не FOSS) ─────────────────────────
c_warn "SF Pro Display — пропріетарний Apple-шрифт, автоматично НЕ ставлю."
c_warn "  Опційна неофіційна AUR-збірка: yay -S otf-san-francisco (перевір légal-статус сам)."

# ───────────────────────── sync.sh install ─────────────────────────
if [ -x "$REPO_DIR/sync.sh" ]; then
  c_info "Симлінкую конфіги через sync.sh install..."
  "$REPO_DIR/sync.sh" install
else
  c_warn "sync.sh не знайдено або не виконуваний — запусти симлінки вручну."
fi

# ───────────────────────── підсумок ─────────────────────────
echo
if [ "${#FAILED[@]}" -eq 0 ]; then
  c_ok "Все встановилось без помилок. Перелогінься в Hyprland і насолоджуйся."
else
  c_warn "Встановлення завершено, але з ${#FAILED[@]} пропусками:"
  for f in "${FAILED[@]}"; do
    echo "    - $f"
  done
  c_warn "Постав їх вручну (перевір точні назви пакетів для твого дистрибутива)."
fi
