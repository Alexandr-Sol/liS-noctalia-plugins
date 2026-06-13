import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Widgets
import qs.Services.UI
import qs.Services.System

Item {
  id: root
  property var pluginApi: null

  property ShellScreen screen
  property string widgetId: ""
  property string section: ""
  property int sectionWidgetIndex: -1
  property int sectionWidgetsCount: 0

  readonly property var mainInstance: pluginApi?.mainInstance
  readonly property bool isGenerating: mainInstance?.isGenerating || false
  readonly property bool binaryAvailable: mainInstance?.binaryAvailable || false
  readonly property int messageCount: mainInstance?.messages?.length || 0

  readonly property string screenName: screen ? screen.name : ""
  readonly property string barPosition: Settings.getBarPositionForScreen(screenName)
  readonly property bool isVertical: barPosition === "left" || barPosition === "right"
  readonly property real capsuleHeight: Style.getCapsuleHeightForScreen(screenName)
  readonly property real barFontSize: Style.getBarFontSizeForScreen(screenName)

  // --- Widget settings ---
  readonly property string widgetStyle: pluginApi?.pluginSettings?.widget?.style || "compact"
  readonly property bool showStatus: pluginApi?.pluginSettings?.widget?.showStatus !== false

  readonly property real contentWidth: (root.isVertical || root.widgetStyle === "compact") 
                                       ? root.capsuleHeight 
                                       : horizontalRow.implicitWidth + Style.marginM * 2
  readonly property real contentHeight: root.capsuleHeight

  implicitWidth: contentWidth
  implicitHeight: contentHeight

  function accentColor() {
    if (!binaryAvailable) { return Color.mOnSurfaceVariant; }
    if (isGenerating) { return Color.mPrimary; }
    return Color.mOnSurface;
  }

  readonly property color contentColor: mouseArea.containsMouse ? Color.mOnHover : root.accentColor()

  Rectangle {
    id: capsule
    x: Style.pixelAlignCenter(parent.width, width)
    y: Style.pixelAlignCenter(parent.height, height)
    width: root.contentWidth
    height: root.contentHeight
    color: mouseArea.containsMouse ? Color.mHover : Style.capsuleColor
    radius: Style.radiusL
    border.color: Style.capsuleBorderColor
    border.width: Style.capsuleBorderWidth

    // Horizontal Layout (Icon + Label)
    Row {
      id: horizontalRow
      anchors.centerIn: parent
      spacing: Style.marginS
      visible: !root.isVertical && root.widgetStyle === "large"

      NIcon {
        id: hIcon
        anchors.verticalCenter: parent.verticalCenter
        icon: isGenerating ? "loader-2" : "sparkles"
        color: root.contentColor
        applyUiScale: false
        
        RotationAnimation on rotation {
          running: root.isGenerating
          from: 0; to: 360; duration: 1200; loops: Animation.Infinite
        }
        Binding { target: hIcon; property: "rotation"; value: 0; when: !root.isGenerating }
      }

      NText {
        anchors.verticalCenter: parent.verticalCenter
        text: isGenerating ? "Agy..." : "Agy"
        color: root.contentColor
        pointSize: root.barFontSize
        applyUiScale: false
        font.weight: isGenerating ? Font.Medium : Font.Normal
      }
    }

    // Vertical / Compact Layout (Icon only)
    Item {
      anchors.fill: parent
      visible: root.isVertical || root.widgetStyle === "compact"

      NIcon {
        id: vIcon
        anchors.centerIn: parent
        icon: isGenerating ? "loader-2" : "sparkles"
        color: root.contentColor
        applyUiScale: false

        RotationAnimation on rotation {
          running: root.isGenerating
          from: 0; to: 360; duration: 1200; loops: Animation.Infinite
        }
        Binding { target: vIcon; property: "rotation"; value: 0; when: !root.isGenerating }
      }

      // Active indicator dot
      Rectangle {
        visible: root.binaryAvailable && root.messageCount > 0
        width: 6; height: 6; radius: 3
        color: mouseArea.containsMouse ? Color.mOnHover : Color.mPrimary
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 4
      }
    }
  }

  MouseArea {
    id: mouseArea
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    acceptedButtons: Qt.LeftButton | Qt.RightButton

    onEntered: TooltipService.show(root, buildTooltip(), BarService.getTooltipDirection(root.screenName))
    onExited: TooltipService.hide()

    onClicked: function (mouse) {
      if (mouse.button === Qt.LeftButton) {
        if (pluginApi) { pluginApi.openPanel(root.screen, root); }
      } else if (mouse.button === Qt.RightButton) {
        PanelService.showContextMenu(contextMenu, root, screen);
      }
    }
  }

  NPopupContextMenu {
    id: contextMenu
    model: [
      { "label": pluginApi?.tr("menu.openPanel") || "Открыть панель", "action": "open", "icon": "external-link" },
      { "label": pluginApi?.tr("menu.settings") || "Настройки", "action": "widget-settings", "icon": "settings" },
      { "label": pluginApi?.tr("menu.newSession") || "Новая сессия", "action": "newSession", "icon": "plus" },
      { "label": pluginApi?.tr("menu.stop") || "Остановить", "action": "stop", "icon": "square" },
      { "label": pluginApi?.tr("menu.clearHistory") || "Очистить историю", "action": "clear", "icon": "trash" }
    ]
    onTriggered: function (action) {
      contextMenu.close();
      PanelService.closeContextMenu(screen);
      if (action === "open") { pluginApi?.openPanel(root.screen, root); }
      else if (action === "widget-settings") {
          BarService.openPluginSettings(screen, pluginApi.manifest);
      }
      else if (action === "newSession") { mainInstance?.newSession(); }
      else if (action === "stop") { mainInstance?.stopGeneration(); }
      else if (action === "clear") {
        mainInstance?.clearMessages();
        if (pluginApi?.pluginSettings?.agy?.enableNotifications !== false) {
          ToastService.showNotice(pluginApi?.tr("toast.historyCleared") || "История чата очищена");
        }
      }
    }
  }

  function buildTooltip() {
    var t = "Agy (Antigravity)";
    if (!binaryAvailable) {
      t += "\n" + (pluginApi?.tr("widget.notInstalled") || "agy-bridge не найден");
      return t;
    }
    if (messageCount > 0) { t += "\n" + (pluginApi?.tr("widget.messages") || "Сообщений") + ": " + messageCount; }
    if (isGenerating) {
      t += "\n" + (pluginApi?.tr("widget.running") || "Работает…");
    }
    t += "\n\n" + (pluginApi?.tr("widget.rightClickHint") || "Правая кнопка — опции");
    return t;
  }

  Component.onCompleted: {
    Logger.i("AgyPanel", "BarWidget initialized");
  }
}
