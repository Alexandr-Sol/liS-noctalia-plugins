import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

NBox {
    id: root

    property var pluginApi: null
    property string name: ""
    property string config: ""
    property bool isActive: false
    property bool isLoading: false
    property bool isDefault: false
    property bool anyLoading: false

    signal connectClicked
    signal disconnectClicked
    signal setDefaultClicked

    Layout.fillWidth: true
    implicitHeight: Math.round(rowLayout.implicitHeight + Style.marginXL)
    color: Color.mSurface

    // Active state overlay
    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        color: Color.mPrimary
        opacity: root.isActive ? 0.15 : 0
        Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
    }

    // Hover overlay — containsMouse от MouseArea снаружи wrapper'а, не зависит от scale
    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        color: Color.mOnSurface
        opacity: itemMouse.containsMouse && !root.isActive ? 0.06 : 0
        Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
    }

    // MouseArea на уровне NBox (не внутри scaled wrapper'а) — hit-зона всегда полного размера
    MouseArea {
        id: itemMouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        enabled: !root.anyLoading
        onClicked: (mouse) => {
            if (mouse.button === Qt.RightButton) { root.setDefaultClicked(); return }
            if (root.isActive) root.disconnectClicked()
            else root.connectClicked()
        }
    }

    // Визуальный wrapper масштабируется при нажатии — MouseArea снаружи и не затронута
    Item {
        id: contentWrapper
        anchors.fill: parent
        scale: itemMouse.pressed ? 0.985 : 1.0
        Behavior on scale {
            NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
        }

        function detectProtocol(cfg) {
            return "AWG"
        }

        readonly property string protocol: detectProtocol(root.config)

        readonly property string statusText: {
            if (root.isLoading && root.isActive)
                return (root.pluginApi?.tr("common.disconnecting") ?? "Disconnecting…") + " • " + protocol
            if (root.isLoading)
                return (root.pluginApi?.tr("common.connecting") ?? "Connecting…") + " • " + protocol
            if (root.isActive)
                return root.pluginApi?.tr("common.connected") + " • " + protocol
            return root.pluginApi?.tr("common.disconnected") + " • " + protocol
        }

        RowLayout {
            id: rowLayout
            width: parent.width - Style.marginXL
            x: Style.marginM
            y: Style.marginM
            spacing: Style.marginS

            NIcon {
                id: lockIcon
                icon: root.isActive ? "lock" : "lock-open"
                pointSize: Style.fontSizeXXL
                color: root.isActive ? Color.mPrimary : Color.mOnSurface

                Behavior on color {
                    ColorAnimation { duration: 220; easing.type: Easing.OutCubic }
                }

                SequentialAnimation {
                    id: lockBounceAnim
                    NumberAnimation { target: lockIcon; property: "scale"; to: 0.70; duration: 90; easing.type: Easing.InCubic }
                    NumberAnimation { target: lockIcon; property: "scale"; to: 1.0; duration: 240; easing.type: Easing.OutBack; easing.overshoot: 1.4 }
                }

                Connections {
                    target: root
                    function onIsActiveChanged() { lockBounceAnim.restart() }
                    function onIsLoadingChanged() { if (root.isLoading) lockBounceAnim.restart() }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                RowLayout {
                    spacing: Style.marginXS
                    Layout.fillWidth: true

                    NIcon {
                        icon: "star-filled"
                        pointSize: Style.fontSizeXS
                        color: Color.mPrimary
                        visible: root.isDefault
                    }

                    NText {
                        text: root.name
                        pointSize: Style.fontSizeM
                        font.weight: Style.fontWeightMedium
                        color: Color.mOnSurface
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }

                NText {
                    id: statusLabel
                    text: contentWrapper.statusText
                    pointSize: Style.fontSizeXXS
                    color: root.isActive ? Color.mPrimary : Color.mOnSurfaceVariant
                    elide: Text.ElideRight
                    Layout.fillWidth: true

                    Behavior on color {
                        ColorAnimation { duration: 200; easing.type: Easing.OutCubic }
                    }

                    SequentialAnimation {
                        id: statusFadeAnim
                        NumberAnimation { target: statusLabel; property: "opacity"; to: 0.0; duration: 80; easing.type: Easing.InCubic }
                        NumberAnimation { target: statusLabel; property: "opacity"; to: 1.0; duration: 160; easing.type: Easing.OutCubic }
                    }

                    onTextChanged: statusFadeAnim.restart()
                }
            }

            NBusyIndicator {
                visible: root.isLoading
                running: visible
                color: Color.mPrimary
                size: Style.baseWidgetSize * 0.5
                opacity: root.isLoading ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
            }
        }
    }
}
