<div align="center">

![Edots-rice banner](docs/banner.png)

# Edots-rice

**Особистий MangoWM + Quickshell rice**

Кастомний нотч-бар у стилі dynamic island, шпалеро-адаптивна палітра кольорів,
GameMode, swaylock і MangoWM-конфіг — усе зібрано в один дотфайл-репозиторій.

[![MangoWM](https://img.shields.io/badge/MangoWM-Wayland-ffb347?style=for-the-badge)](#)
[![Quickshell](https://img.shields.io/badge/Quickshell-QML-1E1E2E?style=for-the-badge)](https://quickshell.org/)
[![License](https://img.shields.io/badge/license-MIT-lightgrey?style=for-the-badge)](#ліцензія)

надихнувся [Dynamic-island-for-arch](https://github.com/patheonsceo/Dynamic-island-for-arch) та [Ricelin](https://github.com/Gakuseei/Ricelin)

</div>

---

## Зміст

- [Що входить](#що-входить)
- [Скріншоти](#скріншоти)
- [Залежності](#залежності)
- [Встановлення](#встановлення)
- [Синхронізація дотфайлів (`sync.sh`)](#синхронізація-дотфайлів-syncsh)
- [Структура репо](#структура-репо)
- [Ліцензія](#ліцензія)

## Що входить

| Компонент | Опис |
|---|---|
| `mango/` | MangoWM-конфіг: `config.conf`, модульні `*.conf`, `scripts/wallcolors.py`, `swaylock/` |
| `quickshell/bar/` | Нотч-бар на Quickshell (QML): лаунчер, шпалери, буфер обміну, мережа, звук, батарея, GameMode, живлення |
| `quickshell/scripts/` | `gamemode.sh` — легкий GameMode тогл; `modernmode.sh` — локальний візуальний тогл стану Quickshell |
| `edots/` | Окрема "еко-система" утиліт: `tool-manager/` (`upkg`, `utimer`), `tui-player/`, допоміжні скрипти |
| `gtk-3.0/`, `gtk-4.0/` | Тема GTK, синхронізована з тією ж палітрою |
| `kitty/`, `ghostty/`, `alacritty/`, `rofi/`, `swaync/`, `fastfetch/`, `fish/`, `nvim/` | Конфіги супутніх застосунків |

## Скріншоти

![notch](docs/notch.png)
*Нотч-бар: воркспейси, годинник, мережа/звук/батарея, трей.*

![dashboard](docs/dashboard.png)
*Dashboard: меню програм, Wi-Fi/Bluetooth/DND, гучність, MPRIS, календар, профілі живлення.*

## Залежності

### Ядро

| Програма | Навіщо |
|---|---|
| `mangowc-git` | Wayland-композитор MangoWM |
| [Quickshell](https://quickshell.org/) | движок нотч-бару (QML), CLI-команда `qs` |
| `swaylock-effects-git` | екран блокування |
| `swayidle` | idle/lock/suspend логіка |

### Шрифти

| Шрифт | Де використовується |
|---|---|
| Material Symbols Rounded (`extra/ttf-material-symbols-variable`) | іконки у Quickshell-барі |
| JetBrainsMono Nerd Font | термінали, swaylock helpers |
| SF Pro Display | текст/годинник у барі |
| Fira Code | Rofi |
| Google Sans Flex (`gtk-3.0`/`gtk-4.0` `settings.ini`) | системний GTK-шрифт |

### CLI-інструменти, які напряму викликає бар

| Програма | Навіщо |
|---|---|
| `NetworkManager` (`nmcli`) | Wi-Fi тогл і статус |
| `network-manager-applet` (`nm-applet`) | треюшна іконка мережі |
| `bluez` / `blueman` | Bluetooth інтеграція |
| `wireplumber` (`wpctl`) | гучність/мʼют |
| `power-profiles-daemon` (`powerprofilesctl`) | профілі живлення |
| `swaync` + `swaync-client` | сповіщення, DND |
| `cliphist` + `wl-clipboard` | історія буфера обміну |
| `brightnessctl` | яскравість |
| `awww` | демон шпалер |
| `slurp` + `wf-recorder` | запис екрана / вибір області |
| `playerctl` | медіа-контроль |
| `rishot` | скріншоти + анотації |

### Допоміжні скрипти

| Скрипт | Залежності |
|---|---|
| `mango/scripts/wallcolors.py` | `python3`, `matugen`, опційно `kitty`, `plasma-apply-colorscheme` |
| `mango/scripts/swaylock-music.sh` | `playerctl`, `bc` |
| `mango/scripts/swaylock-weather.sh` | `curl` |
| `quickshell/scripts/gamemode.sh` | `swaync-client`, `notify-send`; опційно `cpupower`, `pkexec`, `gamemoded` |
| `quickshell/scripts/modernmode.sh` | `notify-send` |

### `edots/` еко-система

| Компонент | Залежності |
|---|---|
| `tool-manager/upkg` | `yay` (AUR), `flatpak` |
| `tool-manager/utimer` | `mpv` або `pw-play` або `paplay`, `notify-send` |
| `tui-player/` | `python3`, `venv`, `pip`, `textual`, `python-vlc`, `mutagen` |

## Встановлення

### Повний бутстрап

```bash
curl -fsSL https://raw.githubusercontent.com/Edgit13/Edots-rice/master/install.sh | bash
```

Або локально:

```bash
git clone https://github.com/Edgit13/Edots-rice.git ~/Dotfiles
cd ~/Dotfiles
./install.sh
```

### Лише symlink'и

```bash
git clone https://github.com/Edgit13/Edots-rice.git ~/Dotfiles
cd ~/Dotfiles
./sync.sh install
```

Після цього запускай бар так:

```bash
qs -p ~/.config/quickshell/bar/shell.qml
```

## Синхронізація дотфайлів (`sync.sh`)

`sync.sh` лінкує конфіги з репозиторію напряму в `~/.config` через symlink.
Правиш файл у репо або в `~/.config` — це той самий файл.

```bash
./sync.sh install
./sync.sh status
./sync.sh unlink
```

Лінкуються: `alacritty`, `fastfetch`, `fish`, `ghostty`, `gtk-3.0`, `gtk-4.0`, `mango`,
`kitty`, `nvim`, `quickshell`, `rofi`, `swaync`, `edots`, а також `dolphinrc` і `kdeglobals`.

## Структура репо

```text
Edots-rice/
├── sync.sh
├── mango/
│   ├── *.conf
│   ├── scripts/
│   └── swaylock/
├── quickshell/
│   ├── bar/
│   └── scripts/
├── edots/
├── gtk-3.0/
├── gtk-4.0/
├── kitty/
├── ghostty/
├── alacritty/
├── fish/
├── nvim/
├── rofi/
├── swaync/
├── fastfetch/
├── firefox/
└── docs/
```

## Ліцензія

MIT
