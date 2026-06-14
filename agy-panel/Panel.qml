import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Widgets
import qs.Services.UI
import "AgyLogic.js" as Logic

Item {
  id: root
  property var pluginApi: null

  // Состояние
  readonly property var mainInstance: pluginApi?.mainInstance
  readonly property bool isGenerating: mainInstance?.isGenerating || false
  readonly property int messageCount: mainInstance?.messages?.length || 0
  
  property bool showSettings: false

  readonly property var chatViewInstance: !root.showSettings ? viewContainer.item : null
  readonly property var chatFlickableRef: chatViewInstance ? chatViewInstance.flickable : null

  // Интеграция со SmartPanel
  readonly property var geometryPlaceholder: panelContainer
  readonly property bool allowAttach: true

  // Размеры
  property real contentPreferredWidth: pluginApi?.pluginSettings?.panelWidth ?? 840
  property real _panelHeightRatio: pluginApi?.pluginSettings?.panelHeightRatio ?? 0.55
  property real contentPreferredHeight: screen ? (screen.height * _panelHeightRatio) : 600 * Style.uiScaleRatio

  anchors.fill: parent

  Rectangle {
    id: panelContainer
    anchors.fill: parent
    color: "transparent"

    ColumnLayout {
      anchors.fill: parent
      anchors.margins: Style.marginM
      spacing: Style.marginS

      // ----- Header (Step 4 - Fixed Alignment) -----
      Rectangle {
        id: headerBox
        Layout.fillWidth: true
        Layout.preferredHeight: Math.max(64 * Style.uiScaleRatio, headerRow.implicitHeight + Style.marginS * 2)
        color: Color.mSurfaceVariant
        radius: Style.radiusM

        RowLayout {
          id: headerRow
          anchors.fill: parent
          anchors.margins: Style.marginS
          spacing: Style.marginM

          // Logo/Branding Pill
          Rectangle {
            id: logoPill
            Layout.preferredHeight: terminalBtn.implicitHeight
            implicitWidth: logoRow.implicitWidth + 24 * Style.uiScaleRatio
            Layout.alignment: Qt.AlignVCenter
            
            color: Qt.alpha(Color.mPrimary, 0.08)
            border.color: Qt.alpha(Color.mPrimary, 0.15)
            border.width: 1
            radius: height / 2

            RowLayout {
              id: logoRow
              anchors.centerIn: parent
              spacing: 8 * Style.uiScaleRatio

              NIcon { 
                icon: "sparkles"
                color: Color.mPrimary
                pointSize: Style.fontSizeM
                Layout.alignment: Qt.AlignVCenter
              }

              NText {
                text: "Antigravity"
                font.weight: Font.Bold
                pointSize: Style.fontSizeM
                color: Color.mOnSurface
                Layout.alignment: Qt.AlignVCenter
              }
            }
          }

          // Path/Breadcrumb Pill
          Rectangle {
            id: pathPill
            Layout.preferredHeight: terminalBtn.implicitHeight
            Layout.maximumWidth: 240 * Style.uiScaleRatio
            implicitWidth: pathRow.implicitWidth + 24 * Style.uiScaleRatio
            Layout.alignment: Qt.AlignVCenter
            
            color: Qt.alpha(Color.mOnSurface, 0.05)
            border.color: Qt.alpha(Color.mOutline, 0.12)
            border.width: 1
            radius: height / 2
            clip: true

            readonly property string rawPath: {
              var path = "";
              if (mainInstance?.sessionWorkingDir) {
                path = mainInstance.sessionWorkingDir;
              } else if (mainInstance?.workingDir) {
                path = mainInstance.workingDir;
              }
              return path;
            }

            readonly property bool isUnderHome: rawPath === "" || rawPath === "~" || rawPath.indexOf("/home/lis") === 0
            readonly property bool isHome: rawPath === "" || rawPath === "~" || rawPath === "/home/lis"

            RowLayout {
              id: pathRow
              anchors.centerIn: parent
              width: parent.width - 24 * Style.uiScaleRatio
              spacing: 6 * Style.uiScaleRatio

              NIcon {
                icon: pathPill.isUnderHome ? "home" : "folder"
                pointSize: Style.fontSizeS
                color: mainInstance?.sessionWorkingDir ? Color.mPrimary : Color.mOnSurfaceVariant
                opacity: 0.8
                Layout.alignment: Qt.AlignVCenter
              }

              NText {
                text: {
                  var path = pathPill.rawPath;
                  if (pathPill.isHome) {
                    return "Home";
                  }
                  if (path.indexOf("/home/lis") === 0) {
                    return path.substring(9);
                  }
                  if (path.indexOf("~") === 0) {
                    return path.substring(1);
                  }
                  return path;
                }
                pointSize: Style.fontSizeS
                color: mainInstance?.sessionWorkingDir ? Color.mPrimary : Color.mOnSurfaceVariant
                font.weight: mainInstance?.sessionWorkingDir ? Font.Bold : Font.Normal
                elide: Text.ElideMiddle
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
              }
            }
          }

          // Spacer to push buttons to the right
          Item { Layout.fillWidth: true }

          // Horizontal scroll pill
          Rectangle {
            id: headerScrollPill
            Layout.preferredWidth: 120 * Style.uiScaleRatio
            Layout.preferredHeight: terminalBtn.implicitHeight
            Layout.alignment: Qt.AlignVCenter
            Layout.rightMargin: Style.marginS
            
            color: Qt.alpha(Color.mOnSurface, 0.08)
            border.color: Qt.alpha(Color.mOutline, 0.15)
            border.width: 1
            radius: height / 2
            clip: true

            visible: !root.showSettings && chatFlickableRef && (chatFlickableRef.contentHeight > chatFlickableRef.height)

            opacity: visible && (headerScrollBar.hovered || headerScrollBar.active || pillMouse.containsMouse) ? 1.0 : 0.4
            Behavior on opacity {
              NumberAnimation { duration: 150 }
            }

            MouseArea {
              id: pillMouse
              anchors.fill: parent
              hoverEnabled: true
            }

            ScrollBar {
              id: headerScrollBar
              anchors.fill: parent
              anchors.topMargin: 8 * Style.uiScaleRatio
              anchors.bottomMargin: 8 * Style.uiScaleRatio
              anchors.leftMargin: 12 * Style.uiScaleRatio
              anchors.rightMargin: 12 * Style.uiScaleRatio
              orientation: Qt.Horizontal
              policy: ScrollBar.AlwaysOn
              hoverEnabled: true

              size: chatFlickableRef ? chatFlickableRef.visibleArea.heightRatio : 0
              position: chatFlickableRef ? chatFlickableRef.visibleArea.yPosition : 0

              onPositionChanged: {
                if (pressed && chatFlickableRef) {
                  chatFlickableRef.contentY = position * chatFlickableRef.contentHeight
                }
              }

              contentItem: Rectangle {
                implicitHeight: parent.height
                radius: height / 2
                color: headerScrollBar.pressed ? Color.mPrimary : (headerScrollBar.hovered ? Color.mPrimary : Qt.alpha(Color.mOnSurface, 0.4))
                Behavior on color {
                  ColorAnimation { duration: 150 }
                }
              }

              background: Rectangle {
                implicitHeight: parent.height
                color: "transparent"
              }
            }
          }

          NIconButton {
            id: terminalBtn
            icon: "terminal"
            colorFg: Color.mOnSurfaceVariant
            tooltipText: pluginApi?.tr("panel.openInTerminal") || "Continue in terminal"
            Layout.alignment: Qt.AlignVCenter
            onClicked: mainInstance?.openTerminal()
          }

          NIconButton {
            icon: "settings"
            colorFg: root.showSettings ? Color.mPrimary : Color.mOnSurfaceVariant
            Layout.alignment: Qt.AlignVCenter
            onClicked: root.showSettings = !root.showSettings
          }

          NButton {
            id: newChatBtn
            readonly property string detectedPath: {
              var text = mainInstance?.inputText || "";
              return Logic.extractPath(text);
            }
            text: detectedPath !== "" 
              ? (pluginApi?.tr("panel.newChatAtPath") || "New Chat in folder")
              : (pluginApi?.tr("panel.newChat") || "New Chat")
            icon: detectedPath !== "" ? "folder-plus" : "plus"
            enabled: root.messageCount > 0 || detectedPath !== "" || (mainInstance?.sessionWorkingDir && mainInstance.sessionWorkingDir !== "")
            Layout.alignment: Qt.AlignVCenter
            onClicked: {
              if (detectedPath !== "") {
                var path = detectedPath;
                mainInstance.inputText = "";
                mainInstance?.newSession(path);
              } else {
                mainInstance?.newSession();
              }
            }
          }
        }
      }

      // ----- Content Area (Step 4: Chat vs Settings) -----
      NSlideSwapView {
        id: viewContainer
        Layout.fillWidth: true
        Layout.fillHeight: true
        animationsEnabled: true
        sourceComponent: root.showSettings ? settingsComponent : chatComponent

        onSourceComponentChanged: {
          swap(root.showSettings ? 1 : -1, null);
        }
      }
    }
    
    Component {
      id: chatComponent
      ChatView {
        pluginApi: root.pluginApi
        mainInstance: root.mainInstance
        isGenerating: root.isGenerating
      }
    }

    Component {
      id: settingsComponent
      SettingsView {
        pluginApi: root.pluginApi
      }
    }
  }
}
