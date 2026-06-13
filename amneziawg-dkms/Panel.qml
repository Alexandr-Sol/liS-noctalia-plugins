import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Widgets
import qs.Services.UI

Item {
    id: root

    property var pluginApi: null
    property ShellScreen screen
    readonly property var geometryPlaceholder: panelContainer
    readonly property bool allowAttach: true
    readonly property var main: pluginApi?.mainInstance ?? null
    readonly property var pluginSettings: pluginApi?.pluginSettings ?? ({})
    readonly property var profiles: main?.profiles ?? []
    readonly property bool isConnected: main?.isConnected ?? false
    readonly property bool isLoading: main?.isLoading ?? false
    readonly property string activeProfile: main?.activeProfile ?? ""
    readonly property string defaultProfileName: pluginSettings.defaultProfileName ?? ""
    readonly property bool isZapretActive: main?.isZapretActive ?? false
    readonly property bool isZapretLoading: main?.isZapretLoading ?? false

    property bool showSettings: false

    property real contentPreferredWidth: Math.round(480 * Style.uiScaleRatio)
    property real contentPreferredHeight: mainColumn.implicitHeight + Style.marginL * 2

    function setDefaultProfile(name) {
        pluginApi.pluginSettings.defaultProfileName = name
        pluginApi.saveSettings()
    }

    Component.onCompleted: {
        if (main) main.loadProfiles()
    }

    Rectangle {
        id: panelContainer
        anchors.fill: parent
        color: "transparent"

        ColumnLayout {
            id: mainColumn
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: Style.marginL
            spacing: Style.marginM

            // HEADER
            NBox {
                Layout.fillWidth: true
                Layout.preferredHeight: Math.round(header.implicitHeight + Style.marginM * 2 + 1)

                RowLayout {
                    id: header
                    anchors.fill: parent
                    anchors.margins: Style.marginM
                    spacing: Style.marginM

                    NIcon {
                        icon: root.showSettings ? "settings" : "key"
                        pointSize: Style.fontSizeXXL
                        color: root.showSettings ? Color.mOnSurfaceVariant : (root.isConnected ? Color.mPrimary : Color.mOnSurfaceVariant)
                        Behavior on color { ColorAnimation { duration: 200; easing.type: Easing.OutCubic } }
                    }

                    NLabel {
                        label: root.showSettings ? pluginApi?.tr("settings.pluginSettings") : "VPN"
                    }

                    NBox { Layout.fillWidth: true }

                    NIconButton {
                        icon: root.showSettings ? "shield" : "settings"
                        tooltipText: root.showSettings ? "VPN" : pluginApi?.tr("settings.pluginSettings")
                        baseSize: Style.baseWidgetSize * 0.8
                        onClicked: root.showSettings = !root.showSettings
                    }

                    NIconButton {
                        icon: "close"
                        tooltipText: pluginApi?.tr("common.close")
                        baseSize: Style.baseWidgetSize * 0.8
                        onClicked: pluginApi.closePanel(pluginApi.panelOpenScreen)
                    }
                }
            }

            // CONTENT / SETTINGS SWITCHER
            // Height uses declarative binding dependent on showSettingsHeight property,
            // which is updated via ScriptAction at the invisible midpoint of each transition.
            // This prevents binding destruction and avoids "flicker" while maintaining
            // synchronous height updates when panel size changes.
            Item {
                id: viewSwitcher
                Layout.fillWidth: true
                
                property bool showSettingsHeight: false
                implicitHeight: showSettingsHeight ? settingsPane.implicitHeight : mainPane.implicitHeight

                states: [
                    State { name: "main";     when: !root.showSettings },
                    State { name: "settings"; when:  root.showSettings }
                ]

                transitions: [
                    Transition {
                        from: "main"; to: "settings"
                        SequentialAnimation {
                            // 1. Fade out main content
                            NumberAnimation { target: mainPane; property: "opacity"; to: 0; duration: 150; easing.type: Easing.InCubic }
                            // 2. At the invisible midpoint: snap height via property and reset settings opacity
                            ScriptAction { script: { viewSwitcher.showSettingsHeight = true; settingsPane.opacity = 0 } }
                            // 3. Fade in settings
                            NumberAnimation { target: settingsPane; property: "opacity"; to: 1; duration: 200; easing.type: Easing.OutCubic }
                        }
                    },
                    Transition {
                        from: "settings"; to: "main"
                        SequentialAnimation {
                            // 1. Fade out settings
                            NumberAnimation { target: settingsPane; property: "opacity"; to: 0; duration: 150; easing.type: Easing.InCubic }
                            // 2. At the invisible midpoint: snap height via property and reset main opacity
                            ScriptAction { script: { viewSwitcher.showSettingsHeight = false; mainPane.opacity = 0 } }
                            // 3. Fade in main content
                            NumberAnimation { target: mainPane; property: "opacity"; to: 1; duration: 200; easing.type: Easing.OutCubic }
                        }
                    }
                ]

                // MAIN VIEW — always rendered (no visible binding), opacity-managed by transitions
                ColumnLayout {
                    id: mainPane
                    width: parent.width
                    spacing: Style.marginM
                    enabled: opacity > 0.01

                    // PROFILES LIST
                    ColumnLayout {
                        visible: profiles.length > 0
                        Layout.fillWidth: true
                        spacing: Style.marginM

                        Repeater {
                            model: root.profiles

                            ProfileListItem {
                                pluginApi: root.pluginApi
                                name: modelData.name
                                config: modelData.config
                                isActive: root.isConnected && root.activeProfile === modelData.name
                                isLoading: root.isLoading && root.activeProfile === modelData.name
                                isDefault: root.defaultProfileName === modelData.name || (root.defaultProfileName === "" && index === 0)
                                anyLoading: root.isLoading

                                onConnectClicked: main?.connect(modelData.name, modelData.config)
                                onDisconnectClicked: main?.disconnect()
                                onSetDefaultClicked: root.setDefaultProfile(modelData.name)
                            }
                        }
                    }

                    // EMPTY STATE
                    NBox {
                        visible: profiles.length === 0
                        Layout.fillWidth: true
                        Layout.preferredHeight: Math.round(emptyCol.implicitHeight + Style.marginM * 2 + 1)

                        ColumnLayout {
                            id: emptyCol
                            anchors.fill: parent
                            anchors.margins: Style.marginM
                            spacing: Style.marginL

                            NIcon { icon: "shield"; pointSize: 48; color: Color.mOnSurfaceVariant; Layout.alignment: Qt.AlignHCenter }
                            NText { text: pluginApi?.tr("panel.emptyTitle"); pointSize: Style.fontSizeL; color: Color.mOnSurfaceVariant; Layout.alignment: Qt.AlignHCenter }
                            NText { text: pluginApi?.tr("panel.emptyDescription"); pointSize: Style.fontSizeS; color: Color.mOnSurfaceVariant; Layout.alignment: Qt.AlignHCenter }
                        }
                    }

                    // ZAPRET
                    NBox {
                        visible: main?.hasZapret ?? false
                        Layout.fillWidth: true
                        implicitHeight: Math.round(zapretRow.implicitHeight + Style.marginXL)
                        color: Color.mSurface

                        Rectangle {
                            anchors.fill: parent; radius: parent.radius; color: Color.mPrimary
                            opacity: root.isZapretActive ? 0.15 : 0
                            Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                        }
                        Rectangle {
                            anchors.fill: parent; radius: parent.radius; color: Color.mOnSurface
                            opacity: zapretMouse.containsMouse && !root.isZapretActive ? 0.06 : 0
                            Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                        }

                        // MouseArea на уровне NBox — hit-зона не зависит от scale контента
                        MouseArea {
                            id: zapretMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            enabled: !root.isZapretLoading
                            onClicked: { if (root.isZapretActive) main?.zapretStop(); else main?.zapretStart() }
                        }

                        Item {
                            anchors.fill: parent
                            scale: zapretMouse.pressed ? 0.985 : 1.0
                            Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

                        RowLayout {
                            id: zapretRow
                            width: parent.width - Style.marginXL
                            x: Style.marginM
                            y: Style.marginM
                            spacing: Style.marginS

                            NIcon {
                                id: zapretLockIcon
                                icon: root.isZapretActive ? "lock" : "lock-open"
                                pointSize: Style.fontSizeXXL
                                color: root.isZapretActive ? Color.mPrimary : Color.mOnSurface
                                Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutCubic } }

                                SequentialAnimation {
                                    id: zapretLockAnim
                                    NumberAnimation { target: zapretLockIcon; property: "scale"; to: 0.70; duration: 90; easing.type: Easing.InCubic }
                                    NumberAnimation { target: zapretLockIcon; property: "scale"; to: 1.0; duration: 240; easing.type: Easing.OutBack; easing.overshoot: 1.4 }
                                }
                                Connections { target: root; function onIsZapretActiveChanged() { zapretLockAnim.restart() } }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                NText { text: "Zapret"; pointSize: Style.fontSizeM; font.weight: Style.fontWeightMedium; color: Color.mOnSurface; elide: Text.ElideRight; Layout.fillWidth: true }

                                NText {
                                    id: zapretStatusLabel
                                    text: (root.isZapretActive ? pluginApi?.tr("zapret.active") : pluginApi?.tr("zapret.inactive")) + " • " + pluginApi?.tr("zapret.dpiBypass")
                                    pointSize: Style.fontSizeXXS
                                    color: root.isZapretActive ? Color.mPrimary : Color.mOnSurfaceVariant
                                    elide: Text.ElideRight; Layout.fillWidth: true
                                    Behavior on color { ColorAnimation { duration: 200; easing.type: Easing.OutCubic } }
                                    SequentialAnimation {
                                        id: zapretStatusFadeAnim
                                        NumberAnimation { target: zapretStatusLabel; property: "opacity"; to: 0.0; duration: 80; easing.type: Easing.InCubic }
                                        NumberAnimation { target: zapretStatusLabel; property: "opacity"; to: 1.0; duration: 160; easing.type: Easing.OutCubic }
                                    }
                                    onTextChanged: zapretStatusFadeAnim.restart()
                                }
                            }

                            NBusyIndicator {
                                visible: root.isZapretLoading; running: visible
                                color: Color.mPrimary; size: Style.baseWidgetSize * 0.5
                                opacity: root.isZapretLoading ? 1.0 : 0.0
                                Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                            }
                        }
                        } // Item scale wrapper
                    }
                }

                // SETTINGS VIEW — always rendered, opacity-managed by transitions
                PanelSettings {
                    id: settingsPane
                    width: parent.width
                    pluginApi: root.pluginApi
                    main: root.main
                    opacity: 0
                    enabled: opacity > 0.01
                }
            }
        }
    }
}
