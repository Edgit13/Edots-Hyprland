# Edots-Hyprland

Особистий Hyprland + Quickshell rice. Кастомний нотч-бар (dynamic island стиль,
надихнувся [Dynamic-island-for-arch](https://github.com/patheonsceo/Dynamic-island-for-arch)),
шпалеро-адаптивна палітра кольорів, GameMode, HyprGlass.

![screenshot](docs/screenshot.png)
<!-- заміни на реальний скрін нотч-бару -->

## Що входить

- **`quickshell/bar/`** — нотч-бар на Quickshell (QML): лівий острів
  (меню + воркспейси), центральний notch (годинник, Volume OSD, клік →
  Dashboard), правий острів (буфер обміну, шпалери, сповіщення, трей,
  мережа, звук, батарея, GameMode, живлення)
- **`quickshell/bar/Dash/`** — Dashboard: Wi-Fi/Bluetooth/DND тогли, Mpris
  плеєр, календар, профілі живлення (`powerprofilesctl`)
- **`quickshell/scripts/`** — `gamemode.sh` (вимикає анімації/blur/DND під
  час ігор), `modernmode.sh` (тогл HyprGlass через `hyprpm`)
- **`hypr/`** — модульний Hyprland-конфіг на Lua (`hyprland.lua` +
  `modules/*.lua`), hyprlock, hypridle
- **`hypr/scripts/wallcolors.py`** — витягує палітру з поточної шпалери й
  генерує кольори для Hyprland, GTK, Quickshell, Kitty, Fish, Firefox
- **`gtk-3.0/`, `gtk-4.0/`** — тема GTK, синхронізована з тією ж палітрою

## Залежності

- [Hyprland](https://hyprland.org/) (тестовано на 0.56.x)
- [Quickshell](https://quickshell.org/)
- `hyprpm` (для HyprGlass — опційно)
- `swaync` (сповіщення)
- Python 3 (для `wallcolors.py`)
- Nerd Font (JetBrainsMono Nerd Font Propo) — іконки в барі
- `powerprofilesctl`, `nmcli`, `bluetoothctl` — для тоглів у Dashboard

## Встановлення

```bash
git clone git@github.com:<username>/Edots-Hyprland.git ~/dotfiles
cd ~/dotfiles

# Забери попередні конфіги, якщо є
mv ~/.config/hypr ~/.config/hypr.bak 2>/dev/null
mv ~/.config/quickshell ~/.config/quickshell.bak 2>/dev/null
mv ~/.config/gtk-3.0 ~/.config/gtk-3.0.bak 2>/dev/null
mv ~/.config/gtk-4.0 ~/.config/gtk-4.0.bak 2>/dev/null

# Симлінк замість копій — зміни одразу видно в git diff
ln -s ~/dotfiles/hypr ~/.config/hypr
ln -s ~/dotfiles/quickshell ~/.config/quickshell
ln -s ~/dotfiles/gtk-3.0 ~/.config/gtk-3.0
ln -s ~/dotfiles/gtk-4.0 ~/.config/gtk-4.0

chmod +x ~/.config/quickshell/bar/reload.sh
chmod +x ~/.config/quickshell/scripts/*.sh
chmod +x ~/.config/hypr/scripts/*.sh

# Згенерувати кольори з поточної шпалери перед першим запуском
python3 ~/.config/hypr/scripts/wallcolors.py

qs -p ~/.config/quickshell/bar
```

## HyprGlass (опційно)

```bash
hyprpm add https://github.com/hyprnux/hyprglass
```

Потрібен дозвіл на завантаження плагінів без запиту пароля щоразу —
розкоментуй у `hypr/hyprland.lua`:

```lua
hl.permission("/usr/(bin|local/bin)/hyprpm", "plugin", "allow")
```

і повністю перезапусти Hyprland-сесію (не просто `hyprctl reload`).

## Ліцензія

MIT (або що сам оберешь)
