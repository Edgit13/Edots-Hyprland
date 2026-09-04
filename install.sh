#!/usr/bin/env bash
#
# install.sh — повний бутстрап Edots-rice на Arch-based дистрибутивах
# (Arch, EndeavourOS, Manjaro, CachyOS...).
#
# Ставить усі пакети, шрифти й Python-залежності, потрібні цьому рису,
# бутстрапить yay якщо його нема, і в кінці передає естафету sync.sh.
#
# Використання:
#   curl -fsSL https://raw.githubusercontent.com/Edgit13/Edots-rice/master/install.sh | bash
# або локально:
#   git clone https://github.com/Edgit13/Edots-rice.git ~/Dotfiles
#   cd ~/Dotfiles && ./install.sh
#
set -uo pipefail

REPO_URL="https://github.com/Edgit13/Edots-rice.git"
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

# ───────────────────────── шпалери (окремий репо) ─────────────────────────
WALLPAPERS_REPO="https://github.com/Edgit13/Edot-Wallpapers.git"
WALLPAPERS_DIR="$HOME/Pictures/Wallpapers"

echo
echo "Шпалери зберігаються в окремому репозиторії: $WALLPAPERS_REPO"
echo "Якщо погодишся — вони скачаються в: $WALLPAPERS_DIR"
read -r -p "Поставити шпалери? [y/N]: " wp_answer
case "$wp_answer" in
  [Yy]*)
    if [ -d "$WALLPAPERS_DIR/.git" ]; then
      c_info "Репо шпалер вже є в $WALLPAPERS_DIR — оновлюю (git pull)..."
      if git -C "$WALLPAPERS_DIR" pull --ff-only; then
        c_ok "шпалери оновлено"
      else
        c_warn "git pull для шпалер не вдався"
        FAILED+=("wallpapers:pull")
      fi
    else
      if [ -e "$WALLPAPERS_DIR" ]; then
        wp_backup="$HOME/.config-backup-$(date +%Y%m%d-%H%M%S)"
        mkdir -p "$wp_backup"
        mv "$WALLPAPERS_DIR" "$wp_backup/Wallpapers"
        c_warn "існуючу $WALLPAPERS_DIR перенесено в $wp_backup/Wallpapers"
      fi
      mkdir -p "$(dirname "$WALLPAPERS_DIR")"
      c_info "Клоную шпалери в $WALLPAPERS_DIR..."
      if git clone "$WALLPAPERS_REPO" "$WALLPAPERS_DIR"; then
        c_ok "шпалери склоновано в $WALLPAPERS_DIR"
      else
        c_warn "git clone шпалер не вдався"
        FAILED+=("wallpapers:clone")
      fi
    fi
    ;;
  *)
    c_info "Пропускаю шпалери (постав пізніше: git clone $WALLPAPERS_REPO $WALLPAPERS_DIR)."
    ;;
esac

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
  # Ядро MangoWC (xdg-desktop-portal-wlr — загальний wlroots-портал,
  # не Hyprland-специфічний; swayidle — заміна hypridle)
  xdg-desktop-portal-wlr swayidle
  # Шрифти
  ttf-material-symbols-variable ttf-fira-code
  # CLI-інструменти бару
  networkmanager network-manager-applet bluez bluez-utils blueman
  power-profiles-daemon wireplumber
  wl-clipboard brightnessctl iproute2 iputils slurp wf-recorder
  # Термінали / застосунки
  alacritty ghostty kitty nautilus dolphin firefox
  # Допоміжні скрипти
  libnotify cpupower gamemode playerctl bc starship
  # edots-hypr еко-система
  figlet inotify-tools flatpak python-pip
  vlc
  # Термінал/шел/інше
  fish jq fastfetch neovim git ripgrep fd rofi tree curl
  # опційні залежності rishot (мульти-монітор склейка, діалог збереження)
  imagemagick kdialog
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

# ───────────────────────── Google Sans Flex (GTK font, тепер OSS) ─────────────────────────
# gtk-3.0/gtk-4.0 налаштовані на "Google Sans Flex" — Google випустив цей шрифт
# як open source (SIL OFL) в кінці 2025, але в pacman/AUR його ще нема (станом
# на момент написання скрипта). Качаємо статичну Regular-версію з офіційного
# дзеркала LineageOS (той самий шрифт, ліцензія та сама, це не сторонній форк).
FONT_DIR="$HOME/.local/share/fonts"
if [ ! -f "$FONT_DIR/GoogleSansFlex-Regular.ttf" ]; then
  c_info "Качаю Google Sans Flex (GTK-шрифт)..."
  mkdir -p "$FONT_DIR"
  if curl -fsSL -o "$FONT_DIR/GoogleSansFlex-Regular.ttf" \
    "https://raw.githubusercontent.com/LineageOS/android_external_google-fonts_google-sans-flex/lineage-23.2/GoogleSansFlex-Regular.ttf"; then
    fc-cache -f "$FONT_DIR" >/dev/null 2>&1
    c_ok "Google Sans Flex (Regular)"
    c_warn "  Це лише статична Regular-інстанція, не повний variable-шрифт —"
    c_warn "  вага/opsz з gtk-3.0/settings.ini (@opsz=11,wght=500) не відпрацюють."
    c_warn "  Для повної підтримки осей качай variable TTF вручну з fonts.google.com/specimen/Google+Sans+Flex"
  else
    c_warn "не вдалося скачати Google Sans Flex — постав вручну з fonts.google.com"
    FAILED+=("font:google-sans-flex")
  fi
fi

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
  mangowc-git
  swaylock-effects-git
  quickshell
  ttf-jetbrains-mono-nerd
  swaync
  cliphist
  awww
  zen-browser-bin
  matugen
)
# ПРИМІТКА: hyprscreen (запис екрана) прибрано зі списку — цей AUR-пакет
# сам вимагає встановленого Hyprland як залежність, тож на MangoWC не
# збереться. Еквівалента під MangoWC поки не підбирав — якщо запис екрана
# потрібен, скажи, підберу окремо (наприклад wf-recorder напряму, без
# hyprscreen-обгортки).

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

# ───────────────────────── rishot (скріншоти + анотації) ─────────────────────────
# https://github.com/Gakuseei/rishot — власний офіційний інсталятор, вимагає
# quickshell (уже поставлений вище). Ставить сам себе на PATH.
if ! command -v rishot >/dev/null 2>&1; then
  c_info "Ставлю rishot..."
  if curl -fsSL https://raw.githubusercontent.com/Gakuseei/rishot/main/install.sh | sh; then
    c_ok "rishot"
  else
    c_warn "інсталятор rishot не вдався — постав вручну: curl -fsSL https://raw.githubusercontent.com/Gakuseei/rishot/main/install.sh | sh"
    FAILED+=("rishot")
  fi
fi

# ───────────────────────── HyprGlass — НЕ переноситься на MangoWC ─────────────────────────
# HyprGlass — плагін через hyprpm (Hyprland-специфічна плагінна система),
# прямого еквівалента на MangoWC немає. MangoWC дає blur/shadow/corner
# radius/opacity нативно вбудовано через scenefx (не плагін, налаштування
# в самому конфізі компоузера) — це заміна концепції, не порт коду, тому
# свідомо НЕ намагаюсь тут це автоматично ввімкнути. Налаштуй blur/shadow
# напряму в mango-конфізі (decorations.conf), коли з'явиться.

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

# ───────────────────────── речі, які скрипт свідомо НЕ ставить ─────────────────────────
c_warn "Курсор-тема 'Moga-Black' (gtk-3.0/gtk-4.0 settings.ini) — не знайшов надійного"
c_warn "  джерела пакета, постав вручну (AUR-пошук або themes.gtk.org) і заміни назву,"
c_warn "  якщо поставиш під іншою."

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
  c_ok "Все встановилось без помилок. Перелогінься в MangoWC і насолоджуйся."
else
  c_warn "Встановлення завершено, але з ${#FAILED[@]} пропусками:"
  for f in "${FAILED[@]}"; do
    echo "    - $f"
  done
  c_warn "Постав їх вручну (перевір точні назви пакетів для твого дистрибутива)."
fi
