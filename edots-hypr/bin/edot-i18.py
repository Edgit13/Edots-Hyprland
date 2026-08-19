#!/usr/bin/env python3
import sys
from pathlib import Path

SETTINGS_PATH = (Path(__file__).resolve().parent.parent / "settings.edot")

def parse_settings(path: Path):
    data = {}
    current_section = None
    in_section = False

    for raw in path.read_text(encoding="utf-8").splitlines():
        line = raw.strip()
        if not line:
            continue

        # секція: {theme}:
        if line.startswith("{") and "}" in line:
            end = line.find("}")
            sec = line[:end+1]  # "{theme}"
            # валідність: або закінчується на "{theme}:", або просто "{theme}"
            current_section = sec
            data.setdefault(current_section, {})
            in_section = True
            continue

        # лише якщо ми в секції
        if current_section and ":" in raw:
            # беремо ключ: значення (враховуємо, що raw може мати відступи)
            left, right = raw.split(":", 1)
            key = left.strip()
            value = right.strip()
            if key and value != "":
                data[current_section][key] = value

    return data

def main(argv):
    settings = parse_settings(SETTINGS_PATH)

    if argv[1:] == ["__dump__"]:
        print("SECTIONS", file=sys.stderr)
        for k in settings:
            print(k, settings[k], file=sys.stderr)
        return 0

    if len(argv) < 4:
        print("usage:", file=sys.stderr)
        print("  edot-i18.py -t {section} key", file=sys.stderr)
        print("  edot-i18.py -t -m {section} key1 key2 ...", file=sys.stderr)
        return 2

    if argv[1] != "-t":
        return 2

    if argv[2] == "-m":
        section = argv[3]
        keys = argv[4:]
        sec = settings.get(section, {})
        for k in keys:
            if k in sec:
                print(f"{k}={sec[k]}")
        return 0

    section = argv[2]
    key = argv[3]
    sec = settings.get(section, {})
    print(sec.get(key, ""))
    return 0

if __name__ == "__main__":
    raise SystemExit(main(sys.argv))

