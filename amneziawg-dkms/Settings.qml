import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Widgets

ColumnLayout {
    id: root

    property var pluginApi: null
    readonly property var pluginSettings: pluginApi?.pluginSettings ?? pluginApi?.manifest?.metadata?.defaultSettings ?? ({})
    readonly property var main: pluginApi?.mainInstance ?? null
    readonly property var profiles: main?.profiles ?? []

    property string editBarStyle: pluginSettings.barStyle ?? "icon"
    property string editConnectedColor: pluginSettings.connectedColor ?? "primary"
    property string editDisconnectedColor: pluginSettings.disconnectedColor ?? "none"
    property bool disableToastNotifications: pluginSettings.disableToastNotifications ?? false
    property bool quickToggle: pluginSettings.quickToggle ?? false
    property bool autoStopZapret: pluginSettings.autoStopZapret ?? false

    readonly property var barStyleModel: [{
        "key": "icon",
        "name": pluginApi?.tr("settings.barStyleIcon")
    }, {
        "key": "pill",
        "name": pluginApi?.tr("settings.barStylePill")
    }]

    function saveSettings() {
        pluginApi.pluginSettings.barStyle = root.editBarStyle
        pluginApi.pluginSettings.connectedColor = root.editConnectedColor
        pluginApi.pluginSettings.disconnectedColor = root.editDisconnectedColor
        pluginApi.pluginSettings.disableToastNotifications = root.disableToastNotifications
        pluginApi.pluginSettings.quickToggle = root.quickToggle
        pluginApi.pluginSettings.autoStopZapret = root.autoStopZapret
        pluginApi.saveSettings()
    }

    NComboBox {
        label: pluginApi?.tr("settings.barStyle")
        description: pluginApi?.tr("settings.barStyleDescription")
        minimumWidth: 200
        model: root.barStyleModel
        currentKey: root.editBarStyle
        onSelected: (key) => {
            root.editBarStyle = key
            root.saveSettings()
        }
    }

    NColorChoice {
        label: pluginApi?.tr("settings.connectedColor")
        description: pluginApi?.tr("settings.connectedColorDescription")
        currentKey: root.editConnectedColor
        onSelected: (key) => {
            root.editConnectedColor = key
            root.saveSettings()
        }
    }

    NColorChoice {
        label: pluginApi?.tr("settings.disconnectedColor")
        description: pluginApi?.tr("settings.disconnectedColorDescription")
        currentKey: root.editDisconnectedColor
        onSelected: (key) => {
            root.editDisconnectedColor = key
            root.saveSettings()
        }
    }

    NToggle {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.disableToastNotifications")
        description: pluginApi?.tr("settings.disableToastNotificationsDescription")
        checked: root.disableToastNotifications
        onToggled: checked => {
            root.disableToastNotifications = checked
            root.saveSettings()
        }
    }

    NToggle {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.quickToggle")
        description: pluginApi?.tr("settings.quickToggleDescription")
        checked: root.quickToggle
        onToggled: checked => {
            root.quickToggle = checked
            root.saveSettings()
        }
    }

    NToggle {
        visible: main?.hasZapret ?? false
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.autoStopZapret")
        description: pluginApi?.tr("settings.autoStopZapretDescription")
        checked: root.autoStopZapret
        onToggled: checked => {
            root.autoStopZapret = checked
            root.saveSettings()
        }
    }

    // PROFILES SECTION
    NBox {
        Layout.fillWidth: true
        Layout.topMargin: Style.marginM
        Layout.preferredHeight: Math.round(profileSection.implicitHeight + Style.marginL * 2)

        ColumnLayout {
            id: profileSection
            anchors.fill: parent
            anchors.margins: Style.marginM
            spacing: Style.marginM

            RowLayout {
                Layout.fillWidth: true
                NLabel {
                    label: pluginApi?.tr("settings.profiles")
                    Layout.fillWidth: true
                }
                NIconButton {
                    icon: "refresh"
                    baseSize: Style.baseWidgetSize * 0.7
                    tooltipText: pluginApi?.tr("settings.refreshProfiles")
                    onClicked: main?.loadProfiles()
                }
            }

            NText {
                text: pluginApi?.tr("settings.autoConfigInfo")
                pointSize: Style.fontSizeXXS
                color: Color.mOnSurfaceVariant
                Layout.leftMargin: Style.marginXS
            }

            Repeater {
                model: root.profiles

                NBox {
                    Layout.fillWidth: true
                    Layout.leftMargin: Style.marginXS
                    Layout.rightMargin: Style.marginXS
                    implicitHeight: Math.round(rowContent.implicitHeight + Style.marginL)
                    color: Color.mSurface

                    ColumnLayout {
                        id: rowContent
                        anchors.fill: parent
                        anchors.leftMargin: Style.marginM
                        anchors.rightMargin: Style.marginM
                        anchors.topMargin: Style.marginS
                        anchors.bottomMargin: Style.marginS
                        spacing: Style.marginS

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Style.marginS

                            NIcon {
                                icon: "shield"
                                pointSize: Style.fontSizeXXL
                                color: Color.mOnSurfaceVariant
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                NText {
                                    text: modelData.name
                                    pointSize: Style.fontSizeM
                                    font.weight: Style.fontWeightMedium
                                    color: Color.mOnSurface
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }

                                NText {
                                    text: modelData.config
                                    pointSize: Style.fontSizeXXS
                                    color: Color.mOnSurfaceVariant
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
