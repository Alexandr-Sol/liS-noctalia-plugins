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

          NIcon { 
            icon: "sparkles"
            color: Color.mPrimary
            pointSize: Style.fontSizeL
            Layout.alignment: Qt.AlignVCenter
          }

          RowLayout {
            Layout.alignment: Qt.AlignVCenter
            Layout.maximumWidth: 320 * Style.uiScaleRatio
            spacing: Style.marginXS

            NText {
              text: "Antigravity"
              font.weight: Font.Bold
              pointSize: Style.fontSizeM
              color: Color.mOnSurface
              Layout.alignment: Qt.AlignVCenter
            }

            NText {
              text: "•"
              pointSize: Style.fontSizeS
              color: Color.mOnSurfaceVariant
              opacity: 0.5
              Layout.alignment: Qt.AlignVCenter
            }

            NText {
              id: subtitleText
              text: {
                var currentCwd = "";
                if (mainInstance?.sessionWorkingDir) {
                  currentCwd = mainInstance.sessionWorkingDir;
                } else if (mainInstance?.workingDir) {
                  currentCwd = mainInstance.workingDir;
                } else {
                  currentCwd = "~";
                }
                return currentCwd;
              }
              pointSize: Style.fontSizeS
              color: mainInstance?.sessionWorkingDir ? Color.mPrimary : Color.mOnSurfaceVariant
              font.weight: mainInstance?.sessionWorkingDir ? Font.Bold : Font.Normal
              elide: Text.ElideMiddle
              Layout.fillWidth: true
              Layout.alignment: Qt.AlignVCenter
            }
          }

          // Spacer to push buttons to the right
          Item { Layout.fillWidth: true }

          NIconButton {
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
