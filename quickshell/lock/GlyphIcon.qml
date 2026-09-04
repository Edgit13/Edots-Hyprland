import QtQuick

Text {
    required property string glyph

    text: glyph
    color: Colors.fg
    font.family: "Material Symbols Rounded"
    font.pixelSize: 18
    verticalAlignment: Text.AlignVCenter
    horizontalAlignment: Text.AlignHCenter
}
