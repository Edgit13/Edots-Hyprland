<div align="center">

![Edots-Hyprland banner](docs/banner.png)

# Edots-Hyprland

**Особистий Hyprland + Quickshell rice**

Кастомний нотч-бар у стилі dynamic island, шпалеро-адаптивна палітра кольорів,
GameMode, HyprGlass — усе зібрано в один дотфайл-репозиторій.

[![Hyprland](https://img.shields.io/badge/Hyprland-58E1FF?style=for-the-badge&logo=hyprland&logoColor=black)](https://hyprland.org/)
[![Quickshell](https://img.shields.io/badge/Quickshell-QML-1E1E2E?style=for-the-badge)](https://quickshell.org/)
[![License](https://img.shields.io/badge/license-MIT-lightgrey?style=for-the-badge)](#ліцензія)

надихнувся [Dynamic-island-for-arch](https://github.com/patheonsceo/Dynamic-island-for-arch)

</div>

---

## Зміст

- [Що входить](#що-входить)
- [Скріншоти](#скріншоти)
- [Залежності](#залежності)
- [Встановлення](#встановлення)
- [Синхронізація дотфайлів (`sync.sh`)](#синхронізація-дотфайлів-syncsh)
- [HyprGlass (опційно)](#hyprglass-опційно)
- [Структура репо](#структура-репо)
- [Ліцензія](#ліцензія)

## Що входить

| Компонент | Опис |
|---|---|
| `quickshell/bar/` | Нотч-бар на Quickshell (QML): лівий острів (меню + воркспейси), центральний notch (годинник, Volume OSD, клік → Dashboard), правий острів (буфер обміну, шпалери, сповіщення, трей, мережа, звук, батарея, GameMode, живлення) |
| `quickshell/bar/Dash/` | Dashboard: Wi-Fi / Bluetooth / DND тогли, MPRIS-плеєр, календар, профілі живлення (`powerprofilesctl`) |
| `quickshell/scripts/` | `gamemode.sh` — вимикає анімації/blur/DND під час ігор; `modernmode.sh` — тогл HyprGlass через `hyprpm` |
| `hypr/` | Модульний Hyprland-конфіг на Lua (`hyprland.lua` + `modules/*.lua`), `hyprlock/`, `hypridle.conf` |
| `hypr/scripts/wallcolors.py` | Витягує палітру з поточної шпалери через `matugen` і генерує кольори для Hyprland, GTK, Quickshell, Kitty, Ghostty, Fish, Firefox |
| `edots-hypr/` | Окрема "еко-система" утиліт: `tool-manager/` (`upkg` — обгортка над yay+flatpak, `utimer` — фоновий таймер), `tui-player/` (TUI-плеєр на Textual+VLC), `bin/edot-i18.py` (читає `settings.edot`), скрипти автозапуску/бекапу |
| `gtk-3.0/`, `gtk-4.0/` | Тема GTK, синхронізована з тією ж палітрою |
| `nvim/`, `fish/`, `kitty/`, `alacritty/`, `ghostty/`, `rofi/`, `swaync/`, `fastfetch/` | Конфіги супутніх застосунків |

## Скріншоти

![notch](docs/notch.png)
*Нотч-бар: воркспейси, годинник, мережа/звук/батарея, трей.*

![dashboard](docs/dashboard.png)
*Dashboard: меню програм, Wi-Fi/Bluetooth/DND, гучність, MPRIS, календар, профілі живлення.*

## Залежності

### Ядро

| Програма | Навіщо |
|---|---|
| [Hyprland](https://hyprland.org/) `0.56.x`+ | Wayland-композитор, Lua-конфіг (`hl.*` API) |
| [Quickshell](https://quickshell.org/) | движок нотч-бару (QML), CLI-команда `qs` |
| `hyprpm` | менеджер плагінів Hyprland — потрібен для HyprGlass |
| `hyprlock` | екран блокування |
| `hypridle` | демон бездіяльності (автолок/сон) |
| [HyprGlass](https://github.com/hyprnux/hyprglass) | плагін "liquid-glass" — опційно, тогл `Super+F2`→Dashboard→Modern або `modernmode.sh` |

### Шрифти

| Шрифт | Де використовується |
|---|---|
| Material Symbols Rounded (`extra/ttf-material-symbols-variable`) | іконки у Quickshell-барі |
| JetBrainsMono Nerd Font | Alacritty, іконки в `hyprlock-music.sh` |
| SF Pro Display | текст/годинник у барі |
| Fira Code | Rofi |
| Google Sans Flex (`gtk-3.0`/`gtk-4.0` `settings.ini`, `@opsz=11,wght=500`) | системний GTK-шрифт; з кінця 2025 випущений як OSS (SIL OFL), в pacman/AUR ще нема — `install.sh` качає статичну Regular-версію з дзеркала LineageOS; за повними variable-осями йди на [fonts.google.com](https://fonts.google.com/specimen/Google+Sans+Flex) |

> ⚠️ Курсор-тема `Moga-Black` (та сама `settings.ini`) — не має надійного відомого джерела пакета; `install.sh` її НЕ ставить. Постав вручну (пошук по AUR чи gtk-темах) і за потреби зміни назву в `settings.ini`.

### CLI-інструменти, які напряму викликає бар (Quickshell `Process{}`)

| Програма | Навіщо |
|---|---|
| `NetworkManager` (`nmcli`) | Wi-Fi тогл і статус у `Network.qml` / Dashboard |
| `network-manager-applet` (`nm-applet`) | автозапуск (`autostart.lua`), треюшна іконка мережі |
| `bluez` (`bluetoothctl`) | Bluetooth тогл у Dashboard |
| `blueman` (`blueman-applet`) | автозапуск (`autostart.lua`), треюшна іконка Bluetooth |
| `wireplumber` (`wpctl`) | гучність/мьют з клавіш (`binds.lua`) |
| `power-profiles-daemon` (`powerprofilesctl`) | профілі живлення у Dashboard |
| `swaync` + `swaync-client` | сповіщення, DND, лічильник |
| `cliphist` + `wl-clipboard` (`wl-copy`/`wl-paste`) | історія буфера обміну |
| `brightnessctl` | яскравість екрана (слайдер у Dashboard, клавіші) |
| `awww` | демон шпалер (`awww img -t wave ...`, форк-заміна `swww` у офіційних репах Arch) |
| `iproute2` (`ip`), `iputils` (`ping`) | RX/TX-трафік і пінг у `Network.qml` |
| `alacritty` | термінал (запускається кнопками бару, окремо від дефолтного `kitty` з `binds.lua`) |
| `ghostty` | термінал (опційно; той самий динамічний стиль/прозорість, що Kitty) |
| `nautilus` | файловий менеджер (кнопка в меню бару — окремо від дефолтного `dolphin` у `binds.lua`) |
| `zen-browser` | браузер (кнопка в меню бару — окремо від дефолтного `firefox` у `binds.lua`) |
| `hyprscreen` (AUR) | запис екрана, `Super+Shift+U` (`binds.lua`, змінна `screen_rec`) |
| `xdg-desktop-portal-hyprland` | портали (screen share/pick для `hyprscreen` та іншого) |
| `starship` | промпт у fish (`config.fish`) |
| `systemctl` | reboot/poweroff/suspend |

> ⚠️ `Super+U` (`binds.lua`, змінна `screen` = `~/.local/bin/rishot`) — це твій власний скрипт/білд скріншотів, не публічний пакет. `install.sh` його НЕ ставить; поклади свій білд у `~/.local/bin/rishot` сам, або зміни бінд на `hyprshot`/`hyprscreen`.
>
> ⚠️ `Dash/Panel.qml` викликає `qsh ipc call menu toggle`, а всюди інде (`binds.lua`) — `qs -c bar ipc call ...`. Схоже на одруківку (`qsh` замість `qs`) — вартувало б звірити, чи в тебе справді є алiас/бінарник `qsh`, інакше ця кнопка мовчки не спрацює.

### Допоміжні скрипти

| Скрипт | Залежності |
|---|---|
| `quickshell/scripts/gamemode.sh` | `hyprctl`, `swaync-client`, `notify-send` (libnotify); опційно `cpupower`, `pkexec` (polkit), `gamemoded` (Feral GameMode) |
| `quickshell/scripts/modernmode.sh` | `hyprpm`, `notify-send` |
| `hypr/scripts/wallcolors.py` | `python3`, [`matugen`](https://github.com/InioX/matugen) (генерація Material You палітри), `swaync-client`, `kitty` (remote control), опційно `plasma-apply-colorscheme` (live-тема Dolphin у KDE-сесії) |
| `hypr/scripts/hyprlock-music.sh` | `playerctl`, `bc` |
| `hypr/scripts/hyprlock-weather.sh` | `curl` (запит до `wttr.in`) |

### `edots-hypr/` еко-система

| Компонент | Залежності |
|---|---|
| `asettings.sh` | `figlet` |
| `autostart.sh` | `python3` (запускає `tui-player`) |
| `update.sh` | опційно `inotify-tools` (`inotifywait`), інакше polling через `stat`; `nautilus` для live-reload теми |
| `tool-manager/upkg` | `yay` (AUR), `flatpak` |
| `tool-manager/utimer` | `mpv` **або** `pw-play` (PipeWire) **або** `paplay` (PulseAudio, будь-що одне), `notify-send` |
| `tui-player/` | `python3`, `venv`, `pip`; піп-пакети `textual`, `python-vlc` (потребує системний `vlc`/`libvlc`), `mutagen` |
| `bin/edot-i18.py` | тільки stdlib Python, без зовнішніх залежностей |

> ⚠️ `backup.sh` викликає `./bup.sh`, якого немає в репозиторії — або файл загубився, або скрипт ще не доданий.

### Термінали, шел, інше

| Програма | Навіщо |
|---|---|
| `fish` | основний шел, `config.fish` |
| `starship` | промпт (`starship init fish`) |
| `jq` | читає `hypr/colors.json` у змінні `fish` |
| `fastfetch` | system-info (alias `ff`) |
| `nvim` (LazyVim) | редактор (alias `e`); LazyVim стандартно тягне `git`, `ripgrep`, `fd` |
| `kitty`, `alacritty`, `ghostty` | термінали |
| `rofi` | лаунчер/меню (`Super+Space`) |
| `dolphin` | файловий менеджер (`Super+E`) |
| `firefox` | браузер (`Super+B`), + `firefox/chrome/` userChrome |
| `tree`, `pnpm` | згадуються в `fish/config.fish` (alias/PATH) |

## Встановлення

### Повний бутстрап (пакети + шрифти + symlink'и) — рекомендовано

Тільки для Arch-based дистрибутивів (Arch, EndeavourOS, Manjaro, CachyOS).
Ставить усе з таблиць залежностей вище через `pacman`/`yay` (бутстрапить `yay`
сам, якщо його нема), потім сам клонує репо й запускає `sync.sh install`:

```bash
curl -fsSL https://raw.githubusercontent.com/Edgit13/Edots-Hyprland/master/install.sh | bash
```

Або локально, якщо репо вже склоновано:

```bash
git clone git@github.com:Edgit13/Edots-Hyprland.git ~/Dotfiles
cd ~/Dotfiles
./install.sh
```

`install.sh` не падає на одному невдалому пакеті — збирає список пропусків
і показує в кінці, щоб доставити вручну (назви AUR-пакетів час від часу
міняються). HyprGlass і SF Pro Display — опційні, помічено про них окремо.

На самому початку `install.sh` запитає, чи ставити шпалери — вони живуть
в окремому репо [Edot-Wallpapers](https://github.com/Edgit13/Edot-Wallpapers)
(не в цьому), і при згоді клонуються прямо в `~/Pictures/Wallpapers`.
Погодишся — покаже шлях перед завантаженням; відмовишся — просто пропустить
крок, шпалери можна доставити пізніше вручну:

```bash
git clone https://github.com/Edgit13/Edot-Wallpapers.git ~/Pictures/Wallpapers
```

### Лише symlink'и (пакети вже стоять)

```bash
git clone git@github.com:Edgit13/Edots-Hyprland.git ~/Dotfiles
cd ~/Dotfiles

./sync.sh install
```

`sync.sh install` сам:

1. бекапить існуючі конфіги в `~/.config-backup-<дата>/`;
2. симлінкає кожну теку/файл репо напряму в `~/.config/`;
3. виставляє `+x` на всі шел-скрипти;
4. одразу генерує палітру з поточної шпалери (`wallcolors.py`).

Далі:

```bash
qs -p ~/.config/quickshell/bar
```

## Синхронізація дотфайлів (`sync.sh`)


Раніше конфіги доводилось копіювати вручну і в `~/.config`, і назад у репо.
`sync.sh` вирішує це через **symlink**: `~/.config/hypr` і `~/Dotfiles/hypr` —
це одна й та сама тека на диску. Правиш файл з будь-якого боку — зміна одразу
і в реальному конфізі, і в git-репо, без ручного копіювання.

```bash
./sync.sh install   # створити/оновити symlink'и (з бекапом старого)
./sync.sh status    # перевірити, що і куди залінковано
./sync.sh unlink    # прибрати symlink'и (бекапи лишаються в ~/.config-backup-*)
```

Що лінкується: `alacritty`, `fastfetch`, `fish`, `ghostty`, `gtk-3.0`, `gtk-4.0`, `hypr`,
`kitty`, `nvim`, `quickshell`, `rofi`, `swaync`, `edots-hypr` (→ `~/edots-hypr`),
а також файли `dolphinrc` і `kdeglobals`. Список тек/цілей редагується прямо
в масиві `LINKS` на початку скрипта.

Окремо `sync.sh install` лінкує `upkg` і `utimer` (з `edots-hypr/tool-manager/`)
у `/usr/local/bin/` — це системна тека, тому ці два лінки створюються через
`sudo` (спитає пароль один раз). Редагується в масиві `BIN_LINKS`.

> `firefox/chrome/` лінкується окремо, бо шлях до профілю унікальний:
> ```bash
> ln -sf ~/Dotfiles/firefox/chrome ~/.mozilla/firefox/<профіль>.default-release/chrome
> ```

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

## Структура репо

```
Edots-Hyprland/
├── sync.sh              # symlink-синхронізатор
├── hypr/                # Hyprland (Lua) + hyprlock/hypridle + wallcolors.py
├── quickshell/bar/       # нотч-бар (QML)
├── quickshell/scripts/   # gamemode.sh, modernmode.sh
├── edots-hypr/           # tool-manager (upkg, utimer), tui-player, скрипти автозапуску/бекапу
├── gtk-3.0/ gtk-4.0/     # GTK-тема
├── kitty/ alacritty/ ghostty/  # термінали
├── fish/                # шел
├── nvim/                # LazyVim-конфіг
├── rofi/                # лаунчер
├── swaync/               # сповіщення
├── fastfetch/            # system-info
├── firefox/chrome/       # userChrome.css
└── docs/                 # банер, скріншоти
```

## Ліцензія

MIT
