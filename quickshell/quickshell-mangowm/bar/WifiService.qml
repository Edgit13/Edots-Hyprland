pragma Singleton
import Quickshell
import Quickshell.Io
import Quickshell.Networking
import QtQuick

// ==========================================================================
// WifiService.qml — бекенд повного Wi-Fi менеджера для WifiSurface.qml.
// Увімк/вимк Wi-Fi перевикористовує Networking.wifiEnabled (той самий
// реактивний модуль, що вже дає Network.qml/LinkSurface.qml) — окремого
// опитування для on/off НЕ додано. Сканування списку мереж і конект/
// дисконект тут з нуля, бо в проєкті цього раніше не було ніде.
//
// nmcli-команди повністю в цьому файлі — WifiSurface.qml не містить
// жодного парсингу шелл-виводу, тільки читає готові властивості.
// ==========================================================================

Singleton {
    id: root

    // "idle" | "scanning" | "connecting" | "connected" | "failed" | "passwordRequired"
    property string connectionState: "idle"
    property string connectionError: ""
    property string pendingSsid: ""

    property bool scanning: false
    property var networks: [] // [{ ssid, signal, security, secured, inUse }]

    readonly property var currentNetwork: networks.find(n => n.inUse) || null

    function scan() {
        if (scanning) return
        scanning = true
        rescanProc.running = true
    }

    Process {
        id: rescanProc
        command: ["nmcli", "device", "wifi", "rescan"]
        onExited: listProc.running = true
    }

    Process {
        id: listProc
        command: ["nmcli", "-t", "-f", "SSID,SIGNAL,SECURITY,IN-USE", "device", "wifi", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                const parsed = []
                const lines = text.split("\n")
                for (const line of lines) {
                    if (!line.trim()) continue
                    const parts = line.split(":")
                    const ssid = parts[0]
                    if (!ssid) continue // приховані/порожні SSID пропускаємо
                    const signal = parseInt(parts[1], 10) || 0
                    const security = (parts[2] || "").trim()
                    const inUse = (parts[3] || "").trim() === "*"

                    // Уникаємо дублікатів (та сама мережа з кількох BSSID)
                    if (parsed.some(n => n.ssid === ssid)) continue

                    parsed.push({
                        ssid: ssid,
                        signal: signal,
                        security: security,
                        secured: security !== "" && security !== "--",
                        inUse: inUse
                    })
                }
                parsed.sort((a, b) => b.signal - a.signal)
                root.networks = parsed
                root.scanning = false
            }
        }
    }

    function toggleWifi() {
        wifiToggleProc.command = ["nmcli", "radio", "wifi", Networking.wifiEnabled ? "off" : "on"]
        wifiToggleProc.running = true
    }
    Process { id: wifiToggleProc }

    function connectTo(ssid, password) {
        root.pendingSsid = ssid
        root.connectionState = "connecting"
        root.connectionError = ""

        connectProc.command = password
            ? ["nmcli", "device", "wifi", "connect", ssid, "password", password]
            : ["nmcli", "device", "wifi", "connect", ssid]
        connectProc.running = true
    }

    Process {
        id: connectProc
        stdout: StdioCollector {}
        stderr: StdioCollector {
            id: connectErr
        }
        onExited: (exitCode) => {
            if (exitCode === 0) {
                root.connectionState = "connected"
                root.scan()
            } else {
                root.connectionState = "failed"
                // Коротке повідомлення, без паролю (пароль ніде не логуємо
                // і не зберігаємо — nmcli сам керує збереженими профілями).
                root.connectionError = "Не вдалося підключитись"
            }
        }
    }

    function requestConnect(ssid) {
        const net = root.networks.find(n => n.ssid === ssid)
        if (net && net.secured) {
            root.pendingSsid = ssid
            root.connectionState = "passwordRequired"
        } else {
            root.connectTo(ssid, "")
        }
    }

    function disconnectCurrent() {
        if (!root.currentNetwork) return
        disconnectProc.command = ["nmcli", "connection", "down", "id", root.currentNetwork.ssid]
        disconnectProc.running = true
    }

    Process {
        id: disconnectProc
        onExited: root.scan()
    }

    function cancelPassword() {
        root.connectionState = "idle"
        root.pendingSsid = ""
    }
}
