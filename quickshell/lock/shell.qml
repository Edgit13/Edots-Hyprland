import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "root:/"

ShellRoot {
    id: root

    readonly property string currentUser: Quickshell.env("USER") || Quickshell.env("LOGNAME") || ""

    Auth {
        id: pamAuth
        user: root.currentUser
        onSucceeded: sessionLock.locked = false
    }

    function doLock(): void {
        sessionLock.locked = true
    }

    WlSessionLock {
        id: sessionLock
        locked: true

        WlSessionLockSurface {
            id: lockSurface
            color: "#160f0a"

            LockSurface {
                anchors.fill: parent
                auth: pamAuth
            }
        }
    }

    IpcHandler {
        target: "lock"
        function lock(): void {
            root.doLock()
        }
    }
}
