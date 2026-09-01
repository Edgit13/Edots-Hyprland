pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property string query: ""
    property int selectedIndex: 0
    property var appIndex: []

    readonly property var allApps: {
        const q = query.trim().toLowerCase()
        const apps = appIndex.filter(app => !!app && !!app.name)

        if (!q)
            return apps

        return apps.filter(app => {
            const haystack = [
                app.name,
                app.genericName,
                app.id,
                app.exec,
                app.categories
            ].join(" ").toLowerCase()
            return haystack.includes(q)
        })
    }

    readonly property var results: allApps

    onQueryChanged: selectedIndex = 0
    onResultsChanged: {
        if (selectedIndex >= results.length)
            selectedIndex = Math.max(0, results.length - 1)
    }

    Process {
        id: scanAppsProc

        command: ["sh", "-c", "python3 - <<'PY'\nimport configparser, json, os, shlex\nfrom pathlib import Path\n\nsearch_dirs = []\nfor env_var in ('XDG_DATA_HOME',):\n    value = os.environ.get(env_var)\n    if value:\n        search_dirs.append(Path(value) / 'applications')\nsearch_dirs.append(Path.home() / '.local/share/applications')\nfor base in os.environ.get('XDG_DATA_DIRS', '/usr/local/share:/usr/share').split(':'):\n    if base:\n        search_dirs.append(Path(base) / 'applications')\n\napps_by_id = {}\nfor directory in search_dirs:\n    if not directory.is_dir():\n        continue\n    for path in directory.rglob('*.desktop'):\n        desktop_id = path.name
        cp = configparser.ConfigParser(interpolation=None, strict=False)
        cp.optionxform = str
        try:
            cp.read(path, encoding='utf-8')
        except Exception:
            continue
        if 'Desktop Entry' not in cp:
            continue
        sec = cp['Desktop Entry']
        if sec.get('Type', '').strip() != 'Application':
            continue
        if sec.get('NoDisplay', '').strip().lower() == 'true':
            continue
        if sec.get('Hidden', '').strip().lower() == 'true':
            continue
        name = sec.get('Name', '').strip()
        exec_line = sec.get('Exec', '').strip()
        if not name or not exec_line:
            continue
        if desktop_id in apps_by_id and str(path).startswith(str(Path.home())):
            pass
        apps_by_id[desktop_id] = {
            'id': desktop_id,
            'name': name,
            'genericName': sec.get('GenericName', '').strip(),
            'icon': sec.get('Icon', '').strip(),
            'exec': exec_line,
            'categories': sec.get('Categories', '').strip(),
            'path': str(path),
        }
\napps = sorted(apps_by_id.values(), key=lambda app: app['name'].lower())\nprint(json.dumps(apps, ensure_ascii=False))\nPY"]

        stdout: SplitParser {
            onRead: data => {
                try {
                    const parsed = JSON.parse(data)
                    root.appIndex = Array.isArray(parsed) ? parsed : []
                } catch (error) {
                    console.warn("LauncherService: failed to parse app index", error)
                    root.appIndex = []
                }
            }
        }
    }

    function moveSelection(delta) {
        if (results.length === 0) return
        selectedIndex = (selectedIndex + delta + results.length) % results.length
    }

    function launch(app) {
        if (!app || !app.path)
            return

        Quickshell.execDetached(["gtk-launch", app.id.replace(/\.desktop$/, "")])
    }

    function launchSelected() {
        if (results.length === 0 || selectedIndex >= results.length) return
        launch(results[selectedIndex])
    }

    function cleanDesktopId(value) {
        if (typeof value !== "string")
            return ""

        let cleaned = value.trim()
        if (!cleaned)
            return ""

        if (cleaned.endsWith(".desktop"))
            cleaned = cleaned.slice(0, -8)

        const parts = cleaned.split(".").filter(Boolean)
        if (parts.length > 1)
            cleaned = parts[parts.length - 1]

        cleaned = cleaned.replace(/[._-]+/g, " ").trim()
        if (!cleaned)
            return ""

        return cleaned
            .split(/\s+/)
            .filter(Boolean)
            .map(part => part.charAt(0).toUpperCase() + part.slice(1))
            .join(" ")
    }

    function entryName(app) {
        if (!app)
            return ""

        const candidates = [cleanDesktopId(app.id), app.name, app.genericName]
        for (const candidate of candidates) {
            if (typeof candidate === "string") {
                const value = candidate.trim()
                if (value)
                    return value
            }
        }

        return ""
    }

    function reset() {
        query = ""
        selectedIndex = 0
        if (!scanAppsProc.running)
            scanAppsProc.running = true
    }

    Component.onCompleted: scanAppsProc.running = true
}
