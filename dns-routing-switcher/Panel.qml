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
    readonly property var mainInstance: pluginApi?.mainInstance

    // Wider panel size for domain routing management
    property real contentPreferredWidth: Math.round(560 * Style.uiScaleRatio)
    property real contentPreferredHeight: mainLayout.implicitHeight + (Style.marginL * 2)

    readonly property var geometryPlaceholder: bg
    readonly property bool allowAttach: true

    // Routing Navigation State
    property bool showRouting: false

    // State for Adding Custom DNS Server
    property string newName: ""
    property string newIp: ""
    property bool isAdding: false
    property string validationError: ""

    // State for Adding Routing Rule
    property string selectedDnsIp: "1.1.1.1 1.0.0.1"
    property string customDnsIpText: ""
    readonly property bool isCustomDnsInputSelected: selectedDnsIp === "custom_input"
    property string routingRuleDomains: ""
    property string routingRuleError: ""

    readonly property var dnsComboModel: {
        var items = [
            { key: "8.8.8.8 8.8.4.4", name: "Google" },
            { key: "1.1.1.1 1.0.0.1", name: "Cloudflare" },
            { key: "208.67.222.222 208.67.220.220", name: "OpenDNS" },
            { key: "94.140.14.14 94.140.15.15", name: "AdGuard" },
            { key: "9.9.9.9 149.112.112.112", name: "Quad9" }
        ];
        if (mainInstance) {
            var customs = mainInstance.customProviders || [];
            for (var i = 0; i < customs.length; i++) {
                items.push({ key: customs[i].ip, name: customs[i].label });
            }
        }
        items.push({ key: "custom_input", name: "Custom IP..." });
        return items;
    }

    Rectangle {
        id: bg
        anchors.fill: parent
        color: Color.mSurface
        radius: Style.radiusL
        border.color: Qt.alpha(Color.mOutline, 0.2)
        border.width: 1

        ColumnLayout {
            id: mainLayout
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: Style.marginL
            spacing: Style.marginM

            // Header Section
            NBox {
                id: headerBox
                Layout.fillWidth: true
                Layout.preferredHeight: Math.round(52 * Style.uiScaleRatio)

                RowLayout {
                    id: headerRow
                    anchors.fill: parent
                    anchors.margins: Style.marginS
                    spacing: Style.marginS

                    NIconButton {
                        visible: root.showRouting
                        icon: "arrow-left"
                        colorFg: Color.mPrimary
                        Layout.alignment: Qt.AlignVCenter
                        onClicked: {
                            root.showRouting = false;
                        }
                    }

                    NIcon {
                        visible: !root.showRouting
                        icon: "globe"
                        pointSize: Style.fontSizeL
                        color: Color.mPrimary
                        Layout.alignment: Qt.AlignVCenter
                    }

                    NText {
                        text: root.showRouting 
                              ? (pluginApi?.tr("panel.routing_title") || "Domain Routing Rules")
                              : (pluginApi?.tr("plugin.title") || "DNS Routing Switcher")
                        pointSize: Style.fontSizeL
                        font.weight: Style.fontWeightBold
                        color: Color.mOnSurface
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                    }

                    NIconButton {
                        visible: root.showRouting
                        icon: "file-text"
                        colorFg: Color.mPrimary
                        tooltipText: pluginApi?.tr("panel.open_routing_file") || "Open routing file"
                        Layout.alignment: Qt.AlignVCenter
                        onClicked: {
                            if (mainInstance) {
                                mainInstance.openRoutingFile();
                            }
                        }
                    }

                    NText {
                        visible: !root.showRouting
                        text: mainInstance?.currentDnsName || "..."
                        pointSize: Style.fontSizeS
                        color: (mainInstance?.isChanging) ? Color.mPrimary : Color.mSecondary
                        font.weight: Font.Medium
                        Layout.alignment: Qt.AlignVCenter
                    }
                }
            }

            // Error Display
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: errorText.implicitHeight + Style.marginM
                visible: (mainInstance?.lastError || "") !== ""
                color: Qt.alpha(Color.mError, 0.1)
                radius: Style.radiusS
                border.color: Qt.alpha(Color.mError, 0.3)
                border.width: 1

                NText {
                    id: errorText
                    anchors.fill: parent
                    anchors.margins: Style.marginS
                    text: mainInstance?.lastError || ""
                    color: Color.mError
                    pointSize: Style.fontSizeS
                    wrapMode: Text.WordWrap
                }
            }

            // CONTENT / ROUTING SWITCHER
            // Height is updated via ScriptAction at the invisible midpoint of each transition,
            // avoiding the "flicker" that happens when implicitHeight is bound to an invisible
            // ColumnLayout (which reports 0 when visible:false).
            Item {
                id: viewSwitcher
                Layout.fillWidth: true
                implicitHeight: mainPane.implicitHeight

                // Keep height in sync when the active pane's content changes outside transitions
                Connections {
                    target: mainPane
                    function onImplicitHeightChanged() {
                        if (!root.showRouting) viewSwitcher.implicitHeight = mainPane.implicitHeight
                    }
                }
                Connections {
                    target: routingPane
                    function onImplicitHeightChanged() {
                        if (root.showRouting) viewSwitcher.implicitHeight = routingPane.implicitHeight
                    }
                }

                states: [
                    State { name: "main";    when: !root.showRouting },
                    State { name: "routing"; when:  root.showRouting }
                ]

                transitions: [
                    Transition {
                        from: "main"; to: "routing"
                        SequentialAnimation {
                            // 1. Fade out main content
                            NumberAnimation { target: mainPane; property: "opacity"; to: 0; duration: 150; easing.type: Easing.InCubic }
                            // 2. At the invisible midpoint: snap height and reset routing opacity
                            ScriptAction { script: { viewSwitcher.implicitHeight = routingPane.implicitHeight; routingPane.opacity = 0 } }
                            // 3. Fade in routing
                            NumberAnimation { target: routingPane; property: "opacity"; to: 1; duration: 200; easing.type: Easing.OutCubic }
                        }
                    },
                    Transition {
                        from: "routing"; to: "main"
                        SequentialAnimation {
                            // 1. Fade out routing
                            NumberAnimation { target: routingPane; property: "opacity"; to: 0; duration: 150; easing.type: Easing.InCubic }
                            // 2. At the invisible midpoint: snap height and reset main opacity
                            ScriptAction { script: { viewSwitcher.implicitHeight = mainPane.implicitHeight; mainPane.opacity = 0 } }
                            // 3. Fade in main content
                            NumberAnimation { target: mainPane; property: "opacity"; to: 1; duration: 200; easing.type: Easing.OutCubic }
                        }
                    }
                ]

                // MAIN VIEW — always rendered, opacity-managed by transitions
                ColumnLayout {
                    id: mainPane
                    width: parent.width
                    spacing: Style.marginM
                    enabled: opacity > 0.01

                    NScrollView {
                        Layout.fillWidth: true
                        Layout.preferredHeight: Math.min(Math.round(200 * Style.uiScaleRatio), contentHeight)
                        clip: true

                        ColumnLayout {
                            width: parent.width
                            spacing: Style.marginS

                            // DNS Option template
                            component DnsOption: Rectangle {
                                id: opt
                                Layout.fillWidth: true
                                Layout.preferredHeight: Math.round(50 * Style.uiScaleRatio)
                                radius: Style.radiusM

                                property string label: ""
                                property string providerId: ""
                                property string providerIp: ""
                                property bool isCustom: false
                                property int customIndex: -1
                                property bool isActive: (mainInstance?.activeProviderId || "") === providerId
                                property bool isDisabled: mainInstance?.isChanging || false

                                color: isActive ? Color.mPrimary : Color.mSurfaceVariant
                                opacity: isDisabled ? 0.6 : 1.0
                                Behavior on color { ColorAnimation { duration: Style.animationFast } }
                                Behavior on opacity { NumberAnimation { duration: 150 } }

                                Rectangle {
                                    anchors.fill: parent
                                    radius: opt.radius
                                    color: (hoverArea.containsMouse && !opt.isActive && !opt.isDisabled)
                                           ? Color.mHover : "transparent"
                                    opacity: (hoverArea.containsMouse && !opt.isActive && !opt.isDisabled)
                                             ? 0.2 : 0
                                    Behavior on opacity { NumberAnimation { duration: 150 } }
                                }

                                MouseArea {
                                    id: hoverArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: opt.isDisabled ? Qt.ForbiddenCursor : Qt.PointingHandCursor
                                    onClicked: {
                                        if (opt.isDisabled) return;
                                        if (mainInstance) {
                                            mainInstance.setDns(opt.isCustom ? opt.providerIp : opt.providerId);
                                        }
                                        if (pluginApi) {
                                            pluginApi.withCurrentScreen(function(s) {
                                                pluginApi.closePanel(s);
                                            });
                                        }
                                    }
                                }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: Style.marginM
                                    anchors.rightMargin: Style.marginM
                                    spacing: Style.marginM

                                    NIcon {
                                        icon: opt.isActive ? "check" : "circle"
                                        pointSize: Style.fontSizeM
                                        color: opt.isActive ? Color.mOnPrimary : Color.mOnSurfaceVariant
                                    }

                                    NText {
                                        text: opt.label
                                        pointSize: Style.fontSizeM
                                        font.weight: Font.Medium
                                        color: opt.isActive ? Color.mOnPrimary : Color.mOnSurface
                                        Layout.fillWidth: true
                                    }

                                    NText {
                                        text: opt.providerIp
                                        pointSize: Style.fontSizeXS
                                        color: opt.isActive
                                               ? Qt.alpha(Color.mOnPrimary, 0.7)
                                               : Color.mOnSurfaceVariant
                                        visible: opt.providerIp !== ""
                                    }

                                    NIconButton {
                                        visible: opt.isCustom
                                        icon: "trash"
                                        colorFg: opt.isActive ? Color.mOnPrimary : Color.mError
                                        enabled: !opt.isDisabled
                                        onClicked: {
                                            if (mainInstance && opt.customIndex >= 0) {
                                                mainInstance.removeCustomServer(opt.customIndex);
                                            }
                                        }
                                    }
                                }
                            }

                            DnsOption {
                                label: "Google"
                                providerId: "google"
                                providerIp: "8.8.8.8 8.8.4.4"
                            }
                            DnsOption {
                                label: "Cloudflare"
                                providerId: "cloudflare"
                                providerIp: "1.1.1.1 1.0.0.1"
                            }
                            DnsOption {
                                label: "OpenDNS"
                                providerId: "opendns"
                                providerIp: "208.67.222.222 208.67.220.220"
                            }
                            DnsOption {
                                label: "AdGuard"
                                providerId: "adguard"
                                providerIp: "94.140.14.14 94.140.15.15"
                            }
                            DnsOption {
                                label: "Quad9"
                                providerId: "quad9"
                                providerIp: "9.9.9.9 149.112.112.112"
                            }

                            Repeater {
                                model: mainInstance ? mainInstance.customProviders : []
                                delegate: DnsOption {
                                    label: modelData.label
                                    providerId: "custom_" + index
                                    providerIp: modelData.ip
                                    isCustom: true
                                    customIndex: index
                                }
                            }
                        }
                    }

                    // Add Custom Server Button / Form
                    NButton {
                        Layout.fillWidth: true
                        text: root.isAdding
                              ? (pluginApi?.tr("panel.cancel") || "Cancel")
                              : (pluginApi?.tr("panel.add_server") || "Add Custom Server")
                        icon: root.isAdding ? "x" : "plus"
                        backgroundColor: root.isAdding ? Color.mSurfaceVariant : Qt.alpha(Color.mPrimary, 0.15)
                        textColor: root.isAdding ? Color.mOnSurface : Color.mPrimary
                        enabled: !(mainInstance?.isChanging || false)
                        onClicked: {
                            root.isAdding = !root.isAdding;
                            if (!root.isAdding) {
                                root.newName = "";
                                root.newIp = "";
                                root.validationError = "";
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        visible: root.isAdding
                        spacing: Style.marginS

                        RowLayout {
                            spacing: Style.marginS

                            NTextInput {
                                id: nameInput
                                Layout.fillWidth: true
                                label: pluginApi?.tr("panel.name_placeholder") || "Name"
                                placeholderText: "e.g. Work DNS"
                                text: root.newName
                                onTextChanged: {
                                    root.newName = text;
                                    root.validationError = "";
                                }
                            }

                            NTextInput {
                                id: ipInput
                                Layout.fillWidth: true
                                label: pluginApi?.tr("panel.ip_placeholder") || "IP Address"
                                placeholderText: "e.g. 1.2.3.4"
                                text: root.newIp
                                onTextChanged: {
                                    root.newIp = text;
                                    root.validationError = "";
                                }
                            }
                        }

                        NText {
                            Layout.fillWidth: true
                            visible: root.validationError !== ""
                            text: root.validationError
                            color: Color.mError
                            pointSize: Style.fontSizeXS
                            wrapMode: Text.WordWrap
                        }

                        NButton {
                            Layout.fillWidth: true
                            text: pluginApi?.tr("panel.save") || "Save Server"
                            icon: "check"
                            enabled: root.newName.trim() !== "" && root.newIp.trim() !== ""
                            onClicked: {
                                if (mainInstance) {
                                    var success = mainInstance.addCustomServer(root.newName, root.newIp);
                                    if (success) {
                                        root.newName = "";
                                        root.newIp = "";
                                        root.isAdding = false;
                                        root.validationError = "";
                                    } else {
                                        root.validationError = pluginApi?.tr("error.invalid_ip")
                                                               || "Invalid IP format. Use: x.x.x.x or x.x.x.x x.x.x.x";
                                    }
                                }
                            }
                        }
                    }

                    // Domain Routing Navigation Button
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Style.marginS

                        NButton {
                            Layout.fillWidth: true
                            text: pluginApi?.tr("panel.routing_settings") || "Domain Routing Settings"
                            icon: "settings"
                            backgroundColor: Qt.alpha(Color.mSecondary, 0.15)
                            textColor: Color.mSecondary
                            enabled: !(mainInstance?.isChanging || false)
                            onClicked: {
                                root.showRouting = true;
                            }
                        }

                        Rectangle {
                            id: statusDot
                            Layout.preferredWidth: Math.round(28 * Style.uiScaleRatio)
                            Layout.preferredHeight: Math.round(28 * Style.uiScaleRatio)
                            radius: width / 2
                            color: mainInstance?.routingEnabled ? Qt.alpha(Color.mPrimary, 0.15) : Color.mSurfaceVariant
                            border.color: mainInstance?.routingEnabled ? Color.mPrimary : Qt.alpha(Color.mOutline, 0.2)
                            border.width: 1

                            Behavior on color { ColorAnimation { duration: 150 } }

                            NIcon {
                                anchors.centerIn: parent
                                icon: mainInstance?.routingEnabled ? "check" : "circle"
                                pointSize: Style.fontSizeXS
                                color: mainInstance?.routingEnabled ? Color.mPrimary : Color.mOnSurfaceVariant
                            }
                        }
                    }

                    // Reset Button
                    NButton {
                        Layout.fillWidth: true
                        text: pluginApi?.tr("panel.reset") || "Reset to Default (ISP)"
                        icon: "refresh"
                        backgroundColor: Qt.alpha(Color.mError, 0.15)
                        textColor: Color.mError
                        enabled: !(mainInstance?.isChanging || false)
                                 && (mainInstance?.isCustomDns || false)
                        onClicked: {
                            if (mainInstance) {
                                mainInstance.setDns("default");
                            }
                            if (pluginApi) {
                                pluginApi.withCurrentScreen(function(s) {
                                    pluginApi.closePanel(s);
                                });
                            }
                        }
                    }
                }

                // ROUTING VIEW — always rendered, opacity-managed by transitions
                ColumnLayout {
                    id: routingPane
                    width: parent.width
                    spacing: Style.marginM
                    opacity: 0
                    enabled: opacity > 0.01

                    // Enable/Disable Toggle
                    NButton {
                        Layout.fillWidth: true
                        text: mainInstance?.routingEnabled 
                              ? (pluginApi?.tr("panel.routing_status_enabled") || "Domain Routing Status: ENABLED") 
                              : (pluginApi?.tr("panel.routing_status_disabled") || "Domain Routing Status: DISABLED")
                        icon: mainInstance?.routingEnabled ? "check" : "circle"
                        backgroundColor: mainInstance?.routingEnabled ? Qt.alpha(Color.mPrimary, 0.15) : Color.mSurfaceVariant
                        textColor: mainInstance?.routingEnabled ? Color.mPrimary : Color.mOnSurface
                        enabled: !(mainInstance?.isChanging || false)
                        onClicked: {
                            if (mainInstance) {
                                mainInstance.toggleRouting();
                            }
                        }
                    }

                    // Add Rule Form
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: addRuleLayout.implicitHeight + Style.marginM * 2
                        color: Color.mSurfaceVariant
                        radius: Style.radiusM
                        border.color: Qt.alpha(Color.mOutline, 0.1)
                        border.width: 1

                        ColumnLayout {
                            id: addRuleLayout
                            anchors.fill: parent
                            anchors.margins: Style.marginM
                            spacing: Style.marginS

                            NText {
                                text: pluginApi?.tr("panel.routing_add_title") || "Add New Domain Routing Rule"
                                pointSize: Style.fontSizeS
                                font.weight: Font.DemiBold
                                color: Color.mOnSurface
                            }

                            NComboBox {
                                id: dnsSelectCombo
                                Layout.fillWidth: true
                                label: pluginApi?.tr("panel.routing_dns_label") || "Target DNS Server"
                                model: root.dnsComboModel
                                currentKey: root.selectedDnsIp
                                onSelected: function(key) {
                                    root.selectedDnsIp = key;
                                    root.routingRuleError = "";
                                }
                            }

                            NTextInput {
                                id: customDnsIpInput
                                Layout.fillWidth: true
                                visible: root.isCustomDnsInputSelected
                                label: pluginApi?.tr("panel.routing_custom_dns_ip") || "Enter DNS IP Address"
                                placeholderText: "e.g. 8.8.8.8"
                                text: root.customDnsIpText
                                onTextChanged: {
                                    root.customDnsIpText = text;
                                    root.routingRuleError = "";
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: Style.marginXS

                                NText {
                                    text: pluginApi?.tr("panel.routing_domains_label") || "Domains to Route"
                                    pointSize: Style.fontSizeXS
                                    color: Color.mSecondary
                                    font.weight: Font.Medium
                                }

                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: Math.min(Math.round(140 * Style.uiScaleRatio), 
                                                                     Math.max(Math.round(40 * Style.uiScaleRatio), 
                                                                              domainsArea.implicitHeight + Style.marginS * 2))
                                    radius: Style.radiusS
                                    color: Color.mSurfaceVariant
                                    border.color: domainsArea.activeFocus ? Color.mPrimary : Qt.alpha(Color.mOutline, 0.1)
                                    border.width: 1
                                    clip: true

                                    Behavior on border.color { ColorAnimation { duration: 150 } }

                                    ScrollView {
                                        anchors.fill: parent
                                        anchors.margins: Style.marginS
                                        clip: true
                                        ScrollBar.vertical.policy: domainsArea.implicitHeight > (parent.height - Style.marginS * 2) 
                                                                   ? ScrollBar.AlwaysOn 
                                                                   : ScrollBar.AlwaysOff

                                        TextArea {
                                            id: domainsArea
                                            width: parent.width
                                            wrapMode: TextArea.Wrap
                                            placeholderText: "e.g. google.com blocked.org"
                                            placeholderTextColor: Qt.alpha(Color.mOnSurfaceVariant, 0.4)
                                            background: null
                                            color: Color.mOnSurface
                                            font.pointSize: Style.fontSizeM
                                            selectedTextColor: Color.mOnPrimary
                                            selectionColor: Color.mPrimary
                                            text: root.routingRuleDomains
                                            onTextChanged: {
                                                if (text !== root.routingRuleDomains) {
                                                    root.routingRuleDomains = text;
                                                    root.routingRuleError = "";
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            NText {
                                Layout.fillWidth: true
                                visible: root.routingRuleError !== ""
                                text: root.routingRuleError
                                color: Color.mError
                                pointSize: Style.fontSizeXS
                            }

                            NButton {
                                Layout.fillWidth: true
                                text: pluginApi?.tr("panel.routing_add_button") || "Add Domain Route"
                                icon: "plus"
                                enabled: (root.isCustomDnsInputSelected ? root.customDnsIpText.trim() !== "" : true) 
                                         && root.routingRuleDomains.trim() !== ""
                                onClicked: {
                                    if (mainInstance) {
                                        var targetIp = root.isCustomDnsInputSelected ? root.customDnsIpText.trim() : root.selectedDnsIp;
                                        var ok = mainInstance.addRoutingRules(root.routingRuleDomains, targetIp);
                                        if (ok) {
                                            root.routingRuleDomains = "";
                                            root.routingRuleError = "";
                                            if (root.isCustomDnsInputSelected) {
                                                root.customDnsIpText = "";
                                            }
                                        } else {
                                            root.routingRuleError = pluginApi?.tr("error.invalid_rule") || "Invalid Domain or DNS IP format.";
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Rules List Title
                    NText {
                        text: pluginApi?.tr("panel.routing_active_rules") || "Active Routing Rules"
                        pointSize: Style.fontSizeS
                        font.weight: Font.DemiBold
                        color: Color.mSecondary
                    }

                    // Rules Scroll List
                    NScrollView {
                        Layout.fillWidth: true
                        Layout.preferredHeight: Math.min(Math.round(180 * Style.uiScaleRatio), contentHeight)
                        clip: true

                        ColumnLayout {
                            width: parent.width
                            spacing: Style.marginXS

                            Repeater {
                                model: mainInstance ? mainInstance.routingRules : []
                                delegate: Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: Math.round(44 * Style.uiScaleRatio)
                                    color: Color.mSurfaceVariant
                                    radius: Style.radiusS
                                    border.color: Qt.alpha(Color.mOutline, 0.05)
                                    border.width: 1

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: Style.marginM
                                        anchors.rightMargin: Style.marginM
                                        spacing: Style.marginM

                                        NIcon {
                                            icon: "arrow-up-right"
                                            pointSize: Style.fontSizeS
                                            color: Color.mPrimary
                                        }

                                        NText {
                                            text: modelData.domain
                                            pointSize: Style.fontSizeM
                                            font.weight: Font.Medium
                                            color: Color.mOnSurface
                                            Layout.fillWidth: true
                                        }

                                        NIcon {
                                            icon: "server"
                                            pointSize: Style.fontSizeXS
                                            color: Color.mSecondary
                                        }

                                        NText {
                                            text: modelData.dnsIp
                                            pointSize: Style.fontSizeS
                                            color: Color.mOnSurfaceVariant
                                        }

                                        NIconButton {
                                            icon: "trash"
                                            colorFg: Color.mError
                                            enabled: !(mainInstance?.isChanging || false)
                                            onClicked: {
                                                if (mainInstance) {
                                                    mainInstance.removeRoutingRule(index);
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            NText {
                                visible: (mainInstance ? mainInstance.routingRules.length : 0) === 0
                                text: pluginApi?.tr("panel.routing_no_rules") || "No routing rules added yet."
                                color: Color.mOnSurfaceVariant
                                opacity: 0.5
                                pointSize: Style.fontSizeS
                                horizontalAlignment: Text.AlignHCenter
                                Layout.fillWidth: true
                                Layout.margins: Style.marginL
                            }
                        }
                    }

                    // Save & Apply Button
                    NButton {
                        Layout.fillWidth: true
                        text: pluginApi?.tr("panel.routing_save_apply") || "Save & Apply Routing Rules"
                        icon: "refresh"
                        backgroundColor: Qt.alpha(Color.mPrimary, 0.15)
                        textColor: Color.mPrimary
                        enabled: !(mainInstance?.isChanging || false)
                        onClicked: {
                            if (mainInstance) {
                                mainInstance.saveAndApplyRouting();
                            }
                        }
                    }
                }
            }
        }
    }
}
