import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Modules.Bar.Extras
import qs.Services.UI
import qs.Widgets

Item {
    id: root

    property var pluginApi: null
    property ShellScreen screen
    property string widgetId: ""
    property string section: ""
    property int sectionWidgetIndex: -1
    property int sectionWidgetsCount: 0
    readonly property var pluginSettings: pluginApi?.pluginSettings ?? ({})
    readonly property var main: pluginApi?.mainInstance ?? ({})

    readonly property string screenName: screen?.name ?? ""
    readonly property string barPosition: Settings.getBarPositionForScreen(screenName)
    readonly property bool isBarVertical: barPosition === "left" || barPosition === "right"
    readonly property real capsuleHeight: Style.getCapsuleHeightForScreen(screenName)
    readonly property real barFontSize: Style.getBarFontSizeForScreen(screenName)
    readonly property string barStyle: pluginSettings.barStyle ?? "icon"
    readonly property string connectedColor: pluginSettings.connectedColor ?? "primary"
    readonly property string disconnectedColor: pluginSettings.disconnectedColor ?? "none"

    readonly property bool isConnected: main.isConnected ?? false
    readonly property bool isLoading: main.isLoading ?? false
    readonly property var profiles: main.profiles ?? []
    readonly property bool quickToggle: pluginSettings.quickToggle ?? false
    readonly property string defaultProfileName: pluginSettings.defaultProfileName ?? ""

    function defaultProfile() {
        const profs = profiles
        if (defaultProfileName) {
            const found = profs.find(p => p.name === defaultProfileName)
            if (found) return found
        }
        return profs.length > 0 ? profs[0] : null
    }

    implicitWidth: pill.width
    implicitHeight: pill.height

    Component.onCompleted: {
        Logger.i("AmneziaWG-dkms", "Bar widget loaded")
    }

    NPopupContextMenu {
        id: contextMenu

        model: [{
            "label": pluginApi?.tr("settings.pluginSettings"),
            "action": "plugin-settings",
            "icon": "settings"
        }]
        onTriggered: (action) => {
            contextMenu.close()
            PanelService.closeContextMenu(screen)
            if (action === "plugin-settings")
                BarService.openPluginSettings(screen, pluginApi.manifest)
        }
    }

    BarPill {
        id: pill

        screen: root.screen
        oppositeDirection: BarService.getPillDirection(root)
        autoHide: false
        text: root.barStyle === "pill" ? "VPN" : (root.isConnected ? pluginApi?.tr("common.connected") : pluginApi?.tr("common.disconnected"))
        icon: root.isConnected ? "lock" : "lock-open"
        onClicked: {
            if (pluginApi)
                pluginApi.openPanel(root.screen, root)
        }
        onRightClicked: {
            if (root.quickToggle && !root.isLoading) {
                if (root.isConnected) {
                    main.disconnect()
                } else {
                    const p = root.defaultProfile()
                    if (p) main.connect(p.name, p.config)
                }
            } else {
                if (pluginApi)
                    pluginApi.closePanel(root.screen)
                PanelService.showContextMenu(contextMenu, pill, screen)
            }
        }
        customIconColor: Color.resolveColorKeyOptional(root.isConnected ? root.connectedColor : root.disconnectedColor)
        customTextColor: Color.resolveColorKeyOptional(root.isConnected ? root.connectedColor : root.disconnectedColor)
        forceOpen: root.barStyle === "pill"
        forceClose: false
    }

    // Bounce when connection state changes
    SequentialAnimation {
        id: stateChangeAnim
        NumberAnimation { target: pill; property: "scale"; to: 0.80; duration: 90; easing.type: Easing.InCubic }
        NumberAnimation { target: pill; property: "scale"; to: 1.0; duration: 260; easing.type: Easing.OutBack; easing.overshoot: 1.3 }
    }

    // Opacity pulse during loading
    SequentialAnimation {
        id: pulseAnim
        running: root.isLoading
        loops: Animation.Infinite
        NumberAnimation { target: pill; property: "opacity"; to: 0.45; duration: 650; easing.type: Easing.InOutSine }
        NumberAnimation { target: pill; property: "opacity"; to: 1.0; duration: 650; easing.type: Easing.InOutSine }
        onStopped: pill.opacity = 1.0
    }

    Connections {
        target: root
        function onIsConnectedChanged() { stateChangeAnim.restart() }
    }
}
