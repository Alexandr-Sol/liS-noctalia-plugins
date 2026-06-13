import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Commons
import qs.Widgets
import qs.Services.UI

ColumnLayout {
    id: root
    property var pluginApi: null
    spacing: Style.marginM

    function set(key, value) {
        if (!pluginApi) return;
        
        var s = Object.assign({}, pluginApi.pluginSettings);
        if (!s.widget) s.widget = {};
        
        var w = Object.assign({}, s.widget);
        w[key] = value;
        s.widget = w;
        
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

    function setAgy(key, value) {
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

    NText {
        text: pluginApi?.tr("settings.widgetTitle") || "Widget Settings"
        font.weight: Font.Bold
        font.pointSize: Style.fontSizeL
    }

    NDivider { Layout.fillWidth: true }

    NComboBox {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.widgetStyle") || "Widget Style"
        description: pluginApi?.tr("settings.widgetStyleHelp") || "Select widget representation in the panel"
        model: [
            { "key": "compact", "name": pluginApi?.tr("settings.widgetStyleCompact") || "Compact (icon only)" },
            { "key": "large", "name": pluginApi?.tr("settings.widgetStyleLarge") || "Large (icon + text)" }
        ]
        currentKey: pluginApi?.pluginSettings?.widget?.style || "compact"
        onSelected: function(key) {
            set("style", key);
        }
    }

    NDivider { Layout.fillWidth: true }

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

    NDivider { Layout.fillWidth: true }

    NToggle {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.enableNotifications") || "Enable Notifications"
        description: pluginApi?.tr("settings.enableNotificationsHelp") || "Show popup notifications for actions like copying to clipboard, clearing history, etc."
        checked: pluginApi?.pluginSettings?.agy?.enableNotifications !== false
        onToggled: function(checked) {
            setAgy("enableNotifications", checked);
        }
    }
    
    Item { Layout.fillHeight: true }
}
