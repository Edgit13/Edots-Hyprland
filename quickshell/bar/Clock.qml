pragma ComponentBehavior: Bound

import Quickshell
import QtQuick

Text {
    text: Qt.formatDateTime(clock.date, "hh:mm")
    color: Colors.accent
    font {
        family: "SF Mono"
        letterSpacing: -0.5
        pixelSize: 15
        weight: 600
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }
}
