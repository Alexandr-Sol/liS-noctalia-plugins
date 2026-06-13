import QtQuick
import Quickshell
import qs.Widgets

NIconButtonHot {
    property ShellScreen screen
    property var pluginApi: null

    icon: "sparkles"
    tooltipText: (pluginApi && pluginApi.tr("ccw.tooltip")) ? pluginApi.tr("ccw.tooltip") : "Agy"

    onClicked: pluginApi.togglePanel(screen, this)
}
