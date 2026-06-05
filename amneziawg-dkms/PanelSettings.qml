import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import qs.Commons
import qs.Widgets

ColumnLayout {
    id: root

    property var pluginApi: null
    property var main: null
    readonly property var pluginSettings: pluginApi?.pluginSettings ?? ({})
    readonly property var profiles: main?.profiles ?? []

    property string barStyle: pluginSettings.barStyle ?? "icon"
    property bool quickToggle: pluginSettings.quickToggle ?? false
    property bool autoStopZapret: pluginSettings.autoStopZapret ?? false
    property bool disableToastNotifications: pluginSettings.disableToastNotifications ?? false
    property string defaultProfileName: pluginSettings.defaultProfileName ?? ""

    spacing: Style.marginL

    readonly property var barStyleModel: [{
        "key": "icon",
        "name": pluginApi?.tr("settings.barStyleIcon")
    }, {
        "key": "pill",
        "name": pluginApi?.tr("settings.barStylePill")
    }]

    function save() {
        pluginApi.pluginSettings.barStyle = root.barStyle
        pluginApi.pluginSettings.quickToggle = root.quickToggle
        pluginApi.pluginSettings.autoStopZapret = root.autoStopZapret
        pluginApi.pluginSettings.disableToastNotifications = root.disableToastNotifications
        pluginApi.pluginSettings.defaultProfileName = root.defaultProfileName
        pluginApi.saveSettings()
    }

    function setDefault(name) {
        root.defaultProfileName = name
        root.save()
    }

    // ── Dropdowns & toggles ──────────────────────────────────────────────────

    NComboBox {
        label: pluginApi?.tr("settings.barStyle")
        description: pluginApi?.tr("settings.barStyleDescription")
        minimumWidth: 200
        model: root.barStyleModel
        currentKey: root.barStyle
        onSelected: (key) => { root.barStyle = key; root.save() }
    }

    NToggle {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.quickToggle")
        description: pluginApi?.tr("settings.quickToggleDescription")
        checked: root.quickToggle
        onToggled: checked => { root.quickToggle = checked; root.save() }
    }

    NToggle {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.autoStopZapret")
        description: pluginApi?.tr("settings.autoStopZapretDescription")
        checked: root.autoStopZapret
        onToggled: checked => { root.autoStopZapret = checked; root.save() }
    }

    NToggle {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.disableToastNotifications")
        description: pluginApi?.tr("settings.disableToastNotificationsDescription")
        checked: root.disableToastNotifications
        onToggled: checked => { root.disableToastNotifications = checked; root.save() }
    }

    // ── Divider ──────────────────────────────────────────────────────────────

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: 1
        color: Qt.alpha(Color.mOutline, 0.25)
    }

    // ── Profiles section ─────────────────────────────────────────────────────

    RowLayout {
        Layout.fillWidth: true
        NText {
            text: pluginApi?.tr("settings.profiles")
            pointSize: Style.fontSizeM
            font.weight: Style.fontWeightMedium
            color: Color.mOnSurface
        }
        NBox { Layout.fillWidth: true }
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
        Layout.bottomMargin: Style.marginS
    }

    // Profile cards
    Repeater {
        model: root.profiles

        NBox {
            id: profileRow
            readonly property bool isDefault: modelData.name === root.defaultProfileName
                || (root.defaultProfileName === "" && index === 0)

            Layout.fillWidth: true
            implicitHeight: Math.round(rowContent.implicitHeight + Style.marginL)
            color: Color.mSurface

            RowLayout {
                id: rowContent
                width: parent.width - Style.marginL
                x: Style.marginM
                y: Style.marginM
                spacing: Style.marginS

                NIconButton {
                    icon: profileRow.isDefault ? "star-filled" : "star"
                    colorFg: profileRow.isDefault ? Color.mPrimary : Color.mOnSurfaceVariant
                    baseSize: Style.baseWidgetSize * 0.75
                    tooltipText: pluginApi?.tr("panel.setDefault")
                    onClicked: root.setDefault(modelData.name)
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.minimumWidth: 0
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
