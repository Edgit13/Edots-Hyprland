#!/usr/bin/env python3
import configparser
import colorsys
import json
import logging
import os
import re
import subprocess
import sys
from pathlib import Path

HOME = Path.home()
CONFIG = HOME / ".config"

MANGO_DIR = CONFIG / "mango"
MANGO_COLORS_JSON = MANGO_DIR / "colors.json"
MANGO_SWAYLOCK_COLORS = MANGO_DIR / "swaylock" / "colors.conf"
KITTY_COLORS_CONF = CONFIG / "kitty" / "kitty-colors.conf"
GHOSTTY_COLORS_CONF = CONFIG / "ghostty" / "ghostty-colors.conf"
QUICKSHELL_COLORS_JSON = CONFIG / "quickshell" / "colors.json"
ROFI_COLORS_RASI = CONFIG / "rofi" / "colors.rasi"
SWAYNC_COLORS_CSS = CONFIG / "swaync" / "colors.css"
GTK4_COLORS_CSS = CONFIG / "gtk-4.0" / "gtk-colors.css"
GTK3_COLORS_CSS = CONFIG / "gtk-3.0" / "gtk-colors.css"
FISH_COLORS_FISH = CONFIG / "fish" / "fish-colors.fish"
FIREFOX_COLORS_CSS = CONFIG / "firefox-colors.css"
KDEGLOBALS = CONFIG / "kdeglobals"
DOLPHIN_COLOR_SCHEME = HOME / ".local/share/color-schemes/scheme.colors"
LOG_FILE = HOME / "wallcolours.log"

logging.basicConfig(
    level=logging.INFO,
    format="[%(asctime)s] [%(levelname)s] %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
    handlers=[logging.FileHandler(LOG_FILE, encoding="utf-8"), logging.StreamHandler(sys.stdout)],
)


def get_source_color(image_path: str) -> str:
    try:
        result = subprocess.run(
            ["matugen", "image", image_path, "-m", "dark", "--json", "hex", "--quiet", "--source-color-index", "0"],
            capture_output=True,
            text=True,
            timeout=15,
        )
        out = result.stdout.strip()
        if out:
            try:
                data = json.loads(out)
                colors = data.get("colors", {})
                for key in ("primary", "tertiary", "secondary", "source_color"):
                    node = colors.get(key)
                    if isinstance(node, dict):
                        for variant in ("default", "light", "dark"):
                            v = node.get(variant)
                            if isinstance(v, dict) and v.get("color"):
                                return v["color"]
            except Exception:
                pass

            match = re.search(r"#[0-9a-fA-F]{6}", out)
            if match:
                return match.group(0)
    except Exception as exc:
        logging.error("matugen failed: %s", exc)

    raise SystemExit("Could not extract source color from wallpaper")


def hex_to_hls(hex_color: str):
    hex_color = hex_color.lstrip("#")
    r, g, b = (int(hex_color[i:i+2], 16) / 255 for i in (0, 2, 4))
    return colorsys.rgb_to_hls(r, g, b)


def hls_to_hex(h, l, s):
    r, g, b = colorsys.hls_to_rgb(h % 1.0, max(0, min(1, l)), max(0, min(1, s)))
    return "#{:02x}{:02x}{:02x}".format(round(r * 255), round(g * 255), round(b * 255))


def hex_to_rgb(hex_str: str):
    hex_str = hex_str.lstrip("#")
    return tuple(int(hex_str[i:i+2], 16) for i in (0, 2, 4))


def build_palette(source_hex: str) -> dict:
    h, l, s = hex_to_hls(source_hex)
    bg_hue = h
    bg_sat = min(s, 0.45)
    ui_sat = max(s, 0.50)
    return {
        "bg0": hls_to_hex(bg_hue, 0.04, bg_sat),
        "bg1": hls_to_hex(bg_hue, 0.07, bg_sat),
        "bg2": hls_to_hex(bg_hue, 0.11, bg_sat),
        "bg3": hls_to_hex(bg_hue, 0.15, bg_sat),
        "bg4": hls_to_hex(bg_hue, 0.20, bg_sat),
        "fg": hls_to_hex(bg_hue, 0.88, min(s, 0.20)),
        "accent": hls_to_hex(h, max(l, 0.65), max(s, 0.70)),
        "red": hls_to_hex((h - 0.05) % 1.0, 0.65, ui_sat),
        "orange": hls_to_hex((h + 0.05) % 1.0, 0.70, ui_sat),
        "yellow": hls_to_hex((h + 0.15) % 1.0, 0.70, ui_sat),
        "green": hls_to_hex((h + 0.35) % 1.0, 0.65, ui_sat),
        "aqua": hls_to_hex((h + 0.45) % 1.0, 0.55, ui_sat),
        "blue": hls_to_hex((h + 0.55) % 1.0, 0.65, ui_sat),
        "purple": hls_to_hex((h + 0.75) % 1.0, 0.75, ui_sat),
        "grey0": hls_to_hex(bg_hue, 0.20, bg_sat),
        "grey1": hls_to_hex(bg_hue, 0.35, bg_sat),
        "grey2": hls_to_hex(bg_hue, 0.70, bg_sat),
    }


def write(path: Path, content: str):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding="utf-8")


def write_json(path: Path, data):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")


def write_quickshell_colors(p: dict):
    write_json(QUICKSHELL_COLORS_JSON, p)
    write_json(MANGO_COLORS_JSON, p)


def write_kitty_colors(p: dict):
    mapping = {
        "background": p["bg0"], "foreground": p["fg"], "cursor": p["accent"],
        "color0": p["bg3"], "color8": p["grey0"],
        "color1": p["red"], "color9": p["red"],
        "color2": p["green"], "color10": p["green"],
        "color3": p["yellow"], "color11": p["yellow"],
        "color4": p["blue"], "color12": p["blue"],
        "color5": p["purple"], "color13": p["purple"],
        "color6": p["aqua"], "color14": p["aqua"],
        "color7": p["fg"], "color15": p["fg"],
    }
    write(KITTY_COLORS_CONF, "".join(f"{k} {v}\n" for k, v in mapping.items()))


def write_ghostty_colors(p: dict):
    palette = {0: p["bg3"], 8: p["grey0"], 1: p["red"], 9: p["red"], 2: p["green"], 10: p["green"], 3: p["yellow"], 11: p["yellow"], 4: p["blue"], 12: p["blue"], 5: p["purple"], 13: p["purple"], 6: p["aqua"], 14: p["aqua"], 7: p["fg"], 15: p["fg"]}
    lines = ["# Automatically generated by wallcolors.py\n", f"background = {p['bg0']}\n", f"foreground = {p['fg']}\n", f"cursor-color = {p['accent']}\n", f"cursor-text = {p['bg0']}\n", f"selection-background = {p['bg3']}\n", f"selection-foreground = {p['fg']}\n"]
    lines.extend(f"palette = {i}={palette[i]}\n" for i in range(16))
    write(GHOSTTY_COLORS_CONF, "".join(lines))


def write_rofi_colors(p: dict):
    write(ROFI_COLORS_RASI, f"/* Automatically generated by wallcolors.py */\n* {{\n    background: {p['bg0']};\n    background-alt: {p['bg2']};\n    foreground: {p['fg']};\n    accent: {p['accent']};\n    active: {p['aqua']};\n    urgent: {p['red']};\n}}\n")


def write_swaync_colors(p: dict):
    write(SWAYNC_COLORS_CSS, f"/* Automatically generated by wallcolors.py */\n@define-color bg0 {p['bg0']};\n@define-color bg1 {p['bg1']};\n@define-color bg2 {p['bg2']};\n@define-color bg3 {p['bg3']};\n@define-color fg {p['fg']};\n@define-color accent {p['accent']};\n@define-color urgent {p['red']};\n")


def write_gtk_colors(p: dict):
    lines = f"/* Automatically generated by wallcolors.py */\n\n@define-color window_bg_color {p['bg0']};\n@define-color window_fg_color {p['fg']};\n\n@define-color view_bg_color {p['bg1']};\n@define-color view_fg_color {p['fg']};\n\n@define-color headerbar_bg_color {p['bg2']};\n@define-color headerbar_fg_color {p['fg']};\n\n@define-color sidebar_bg_color {p['bg0']};\n@define-color sidebar_fg_color {p['fg']};\n\n@define-color card_bg_color {p['bg3']};\n@define-color card_fg_color {p['fg']};\n\n@define-color popover_bg_color {p['bg3']};\n@define-color popover_fg_color {p['fg']};\n\n@define-color accent_color {p['accent']};\n@define-color accent_bg_color {p['accent']};\n@define-color accent_fg_color {p['bg0']};\n\n@define-color destructive_color {p['red']};\n@define-color destructive_bg_color {p['red']};\n@define-color destructive_fg_color {p['fg']};\n\n@define-color warning_color {p['yellow']};\n@define-color warning_bg_color {p['yellow']};\n@define-color warning_fg_color {p['bg0']};\n\n@define-color success_color {p['green']};\n@define-color success_bg_color {p['green']};\n@define-color success_fg_color {p['bg0']};\n\n@define-color error_color {p['red']};\n@define-color error_bg_color {p['red']};\n@define-color error_fg_color {p['fg']};\n\n@define-color borders alpha({p['fg']}, 0.12);\n"
    write(GTK3_COLORS_CSS, lines)
    write(GTK4_COLORS_CSS, lines)


def write_fish_colors(p: dict):
    write(FISH_COLORS_FISH, "# Automatically generated by wallcolors.py\n" + "".join(f'set -gx COLOR_{k.upper()} "{v}"\n' for k, v in p.items()))


def write_firefox_colors(p: dict):
    def rgb_triplet(v):
        r, g, b = hex_to_rgb(v)
        return f"{r}, {g}, {b}"
    lines = ["/* Automatically generated by wallcolors.py — do not edit by hand */\n", ":root {\n"]
    lines.extend(f"  --wc-{k}: {v};\n" for k, v in p.items())
    for name in ("bg0", "bg1", "bg2", "bg3", "fg", "accent"):
        lines.append(f"  --wc-{name}-rgb: {rgb_triplet(p[name])};\n")
    lines.append("}\n")
    write(FIREFOX_COLORS_CSS, "".join(lines))


def write_swaylock_colors(p: dict, wallpaper_path: str):
    def rgba(hex_str, alpha=1.0):
        r, g, b = hex_to_rgb(hex_str)
        return f"rgba({r}, {g}, {b}, {alpha})"
    lines = [
        "# Automatically generated by mango/scripts/wallcolors.py\n",
        f"set $bg_color {rgba(p['bg0'], 1.0)}\n",
        f"set $bg_alt {rgba(p['bg2'], 1.0)}\n",
        f"set $fg_color {rgba(p['fg'], 1.0)}\n",
        f"set $accent_color {rgba(p['accent'], 1.0)}\n",
        f"set $red_color {rgba(p['red'], 1.0)}\n",
        f"set $green_color {rgba(p['green'], 1.0)}\n",
        f"set $grey_color {rgba(p['grey1'], 1.0)}\n",
        f"set $ring_color {rgba(p['accent'], 0.38)}\n",
        f"set $ring_clear_color {rgba(p['yellow'], 0.90)}\n",
        f"set $ring_caps_color {rgba(p['orange'], 0.90)}\n",
        f"set $ring_ver_color {rgba(p['green'], 0.90)}\n",
        f"set $ring_wrong_color {rgba(p['red'], 0.95)}\n",
        f"set $key_hl_color {rgba(p['fg'], 0.22)}\n",
        f"set $bs_hl_color {rgba(p['red'], 0.82)}\n",
        f"set $layout_text_color {rgba(p['grey2'], 1.0)}\n",
        f"set $glass_fill {rgba(p['bg0'], 0.72)}\n",
        f"set $glass_stroke {rgba(p['fg'], 0.10)}\n",
        f"set $dim_tint {rgba(p['bg1'], 0.24)}\n",
        'set $font "JetBrainsMono Nerd Font"\n',
        f"set $wallpaper_path {wallpaper_path}\n",
    ]
    write(MANGO_SWAYLOCK_COLORS, "".join(lines))


def write_kdeglobals(p: dict):
    cfg = configparser.ConfigParser(interpolation=None)
    cfg.optionxform = str
    if KDEGLOBALS.exists():
        cfg.read(KDEGLOBALS, encoding="utf-8")
    def rgb(hex_str):
        r, g, b = hex_to_rgb(hex_str)
        return f"{r},{g},{b}"
    mapping = {
        ("Colors:Window", "BackgroundNormal"): rgb(p["bg0"]),
        ("Colors:Window", "BackgroundAlternate"): rgb(p["bg2"]),
        ("Colors:Window", "ForegroundNormal"): rgb(p["fg"]),
        ("Colors:Button", "BackgroundNormal"): rgb(p["bg1"]),
        ("Colors:Button", "BackgroundAlternate"): rgb(p["bg3"]),
        ("Colors:Button", "ForegroundNormal"): rgb(p["fg"]),
        ("Colors:Selection", "BackgroundNormal"): rgb(p["accent"]),
        ("Colors:Selection", "ForegroundNormal"): rgb(p["bg0"]),
        ("Colors:View", "BackgroundNormal"): rgb(p["bg1"]),
        ("Colors:View", "ForegroundNormal"): rgb(p["fg"]),
    }
    for (section, key), value in mapping.items():
        if not cfg.has_section(section):
            cfg.add_section(section)
        cfg.set(section, key, value)
    KDEGLOBALS.parent.mkdir(parents=True, exist_ok=True)
    with KDEGLOBALS.open("w", encoding="utf-8") as fh:
        cfg.write(fh, space_around_delimiters=False)


def main():
    if len(sys.argv) != 2:
        raise SystemExit("Usage: wallcolors.py /path/to/wallpaper")
    wallpaper = os.path.abspath(os.path.expanduser(sys.argv[1]))
    color = get_source_color(wallpaper)
    palette = build_palette(color)
    write_quickshell_colors(palette)
    write_kitty_colors(palette)
    write_ghostty_colors(palette)
    write_rofi_colors(palette)
    write_swaync_colors(palette)
    write_gtk_colors(palette)
    write_fish_colors(palette)
    write_firefox_colors(palette)
    write_swaylock_colors(palette, wallpaper)
    write_kdeglobals(palette)
    logging.info("Updated MangoWM color pipeline for wallpaper: %s", wallpaper)


if __name__ == "__main__":
    main()
