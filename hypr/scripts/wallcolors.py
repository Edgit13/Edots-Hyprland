#!/usr/bin/env python3
"""
wallcolors.py — генерує кольорову палітру Ricelin з шпалери.

Використання:
    wallcolors.py /path/to/wallpaper.png
"""

import sys
import os
import re
import json
import subprocess
import colorsys
import logging

HOME = os.path.expanduser("~")
HYPR_COLORS_LUA = os.path.join(HOME, ".config/hypr/hypr-colors.lua")
KITTY_COLORS_CONF = os.path.join(HOME, ".config/kitty/kitty-colors.conf")
QUICKSHELL_COLORS_JSON = os.path.join(HOME, ".config/hypr/colors.json")
ROFI_COLORS_RASI = os.path.join(HOME, ".config/rofi/colors.rasi")
HYPRLOCK_COLORS_CONF = os.path.join(HOME, ".config/hypr/hyprlock-colors.conf")
SWAYNC_COLORS_CSS = os.path.join(HOME, ".config/swaync/colors.css")
GTK4_COLORS_CSS = os.path.join(HOME, ".config/gtk-4.0/gtk-colors.css")
GTK3_COLORS_CSS = os.path.join(HOME, ".config/gtk-3.0/gtk-colors.css")
FISH_COLORS_FISH = os.path.join(HOME, ".config/fish/fish-colors.fish")
FIREFOX_COLORS_CSS = os.path.join(HOME, ".config/firefox-colors.css")
LOG_FILE = os.path.join(HOME, "wallcolours.log")

# Налаштування логування: запис у файл wallcolours.log та вивід у термінал
logging.basicConfig(
    level=logging.INFO,
    format="[%(asctime)s] [%(levelname)s] %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
    handlers=[
        logging.FileHandler(LOG_FILE, encoding="utf-8"),
        logging.StreamHandler(sys.stdout)  # Дозволяє бачити лог у консолі паралельно
    ]
)


def get_source_color(image_path: str) -> str:
    logging.info(f"Запуск matugen для аналізу зображення: {image_path}")
    try:
        # `--source-color-index 0` для уникнення інтерактивного запиту вибору кольору
        result = subprocess.run(
            ["matugen", "image", image_path, "-m", "dark", "--json", "hex", "--quiet", "--source-color-index", "0"],
            capture_output=True, text=True, timeout=15
        )
        out = result.stdout.strip()

        if result.returncode != 0:
            logging.warning(f"matugen повернув код помилки {result.returncode}. Спроба розпарсити вивід...")

        try:
            data = json.loads(out)
            colors = data.get("colors", {})

            # Перебираємо ключі в порядку пріоритетності для пошуку найкращого акценту
            for key in ("primary", "tertiary", "secondary", "source_color"):
                node = colors.get(key)
                if isinstance(node, dict):
                    for variant in ("default", "light", "dark"):
                        v = node.get(variant)
                        if isinstance(v, dict) and v.get("color"):
                            color = v["color"]
                            logging.info(f"Знайдено колір '{key}' ({variant}): {color}")
                            return color
        except (json.JSONDecodeError, AttributeError) as e:
            logging.debug(f"Не вдалося розпарсити вивід як JSON: {e}")

        # Пошук hex-коду через регулярний вираз
        match = re.search(r"#[0-9a-fA-F]{6}", out)
        if match:
            color = match.group(0)
            logging.info(f"Знайдено hex-колір через регулярний вираз: {color}")
            return color

    except (subprocess.SubprocessError, FileNotFoundError) as e:
        logging.error(f"Помилка виконання або відсутність утиліти matugen: {e}")

    logging.critical("Критична помилка: не вдалося витягти жодного кольору із зображення.")
    sys.exit(1)


def hex_to_hls(hex_color: str):
    hex_color = hex_color.lstrip("#")
    r, g, b = (int(hex_color[i:i+2], 16) / 255 for i in (0, 2, 4))
    return colorsys.rgb_to_hls(r, g, b)


def hls_to_hex(h, l, s):
    r, g, b = colorsys.hls_to_rgb(h % 1.0, max(0, min(1, l)), max(0, min(1, s)))
    return "#{:02x}{:02x}{:02x}".format(round(r * 255), round(g * 255), round(b * 255))


def build_palette(source_hex: str) -> dict:
    logging.info(f"Початок генерації палітри на основі базового кольору: {source_hex}")
    h, l, s = hex_to_hls(source_hex)

    bg_hue = h
    bg_sat = min(s, 0.45)
    ui_sat = max(s, 0.50)

    palette = {
        "bg0": hls_to_hex(bg_hue, 0.04, bg_sat),
        "bg1": hls_to_hex(bg_hue, 0.07, bg_sat),
        "bg2": hls_to_hex(bg_hue, 0.11, bg_sat),
        "bg3": hls_to_hex(bg_hue, 0.15, bg_sat),
        "bg4": hls_to_hex(bg_hue, 0.20, bg_sat),

        "fg": hls_to_hex(bg_hue, 0.88, min(s, 0.20)),

        "accent": hls_to_hex(h, max(l, 0.65), max(s, 0.70)),

        "red":    hls_to_hex((h - 0.05) % 1.0, 0.65, ui_sat),
        "orange": hls_to_hex((h + 0.05) % 1.0, 0.70, ui_sat),
        "yellow": hls_to_hex((h + 0.15) % 1.0, 0.70, ui_sat),
        "green":  hls_to_hex((h + 0.35) % 1.0, 0.65, ui_sat),
        "aqua":   hls_to_hex((h + 0.45) % 1.0, 0.55, ui_sat),
        "blue":   hls_to_hex((h + 0.55) % 1.0, 0.65, ui_sat),
        "purple": hls_to_hex((h + 0.75) % 1.0, 0.75, ui_sat),

        "grey0": hls_to_hex(bg_hue, 0.20, bg_sat),
        "grey1": hls_to_hex(bg_hue, 0.35, bg_sat),
        "grey2": hls_to_hex(bg_hue, 0.70, bg_sat),
    }

    logging.info("Кольорову палітру успішно розраховано.")
    return palette


def write_hypr_colors(p: dict):
    logging.info(f"Запис кольорів Hyprland у: {HYPR_COLORS_LUA}")
    try:
        lines = ['local M = {}\n']
        for name, value in p.items():
            lines.append(f'M.{name} = "{value}"\n')
        lines.append('\nreturn M\n')

        os.makedirs(os.path.dirname(HYPR_COLORS_LUA), exist_ok=True)
        with open(HYPR_COLORS_LUA, "w") as f:
            f.writelines(lines)
        logging.info("Конфігурацію Hyprland успішно збережено.")
    except Exception as e:
        logging.error(f"Не вдалося записати файл конфігурації Hyprland: {e}")


def write_kitty_colors(p: dict):
    logging.info(f"Запис кольорів Kitty у: {KITTY_COLORS_CONF}")
    try:
        mapping = {
            "background": p["bg0"],
            "foreground": p["fg"],
            "cursor": p["accent"],
            "color0": p["bg3"], "color8": p["grey0"],
            "color1": p["red"], "color9": p["red"],
            "color2": p["green"], "color10": p["green"],
            "color3": p["yellow"], "color11": p["yellow"],
            "color4": p["blue"], "color12": p["blue"],
            "color5": p["purple"], "color13": p["purple"],
            "color6": p["aqua"], "color14": p["aqua"],
            "color7": p["fg"], "color15": p["fg"],
        }

        os.makedirs(os.path.dirname(KITTY_COLORS_CONF), exist_ok=True)
        with open(KITTY_COLORS_CONF, "w") as f:
            for key, value in mapping.items():
                f.write(f"{key} {value}\n")
        logging.info("Конфігурацію Kitty успішно збережено.")
    except Exception as e:
        logging.error(f"Не вдалося записати файл конфігурації Kitty: {e}")


def write_quickshell_colors(p: dict):
    logging.info(f"Запис кольорів Quickshell у: {QUICKSHELL_COLORS_JSON}")
    try:
        os.makedirs(os.path.dirname(QUICKSHELL_COLORS_JSON), exist_ok=True)
        with open(QUICKSHELL_COLORS_JSON, "w") as f:
            json.dump(p, f, indent=2)
        logging.info("Конфігурацію Quickshell успішно збережено.")
    except Exception as e:
        logging.error(f"Не вдалося записати файл кольорів Quickshell: {e}")


def write_rofi_colors(p: dict):
    logging.info(f"Запис кольорів Rofi у: {ROFI_COLORS_RASI}")
    try:
        lines = [
            "/* Automatically generated by wallcolors.py */\n",
            "* {\n",
            f"    background: {p['bg0']};\n",
            f"    background-alt: {p['bg2']};\n",
            f"    foreground: {p['fg']};\n",
            f"    accent: {p['accent']};\n",
            f"    active: {p['aqua']};\n",
            f"    urgent: {p['red']};\n",
            "}\n"
        ]
        os.makedirs(os.path.dirname(ROFI_COLORS_RASI), exist_ok=True)
        with open(ROFI_COLORS_RASI, "w") as f:
            f.writelines(lines)
        logging.info("Конфігурацію Rofi успішно збережено.")
    except Exception as e:
        logging.error(f"Не вдалося записати файл конфігурації Rofi: {e}")


def write_hyprlock_colors(p: dict, wallpaper_path: str):
    logging.info(f"Запис кольорів Hyprlock у: {HYPRLOCK_COLORS_CONF}")
    try:
        def to_rgba(hex_str, alpha=1.0):
            hex_str = hex_str.lstrip('#')
            r = int(hex_str[0:2], 16)
            g = int(hex_str[2:4], 16)
            b = int(hex_str[4:6], 16)
            return f"rgba({r}, {g}, {b}, {alpha})"

        lines = [
            "# Automatically generated by wallcolors.py\n",
            f"$bg_color = {to_rgba(p['bg0'])}\n",
            f"$bg_alt = {to_rgba(p['bg2'])}\n",
            f"$fg_color = {to_rgba(p['fg'])}\n",
            f"$accent_color = {to_rgba(p['accent'])}\n",
            f"$red_color = {to_rgba(p['red'])}\n",
            f"$green_color = {to_rgba(p['green'])}\n",
            f"$grey_color = {to_rgba(p['grey1'])}\n",
            "$font = JetBrainsMono Nerd Font\n",
            f"$wallpaper_path = {wallpaper_path}\n",
        ]
        os.makedirs(os.path.dirname(HYPRLOCK_COLORS_CONF), exist_ok=True)
        with open(HYPRLOCK_COLORS_CONF, "w") as f:
            f.writelines(lines)
        logging.info("Конфігурацію Hyprlock успішно збережено.")
    except Exception as e:
        logging.error(f"Не вдалося записати файл кольорів Hyprlock: {e}")

def write_swaync_colors(p: dict):
    logging.info(f"Запис кольорів SwayNC у: {SWAYNC_COLORS_CSS}")
    try:
        lines = [
            "/* Automatically generated by wallcolors.py */\n",
            f"@define-color bg0 {p['bg0']};\n",
            f"@define-color bg1 {p['bg1']};\n",
            f"@define-color bg2 {p['bg2']};\n",
            f"@define-color bg3 {p['bg3']};\n",
            f"@define-color fg {p['fg']};\n",
            f"@define-color accent {p['accent']};\n",
            f"@define-color urgent {p['red']};\n",
        ]
        os.makedirs(os.path.dirname(SWAYNC_COLORS_CSS), exist_ok=True)
        with open(SWAYNC_COLORS_CSS, "w") as f:
            f.writelines(lines)
        logging.info("Конфігурацію SwayNC успішно збережено.")
    except Exception as e:
        logging.error(f"Не вдалося записати файл конфігурації SwayNC: {e}")


def write_gtk_colors(p: dict):
    """
    Генерує @define-color для GTK3/GTK4 (Nautilus, GNOME Files тощо)
    на основі семантичних імен libadwaita: window/view/headerbar/
    sidebar/card/popover + accent/destructive/warning/success/error.
    """
    logging.info(f"Запис кольорів GTK/Nautilus у: {GTK4_COLORS_CSS} та {GTK3_COLORS_CSS}")
    try:
        lines = [
            "/* Automatically generated by wallcolors.py */\n",
            "\n",
            f"@define-color window_bg_color {p['bg0']};\n",
            f"@define-color window_fg_color {p['fg']};\n",
            "\n",
            f"@define-color view_bg_color {p['bg1']};\n",
            f"@define-color view_fg_color {p['fg']};\n",
            "\n",
            f"@define-color headerbar_bg_color {p['bg2']};\n",
            f"@define-color headerbar_fg_color {p['fg']};\n",
            "\n",
            f"@define-color sidebar_bg_color {p['bg0']};\n",
            f"@define-color sidebar_fg_color {p['fg']};\n",
            "\n",
            f"@define-color card_bg_color {p['bg3']};\n",
            f"@define-color card_fg_color {p['fg']};\n",
            "\n",
            f"@define-color popover_bg_color {p['bg3']};\n",
            f"@define-color popover_fg_color {p['fg']};\n",
            "\n",
            f"@define-color accent_color {p['accent']};\n",
            f"@define-color accent_bg_color {p['accent']};\n",
            f"@define-color accent_fg_color {p['bg0']};\n",
            "\n",
            f"@define-color destructive_color {p['red']};\n",
            f"@define-color destructive_bg_color {p['red']};\n",
            f"@define-color destructive_fg_color {p['fg']};\n",
            "\n",
            f"@define-color warning_color {p['yellow']};\n",
            f"@define-color warning_bg_color {p['yellow']};\n",
            f"@define-color warning_fg_color {p['bg0']};\n",
            "\n",
            f"@define-color success_color {p['green']};\n",
            f"@define-color success_bg_color {p['green']};\n",
            f"@define-color success_fg_color {p['bg0']};\n",
            "\n",
            f"@define-color error_color {p['red']};\n",
            f"@define-color error_bg_color {p['red']};\n",
            f"@define-color error_fg_color {p['fg']};\n",
            "\n",
            f"@define-color borders alpha({p['fg']}, 0.12);\n",
        ]

        for path in (GTK4_COLORS_CSS, GTK3_COLORS_CSS):
            os.makedirs(os.path.dirname(path), exist_ok=True)
            with open(path, "w") as f:
                f.writelines(lines)

        logging.info("Конфігурацію GTK/Nautilus успішно збережено.")
    except Exception as e:
        logging.error(f"Не вдалося записати файли кольорів GTK: {e}")


def write_fish_colors(p: dict):
    logging.info(f"Запис кольорів Fish у: {FISH_COLORS_FISH}")
    try:
        lines = ["# Automatically generated by wallcolors.py\n"]
        for name, value in p.items():
            lines.append(f'set -gx COLOR_{name.upper()} "{value}"\n')

        os.makedirs(os.path.dirname(FISH_COLORS_FISH), exist_ok=True)
        with open(FISH_COLORS_FISH, "w") as f:
            f.writelines(lines)
        logging.info("Конфігурацію Fish успішно збережено.")
    except Exception as e:
        logging.error(f"Не вдалося записати файл кольорів Fish: {e}")


def write_firefox_colors(p: dict):
    """
    Генерує CSS-змінні для userChrome.css / userContent.css.
    Файл живе поза профілем Firefox (~/.config/firefox-colors.css),
    а userChrome.css підʼєднує його через @import url("file://...").
    """
    logging.info(f"Запис кольорів Firefox у: {FIREFOX_COLORS_CSS}")
    try:
        lines = [
            "/* Automatically generated by wallcolors.py — do not edit by hand */\n",
            ":root {\n",
        ]
        for name, value in p.items():
            lines.append(f"  --wc-{name}: {value};\n")

        def hex_to_rgb_triplet(hex_str):
            hex_str = hex_str.lstrip("#")
            r = int(hex_str[0:2], 16)
            g = int(hex_str[2:4], 16)
            b = int(hex_str[4:6], 16)
            return f"{r}, {g}, {b}"

        # RGB triplets so userChrome.css can build rgba() with custom alpha
        for name in ("bg0", "bg1", "bg2", "bg3", "fg", "accent"):
            lines.append(f"  --wc-{name}-rgb: {hex_to_rgb_triplet(p[name])};\n")

        lines.append("}\n")

        os.makedirs(os.path.dirname(FIREFOX_COLORS_CSS), exist_ok=True)
        with open(FIREFOX_COLORS_CSS, "w") as f:
            f.writelines(lines)
        logging.info("Конфігурацію Firefox успішно збережено.")
    except Exception as e:
        logging.error(f"Не вдалося записати файл кольорів Firefox: {e}")


def push_to_kitty():
    logging.info("Надсилання команди оновлення кольорів для запущених інстансів Kitty...")
    try:
        result = subprocess.run(
            ["kitty", "@", "set-colors", "--all", "--configured", KITTY_COLORS_CONF],
            capture_output=True, check=False, timeout=5
        )
        if result.returncode == 0:
            logging.info("Кольори у Kitty успішно оновлено на льоту.")
        else:
            logging.warning(f"Команда kitty @ повернула код {result.returncode}. Можливо, віддалене керування не налаштоване.")
    except (subprocess.SubprocessError, FileNotFoundError) as e:
        logging.warning(f"Не вдалося зв'язатися з Kitty через сокет: {e}")


def reload_swaync():
    logging.info("Перезапуск конфігурації SwayNC (CSS)...")
    try:
        subprocess.run(["swaync-client", "-rs"], check=False, timeout=5)
        logging.info("SwayNC успішно оновлено.")
    except (subprocess.SubprocessError, FileNotFoundError) as e:
        logging.warning(f"Не вдалося перезапустити SwayNC: {e}")


def main():
    logging.info("=== Запуск скрипту генерації кольорів ===")
    if len(sys.argv) < 2:
        logging.critical("Помилка використання: Скрипту не передано шлях до шпалери.")
        print("Usage: wallcolors.py <image_path>", file=sys.stderr)
        sys.exit(1)

    image_path = sys.argv[1]
    if not os.path.isfile(image_path):
        logging.critical(f"Помилка: Файл не знайдено за вказаним шляхом: {image_path}")
        sys.exit(1)

    source_color = get_source_color(image_path)
    palette = build_palette(source_color)

    write_hypr_colors(palette)
    write_kitty_colors(palette)
    write_quickshell_colors(palette)
    write_rofi_colors(palette)
    write_hyprlock_colors(palette, image_path)
    write_swaync_colors(palette)
    write_gtk_colors(palette)
    write_fish_colors(palette)
    write_firefox_colors(palette)

    push_to_kitty()
    reload_swaync()

    logging.info("=== Генерацію кольорів успішно завершено ===")


if __name__ == "__main__":
    main()
