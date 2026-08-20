import Quickshell
import QtQuick

Text {
    id: root

    text: Qt.formatDateTime(new Date(), "hh:mm")
    color: Colors.accent
    font {
        family: "SF Mono"
        letterSpacing: -0.5
        pixelSize: 15
        weight: 600
    }

    // Звичайний polling-таймер замість SystemClock: він не завʼязаний на
    // прорахований наперед дедлайн і тому не "зависає" після сну/блокування
    // екрана. Навіть якщо тік пропущено під час suspend, наступний (макс.
    // за 10с) сам підхопить правильний час — без накопичення розсинхрону.
    Timer {
        interval: 10000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.text = Qt.formatDateTime(new Date(), "hh:mm")
    }

    // Додатковий страхувальний тригер: коли елемент знову стає видимим
    // (панель піднялась з невидимого/призупиненого стану після сну чи
    // розлоку), одразу форсуємо оновлення, не чекаючи наступного тіку.
    onVisibleChanged: if (visible) text = Qt.formatDateTime(new Date(), "hh:mm")
}