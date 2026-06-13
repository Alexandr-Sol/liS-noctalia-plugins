import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Commons
import qs.Widgets
import qs.Services.UI

Item {
  id: root
  anchors.fill: parent
  property var pluginApi: null

  property string valueDefaultPrompt: pluginApi?.pluginSettings?.agy?.defaultPrompt || ""

  Timer {
    id: saveTimer
    interval: 500
    repeat: false
    onTriggered: {
      set("defaultPrompt", root.valueDefaultPrompt);
    }
  }

  function set(key, value) {
    if (!pluginApi) return;
    
    var s = Object.assign({}, pluginApi.pluginSettings);
    if (!s.agy) s.agy = {};
    
    var g = Object.assign({}, s.agy);
    g[key] = value;
    s.agy = g;
    
    pluginApi.pluginSettings = s;
    pluginApi.saveSettings();
    if (pluginApi.pluginSettingsChanged) {
      pluginApi.pluginSettingsChanged();
    }
  }

  function setTop(key, value) {
    if (!pluginApi) return;
    
    var s = Object.assign({}, pluginApi.pluginSettings);
    s[key] = value;
    
    pluginApi.pluginSettings = s;
    pluginApi.saveSettings();
    if (pluginApi.pluginSettingsChanged) {
      pluginApi.pluginSettingsChanged();
    }
  }

  NScrollView {
    anchors.fill: parent
    contentWidth: availableWidth
    clip: true

    ColumnLayout {
      width: parent.width
      spacing: Style.marginM
      anchors.margins: Style.marginM

      NText { 
        text: pluginApi?.tr("settings.title") || "Antigravity Settings"
        font.weight: Font.Bold
        font.pointSize: Style.fontSizeL 
      }

      NDivider { Layout.fillWidth: true }

      // --- Terminal Emulator ---
      NComboBox {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.terminalEmulator") || "Terminal Emulator"
        description: pluginApi?.tr("settings.terminalEmulatorHelp") || "Select terminal emulator for continuing the session"
        model: [
          { "key": "ghostty", "name": "Ghostty" },
          { "key": "foot", "name": "Foot" },
          { "key": "kitty", "name": "Kitty" }
        ]
        currentKey: pluginApi?.pluginSettings?.agy?.terminalEmulator || "ghostty"
        onSelected: function(key) {
            set("terminalEmulator", key);
        }
      }

      NDivider { Layout.fillWidth: true }

      // --- Working Directory ---
      NTextInput {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.workingDir") || "Working directory"
        description: pluginApi?.tr("settings.workingDirHelp") || "Absolute path. Agy will operate in this directory."
        text: pluginApi?.pluginSettings?.agy?.workingDir || ""
        placeholderText: "/home/lis"
        onEditingFinished: function() { set("workingDir", text); }
      }

      NDivider { Layout.fillWidth: true }

      // --- Default Prompt ---
      ColumnLayout {
        Layout.fillWidth: true
        spacing: Style.marginXS

        RowLayout {
          Layout.fillWidth: true
          ColumnLayout {
            spacing: 0
            NText {
              text: pluginApi?.tr("settings.defaultPrompt") || "Default Prompt"
              font.weight: Font.DemiBold
              pointSize: Style.fontSizeM
              color: Color.mOnSurface
            }
            NText {
              text: pluginApi?.tr("settings.defaultPromptHelp") || "This system prompt will be silently attached to the first message of each new chat"
              pointSize: Style.fontSizeXS
              color: Color.mOnSurfaceVariant
              opacity: 0.7
              Layout.fillWidth: true
              wrapMode: Text.Wrap
            }
          }
        }

        Rectangle {
          Layout.fillWidth: true
          Layout.preferredHeight: 100
          radius: Style.radiusS
          color: Color.mSurfaceVariant
          border.color: defaultPromptArea.activeFocus ? Color.mPrimary : Color.mSurfaceVariant
          border.width: 1
          clip: true

          ScrollView {
            anchors.fill: parent
            anchors.margins: Style.marginS
            clip: true

            TextArea {
              id: defaultPromptArea
              width: parent.width
              wrapMode: TextArea.Wrap
              placeholderText: pluginApi?.tr("settings.defaultPromptPlaceholder") || "e.g. Respond concisely and only in English..."
              placeholderTextColor: Qt.alpha(Color.mOnSurfaceVariant, 0.4)
              background: null
              color: Color.mOnSurface
              font.pointSize: Style.fontSizeM
              selectedTextColor: Color.mOnPrimary
              selectionColor: Color.mPrimary
              text: root.valueDefaultPrompt
              onTextChanged: {
                if (text !== root.valueDefaultPrompt) {
                  root.valueDefaultPrompt = text;
                  saveTimer.restart();
                }
              }
            }
          }
        }
      }

      NDivider { Layout.fillWidth: true }

      // --- Panel Height ---
      ColumnLayout {
        Layout.fillWidth: true
        spacing: Style.marginS

        NLabel {
          label: (pluginApi?.tr("settings.panelHeightRatio") || "Panel Height") + ": " + Math.round(sliderHeight.value * 100) + "%"
          description: pluginApi?.tr("settings.panelHeightRatioHelp") || "How much of the screen height the panel should use"
        }

        NSlider {
          id: sliderHeight
          Layout.fillWidth: true
          from: 0.3
          to: 1.0
          stepSize: 0.05
          value: pluginApi?.pluginSettings?.panelHeightRatio ?? 0.55
          onPressedChanged: {
            if (!pressed) {
              setTop("panelHeightRatio", value);
            }
          }
        }
      }

      NDivider { Layout.fillWidth: true }

      // --- Panel Width ---
      ColumnLayout {
        Layout.fillWidth: true
        spacing: Style.marginS

        NLabel {
          label: (pluginApi?.tr("settings.panelWidth") || "Panel Width") + ": " + Math.round(sliderWidth.value) + "px"
          description: pluginApi?.tr("settings.panelWidthHelp") || "Width of the panel in pixels"
        }

        NSlider {
          id: sliderWidth
          Layout.fillWidth: true
          from: 320
          to: 1600
          stepSize: 20
          value: pluginApi?.pluginSettings?.panelWidth ?? 840
          onPressedChanged: {
            if (!pressed) {
              setTop("panelWidth", Math.round(value));
            }
          }
        }
      }

      // --- Enable Notifications ---
      NToggle {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.enableNotifications") || "Enable Notifications"
        description: pluginApi?.tr("settings.enableNotificationsHelp") || "Show popup notifications for actions like copying to clipboard, clearing history, etc."
        checked: pluginApi?.pluginSettings?.agy?.enableNotifications !== false
        onToggled: function(checked) {
          set("enableNotifications", checked);
        }
      }

      NDivider { Layout.fillWidth: true }

      // --- Sandbox Mode ---
      NToggle {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.sandbox") || "Run in sandbox (--sandbox)"
        description: pluginApi?.tr("settings.sandboxHelp") || "Restricts Agy to a sandboxed environment for safer execution."
        checked: pluginApi?.pluginSettings?.agy?.sandbox === true
        onToggled: function(checked) {
          set("sandbox", checked);
        }
      }

      NDivider { Layout.fillWidth: true }

      // --- Dangerously Skip Permissions ---
      NToggle {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.dangerouslySkipPermissions") || "Auto-confirm (--dangerously-skip-permissions)"
        description: pluginApi?.tr("settings.dangerouslySkipPermissionsHelp") || "Allow agy to run any tools automatically (DANGEROUS)"
        checked: pluginApi?.pluginSettings?.agy?.dangerouslySkipPermissions === true
        onToggled: function(checked) {
          set("dangerouslySkipPermissions", checked);
        }
      }
      
      Item { Layout.fillHeight: true }
    }
  }
}
