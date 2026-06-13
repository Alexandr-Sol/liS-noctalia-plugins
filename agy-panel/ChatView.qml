import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

Item {
    id: chatViewRoot
    anchors.fill: parent

    property var pluginApi
    property var mainInstance
    property bool isGenerating: false
    property real contentPreferredHeight: 800

    property var animatedMessageIds: ({})

    ColumnLayout {
        anchors.fill: parent
        spacing: Style.marginS

        // ═══════════════════════════════════════════
        // Binary warning
        // ═══════════════════════════════════════════
        Rectangle {
            Layout.fillWidth: true
            visible: mainInstance && mainInstance.binaryChecked && !mainInstance.binaryAvailable
            Layout.preferredHeight: visible ? binaryWarnText.implicitHeight + Style.marginM * 2 : 0
            color: Qt.rgba(0.9, 0.2, 0.2, 0.1)
            border.color: Color.mError
            radius: Style.radiusL

            NText {
                id: binaryWarnText
                anchors.fill: parent
                anchors.margins: Style.marginM
                text: (pluginApi && pluginApi.tr ? pluginApi.tr("errors.binaryMissing") : "agy-bridge не найден. Укажите правильный путь в настройках.")
                wrapMode: Text.WordWrap
                color: Color.mError
                pointSize: Style.fontSizeS
            }
        }

        // ═══════════════════════════════════════════
        // Chat area
        // ═══════════════════════════════════════════
        Rectangle {
            id: chatArea
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: Color.mSurfaceVariant
            radius: Style.radiusL
            clip: true

            Flickable {
                id: chatFlickable
                anchors.fill: parent
                contentWidth: width
                contentHeight: messagesColumn.implicitHeight + Style.marginM * 2
                boundsBehavior: Flickable.StopAtBounds
                flickableDirection: Flickable.VerticalFlick
                clip: true

                property bool stickBottom: true

                function scrollToBottom() {
                    var target = Math.max(0, contentHeight - height);
                    contentY = target;
                }

                function isNearBottom() {
                    return contentHeight <= height || (contentY >= contentHeight - height - 48);
                }

                onContentHeightChanged: {
                    if (stickBottom) { Qt.callLater(scrollToBottom); }
                }

                onMovementEnded: {
                    stickBottom = isNearBottom();
                }

                Column {
                    id: messagesColumn
                    width: chatFlickable.width
                    topPadding: Style.marginM
                    bottomPadding: Style.marginM
                    leftPadding: Style.marginM
                    rightPadding: Style.marginM
                    spacing: Style.marginS

                    // Empty state
                    Item {
                        visible: (mainInstance && mainInstance.messages ? mainInstance.messages.length : 0) === 0 && !chatViewRoot.isGenerating
                        width: messagesColumn.width - messagesColumn.leftPadding - messagesColumn.rightPadding
                        height: chatFlickable.height - messagesColumn.topPadding - messagesColumn.bottomPadding

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: Style.marginS

                            NIcon {
                                Layout.alignment: Qt.AlignHCenter
                                icon: "sparkles"
                                color: Color.mOnSurfaceVariant
                                pointSize: Style.fontSizeXXL
                                opacity: 0.4
                            }
                            NText {
                                Layout.alignment: Qt.AlignHCenter
                                text: "Antigravity CLI"
                                pointSize: Style.fontSizeL
                                color: Color.mOnSurfaceVariant
                                opacity: 0.5
                            }
                            NText {
                                Layout.alignment: Qt.AlignHCenter
                                text: pluginApi?.tr("panel.emptyHintNonInteractive") || "Введите запрос для запуска в неинтерактивном режиме"
                                pointSize: Style.fontSizeS
                                color: Color.mOnSurfaceVariant
                                opacity: 0.35
                            }
                        }
                    }

                    Repeater {
                        id: messagesRepeater
                        model: (mainInstance && mainInstance.messages ? mainInstance.messages : [])
                        delegate: MessageCard {
                            width: messagesColumn.width - messagesColumn.leftPadding - messagesColumn.rightPadding
                            entry: modelData
                            pluginApi: chatViewRoot.pluginApi
                            mainInst: chatViewRoot.mainInstance
                        }
                        onModelChanged: {
                            if (!model || model.length === 0) {
                                chatViewRoot.animatedMessageIds = {};
                            }
                        }
                    }

                    StreamingCard {
                        visible: chatViewRoot.isGenerating
                        width: messagesColumn.width - messagesColumn.leftPadding - messagesColumn.rightPadding
                        pluginApi: chatViewRoot.pluginApi
                        mainInst: chatViewRoot.mainInstance
                    }
                }
            }

            // Scroll-to-bottom button
            Rectangle {
                id: scrollDownBtn
                visible: opacity > 0
                opacity: !chatFlickable.isNearBottom() && (mainInstance && mainInstance.messages ? mainInstance.messages.length : 0) > 0 ? 1.0 : 0.0
                scale: opacity > 0.5 ? 1.0 : 0.8
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottomMargin: Style.marginM
                z: 10

                implicitHeight: scrollRow.implicitHeight + Style.marginXS * 2
                implicitWidth: scrollRow.implicitWidth + Style.marginM * 2
                radius: height / 2
                color: Color.mSecondary

                Behavior on opacity {
                    NumberAnimation { duration: 180; easing.type: Easing.InOutQuad }
                }
                Behavior on scale {
                    NumberAnimation { duration: 180; easing.type: Easing.InOutQuad }
                }

                RowLayout {
                    id: scrollRow
                    anchors.centerIn: parent
                    spacing: Style.marginXS
                    NIcon { icon: "arrow-down"; color: Color.mOnSecondary; pointSize: Style.fontSizeXS }
                    NText { text: pluginApi?.tr("panel.scrollToBottom") || "Прокрутить вниз"; color: Color.mOnSecondary; pointSize: Style.fontSizeXS }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        chatFlickable.stickBottom = true;
                        chatFlickable.scrollToBottom();
                    }
                }
            }
        }

        // ═══════════════════════════════════════════
        // Error strip
        // ═══════════════════════════════════════════
        Rectangle {
            Layout.fillWidth: true
            visible: mainInstance && mainInstance.errorMessage !== ""
            Layout.preferredHeight: visible ? errText.implicitHeight + Style.marginM * 2 : 0
            color: Qt.rgba(0.9, 0.2, 0.2, 0.10)
            border.color: Color.mError
            radius: Style.radiusL

            RowLayout {
                anchors.fill: parent
                anchors.margins: Style.marginM
                spacing: Style.marginM

                NIcon { icon: "alert-circle"; color: Color.mError; pointSize: Style.fontSizeM }

                NText {
                    id: errText
                    Layout.fillWidth: true
                    text: (mainInstance && mainInstance.errorMessage ? mainInstance.errorMessage : "")
                    wrapMode: Text.Wrap
                    color: Color.mError
                    pointSize: Style.fontSizeS
                }

                NIconButton {
                    icon: "x"
                    baseSize: Style.baseWidgetSize
                    colorFg: Color.mError
                    onClicked: { if (mainInstance) mainInstance.errorMessage = ""; }
                }
            }
        }

        // ═══════════════════════════════════════════
        // Input area
        // ═══════════════════════════════════════════
        Rectangle {
            Layout.fillWidth: true
            color: Color.mSurface
            radius: Style.radiusL
            implicitHeight: inputColumn.implicitHeight + Style.marginM * 2
            clip: true

            Column {
                id: inputColumn
                anchors.fill: parent
                anchors.margins: Style.marginM
                spacing: Style.marginS

                // Image preview container
                Item {
                    id: imagePreviewContainer
                    width: parent.width
                    clip: true
                    
                    property bool hasImages: mainInstance && mainInstance.pastedImagePaths && mainInstance.pastedImagePaths.length > 0
                    height: hasImages ? 80 : 0
                    visible: height > 0

                    Behavior on height {
                        NumberAnimation { duration: 150; easing.type: Easing.OutQuad }
                    }

                    RowLayout {
                        anchors.fill: parent
                        spacing: Style.marginS
                        
                        ScrollView {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            contentWidth: thumbnailsRow.implicitWidth
                            contentHeight: height
                            ScrollBar.horizontal.policy: ScrollBar.AsNeeded
                            ScrollBar.vertical.policy: ScrollBar.AlwaysOff
                            clip: true

                            Row {
                                id: thumbnailsRow
                                spacing: Style.marginS
                                height: parent.height

                                Repeater {
                                    model: mainInstance && mainInstance.pastedImagePaths ? mainInstance.pastedImagePaths : []
                                    delegate: Rectangle {
                                        id: thumbContainer
                                        width: 80
                                        height: 80
                                        radius: Style.radiusS
                                        color: Color.mSurfaceVariant
                                        clip: true
                                        
                                        Image {
                                            anchors.fill: parent
                                            source: modelData ? "file://" + modelData : ""
                                            fillMode: Image.PreserveAspectCrop
                                        }
                                        
                                        NIconButton {
                                            anchors.top: parent.top
                                            anchors.right: parent.right
                                            anchors.margins: 4
                                            icon: "x"
                                            baseSize: Style.baseWidgetSize * 0.75
                                            colorFg: Color.mError
                                            onClicked: {
                                                if (mainInstance) {
                                                    var paths = [...mainInstance.pastedImagePaths];
                                                    paths.splice(index, 1);
                                                    mainInstance.pastedImagePaths = paths;
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        
                        NText {
                            text: mainInstance && mainInstance.pastedImagePaths && mainInstance.pastedImagePaths.length > 1
                                  ? (pluginApi?.tr("panel.imagesAttachedCount") || "Изображения прикреплены") + " (" + mainInstance.pastedImagePaths.length + ")"
                                  : (pluginApi?.tr("panel.imageAttached") || "Изображение прикреплено")
                            pointSize: Style.fontSizeXS
                            color: Color.mOnSurfaceVariant
                            Layout.alignment: Qt.AlignVCenter
                        }
                    }
                }

                ScrollView {
                    id: inputScrollView
                    width: parent.width
                    height: Math.min(chatViewRoot.contentPreferredHeight * 0.28, Math.max(inputTextArea.implicitHeight, Style.baseWidgetSize))
                    clip: true
                    ScrollBar.vertical.policy: ScrollBar.AsNeeded

                    Behavior on height {
                        NumberAnimation { duration: 150; easing.type: Easing.OutQuad }
                    }

                    TextArea {
                        id: inputTextArea
                        width: inputScrollView.width
                        wrapMode: TextArea.Wrap
                        placeholderText: pluginApi?.tr("panel.inputPlaceholderCombined") || "Спросите Antigravity... (Enter для отправки, Shift+Enter для новой строки)"
                        placeholderTextColor: Qt.alpha(Color.mOnSurfaceVariant, 0.4)
                        background: null
                        color: activeFocus ? Color.mOnSurface : Color.mOnSurfaceVariant
                        font.pointSize: Style.fontSizeL
                        padding: 0
                        topPadding: 0
                        bottomPadding: 0
                        selectedTextColor: Color.mOnPrimary
                        selectionColor: Color.mPrimary

                        text: (mainInstance && mainInstance.inputText ? mainInstance.inputText : "")

                        onTextChanged: {
                            if (mainInstance) {
                                mainInstance.inputText = text;
                                mainInstance.saveState();
                            }
                        }

                        Keys.onPressed: function(event) {
                            if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter)) {
                                if (event.modifiers & Qt.ShiftModifier) {
                                    insert(cursorPosition, "\n");
                                    event.accepted = true;
                                } else {
                                    chatViewRoot.submit();
                                    event.accepted = true;
                                }
                            } else if (event.key === Qt.Key_V && (event.modifiers & Qt.ControlModifier)) {
                                if (mainInstance) {
                                    mainInstance.pasteFromClipboard();
                                }
                                event.accepted = true;
                            }
                        }
                    }
                }

                RowLayout {
                    width: parent.width
                    spacing: Style.marginXS

                    // Status Chips for Sandbox and Auto-Approve
                    Rectangle {
                        visible: mainInstance && mainInstance.agySettings && mainInstance.agySettings.sandbox === true
                        implicitHeight: sandboxChipText.implicitHeight + Style.marginXS * 2
                        implicitWidth: sandboxChipText.implicitWidth + Style.marginS * 2
                        color: Qt.alpha(Color.mSecondary, 0.10)
                        radius: Style.radiusS

                        NText {
                            id: sandboxChipText
                            anchors.centerIn: parent
                            text: pluginApi?.tr("panel.sandboxLabel") || "Песочница"
                            pointSize: Style.fontSizeXS; color: Color.mSecondary
                        }
                    }

                    Rectangle {
                        visible: mainInstance && mainInstance.agySettings && mainInstance.agySettings.dangerouslySkipPermissions === true
                        implicitHeight: yoloChipText.implicitHeight + Style.marginXS * 2
                        implicitWidth: yoloChipText.implicitWidth + Style.marginS * 2
                        color: Qt.alpha(Color.mError, 0.10)
                        radius: Style.radiusS

                        NText {
                            id: yoloChipText
                            anchors.centerIn: parent
                            text: pluginApi?.tr("panel.autoApproveLabel") || "Авто-одобрение"
                            pointSize: Style.fontSizeXS; color: Color.mError
                        }
                    }

                    Item { Layout.fillWidth: true }

                    NIconButton {
                        icon: "clipboard"
                        baseSize: Style.baseWidgetSize
                        colorFg: Color.mOnSurfaceVariant
                        enabled: !!mainInstance
                        onClicked: {
                            if (mainInstance) {
                                mainInstance.pasteFromClipboard();
                            }
                        }

                        Connections {
                            target: chatViewRoot.mainInstance ? chatViewRoot.mainInstance : null
                            function onPastedTextChanged() {
                                var t = chatViewRoot.mainInstance && chatViewRoot.mainInstance.pastedText ? chatViewRoot.mainInstance.pastedText : "";
                                if (t && t !== "") {
                                    var trimmed = t.trim();
                                    if (trimmed.indexOf("/tmp/agy_paste_") === 0 && trimmed.indexOf(".png") !== -1) {
                                        var paths = chatViewRoot.mainInstance.pastedImagePaths || [];
                                        chatViewRoot.mainInstance.pastedImagePaths = [...paths, trimmed];
                                    } else {
                                        var pos = inputTextArea.cursorPosition;
                                        inputTextArea.insert(pos, t);
                                    }
                                    chatViewRoot.mainInstance.pastedText = "";
                                }
                            }
                        }
                    }

                    NButton {
                        text: chatViewRoot.isGenerating ? (pluginApi?.tr("panel.stop") || "Стоп") : (pluginApi?.tr("panel.send") || "Отправить")
                        icon: chatViewRoot.isGenerating ? "square" : "send"
                        enabled: !!mainInstance && (chatViewRoot.isGenerating || (mainInstance.binaryAvailable && (inputTextArea.text.trim().length > 0 || (mainInstance.pastedImagePaths && mainInstance.pastedImagePaths.length > 0))))
                        onClicked: chatViewRoot.isGenerating ? mainInstance.stopGeneration() : chatViewRoot.submit()
                    }
                }
            }
        }
    }

    function submit() {
        if (!mainInstance) { return; }
        var t = inputTextArea.text;
        var hasImg = mainInstance.pastedImagePaths && mainInstance.pastedImagePaths.length > 0;
        if ((!t || t.trim() === "") && !hasImg) { return; }
        
        var trimmed = t.trim();
        if (trimmed[0] === "/" && mainInstance.handleSlashCommand(trimmed)) {
            inputTextArea.text = "";
            mainInstance.inputText = "";
            mainInstance.saveState();
            return;
        }
        
        if (hasImg) {
            var imgPrompt = trimmed;
            if (imgPrompt !== "") {
                imgPrompt += "\n\n";
            }
            for (var i = 0; i < mainInstance.pastedImagePaths.length; i++) {
                imgPrompt += "[Прикрепленное изображение: " + mainInstance.pastedImagePaths[i] + "]\n";
            }
            mainInstance.sendMessage(imgPrompt.trim());
            mainInstance.pastedImagePaths = [];
        } else {
            mainInstance.sendMessage(trimmed);
        }
        
        inputTextArea.text = "";
        mainInstance.inputText = "";
        mainInstance.saveState();
    }

    function forceFocus() {
        inputTextArea.forceActiveFocus();
    }

    Connections {
        target: mainInstance ? mainInstance : null
        function onForceInputFocus() {
            chatViewRoot.forceFocus();
        }
    }



    // ═══════════════════════════════════════════════════════════
    // ═══════════════════════════════════════════════════════════
    // StreamingCard — live assistant bubble during generation.
    // ═══════════════════════════════════════════════════════════
    component StreamingCard: Rectangle {
        id: streamRoot
        property var pluginApi
        property var mainInst

        radius: Style.radiusL
        color: Color.mSurface
        implicitHeight: streamInner.implicitHeight + Style.marginM * 2

        Behavior on height {
            NumberAnimation { duration: 150; easing.type: Easing.OutQuad }
        }

        visible: chatViewRoot.isGenerating
        height: visible ? implicitHeight : 0

        Rectangle {
            anchors {
                left: parent.left; top: parent.top; bottom: parent.bottom
                topMargin: Style.radiusL; bottomMargin: Style.radiusL
            }
            width: 3; radius: 2; color: Color.mPrimary
        }

        Column {
            id: streamInner
            anchors { fill: parent; margins: Style.marginM; leftMargin: Style.marginM + 6 }
            spacing: Style.marginS

            RowLayout {
                width: parent.width
                spacing: Style.marginS

                NIcon {
                    id: spinnerIcon
                    icon: "loader-2"
                    color: Color.mPrimary
                    pointSize: Style.fontSizeM
                    Layout.alignment: Qt.AlignVCenter

                    RotationAnimation on rotation {
                        running: chatViewRoot.isGenerating
                        from: 0; to: 360; duration: 1200; loops: Animation.Infinite
                    }
                }

                NText {
                    text: pluginApi?.tr("panel.executingRequest") || "Выполнение запроса..."
                    font.weight: Font.Medium
                    pointSize: Style.fontSizeM
                    color: Color.mOnSurfaceVariant
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                }
            }
        }
    }

    // ═══════════════════════════════════════════════════════════
    // MessageCard component
    // ═══════════════════════════════════════════════════════════
    component MessageCard: Rectangle {
        id: cardRoot
        property var entry
        property var pluginApi
        property var mainInst

        property var extractedData: {
            var text = (entry && entry.text !== undefined) ? entry.text : "";
            var paths = [];
            var regex = /\[Прикрепленное изображение:\s*([^\]]+)\]/g;
            var match;
            var cleanText = text;
            while ((match = regex.exec(text)) !== null) {
                paths.push(match[1].trim());
            }
            cleanText = cleanText.replace(/\[Прикрепленное изображение:\s*[^\]]+\]\n?/g, "").trim();
            return {
                cleanText: cleanText,
                imagePaths: paths
            };
        }

        visible: entry !== undefined
        height: visible ? implicitHeight : 0
        radius: Style.radiusL
        implicitHeight: cardInner.implicitHeight + Style.marginM * 2

        opacity: (entry && chatViewRoot.animatedMessageIds[entry.id]) ? 1.0 : 0.0
        scale: (entry && chatViewRoot.animatedMessageIds[entry.id]) ? 1.0 : 0.95
        transform: Translate {
            id: trans
            y: (entry && chatViewRoot.animatedMessageIds[entry.id]) ? 0 : 15
        }

        Component.onCompleted: {
            if (entry && !chatViewRoot.animatedMessageIds[entry.id]) {
                chatViewRoot.animatedMessageIds[entry.id] = true;
                appearAnim.start();
            }
        }

        ParallelAnimation {
            id: appearAnim
            NumberAnimation { target: cardRoot; property: "opacity"; to: 1.0; duration: 250; easing.type: Easing.OutQuad }
            NumberAnimation { target: cardRoot; property: "scale"; to: 1.0; duration: 250; easing.type: Easing.OutQuad }
            NumberAnimation { target: trans; property: "y"; to: 0; duration: 250; easing.type: Easing.OutQuad }
        }

        color: {
            if (!entry) { return Color.mSurface; }
            if (entry.role === "user") { return Qt.alpha(Color.mPrimary, 0.10); }
            if (entry.role === "tool") { return Qt.alpha(Color.mOnSurface, 0.04); }
            return Color.mSurface;
        }

        function roleAccent() {
            if (!entry) { return Color.mOnSurface; }
            if (entry.role === "user") { return Color.mPrimary; }
            if (entry.role === "tool" && entry.meta && entry.meta.isError) { return Color.mError; }
            return Color.mPrimary;
        }

        function headerIcon() {
            if (!entry) { return "circle"; }
            if (entry.role === "user") { return "user"; }
            if (entry.role === "tool") {
                return (entry.meta && entry.meta.isError) ? "ghost" : "check-circle";
            }
            return "sparkles";
        }

        function headerLabel() {
            if (!entry) { return ""; }
            if (entry.role === "user") { return pluginApi?.tr("panel.roleUser") || "Вы"; }
            if (entry.role === "tool") {
                var label = pluginApi?.tr("panel.toolResult") || "Результат";
                if (entry.meta && entry.meta.isError) { label += " (" + (pluginApi?.tr("panel.errorLabel") || "Ошибка") + ")"; }
                return label;
            }
            return "Antigravity";
        }

        Rectangle {
            anchors {
                left: parent.left; top: parent.top; bottom: parent.bottom
                topMargin: Style.radiusL; bottomMargin: Style.radiusL; leftMargin: 0
            }
            width: 3; radius: 2; color: cardRoot.roleAccent()
        }

        Column {
            id: cardInner
            anchors { fill: parent; margins: Style.marginM; leftMargin: Style.marginM + 6 }
            spacing: Style.marginS

            Item {
                width: parent.width
                height: headerRowLayout.implicitHeight
                RowLayout {
                    id: headerRowLayout; anchors.fill: parent; spacing: Style.marginS
                    NIcon { icon: cardRoot.headerIcon(); color: cardRoot.roleAccent(); pointSize: Style.fontSizeM }
                    NText { text: cardRoot.headerLabel(); font.weight: Font.DemiBold; pointSize: Style.fontSizeM; color: Color.mOnSurface }
                    Item { Layout.fillWidth: true }
                    NText {
                        visible: entry && entry.timestamp
                        text: {
                            if (!entry || !entry.timestamp) return "";
                            var d = new Date(entry.timestamp);
                            return d.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
                        }
                        pointSize: Style.fontSizeXS; color: Color.mOnSurfaceVariant; opacity: 0.5
                    }
                    NIconButton {
                        visible: cardRoot.extractedData && cardRoot.extractedData.cleanText !== ""
                        icon: "copy"; baseSize: Style.baseWidgetSize * 0.85; colorFg: Color.mOnSurfaceVariant
                        onClicked: { if (cardRoot.mainInst && cardRoot.extractedData) cardRoot.mainInst.copyToClipboard(cardRoot.extractedData.cleanText); }
                    }
                }
            }

            Item {
                width: parent.width
                height: bodyLayout.implicitHeight
                RowLayout {
                    id: bodyLayout; width: parent.width; spacing: Style.marginXS
                    TextEdit {
                        Layout.fillWidth: true
                        text: cardRoot.extractedData ? cardRoot.extractedData.cleanText : ""
                        wrapMode: TextEdit.Wrap
                        textFormat: TextEdit.MarkdownText
                        readOnly: true
                        selectByMouse: true
                        persistentSelection: true
                        color: (entry && entry.meta && entry.meta.isError) ? Color.mError : Color.mOnSurface
                        selectionColor: Color.mPrimary
                        selectedTextColor: Color.mOnPrimary
                        font.pointSize: {
                            var scale = (typeof Settings !== 'undefined' && Settings.data && Settings.data.ui && Settings.data.ui.fontDefaultScale) ? Settings.data.ui.fontDefaultScale : 1.0;
                            var ratio = (typeof Style !== 'undefined' && Style.uiScaleRatio) ? Style.uiScaleRatio : 1.0;
                            return Math.max(1, Style.fontSizeM * scale * ratio);
                        }
                        font.family: (typeof Settings !== 'undefined' && Settings.data && Settings.data.ui && Settings.data.ui.fontDefault) ? Settings.data.ui.fontDefault : "sans-serif"
                        visible: text !== ""
                        onLinkActivated: function(url) { Qt.openUrlExternally(url); }

                        HoverHandler {
                            cursorShape: parent.hoveredLink ? Qt.PointingHandCursor : Qt.IBeamCursor
                        }
                    }
                }
            }

            Item {
                width: parent.width
                height: visible ? imagesFlow.implicitHeight : 0
                visible: cardRoot.extractedData && cardRoot.extractedData.imagePaths && cardRoot.extractedData.imagePaths.length > 0

                Flow {
                    id: imagesFlow
                    width: parent.width
                    spacing: Style.marginS

                    Repeater {
                        model: cardRoot.extractedData ? cardRoot.extractedData.imagePaths : []
                        delegate: Rectangle {
                            width: Math.min(160, imagesFlow.width)
                            height: 120
                            radius: Style.radiusS
                            color: Color.mSurfaceVariant
                            clip: true

                            Image {
                                anchors.fill: parent
                                source: modelData ? "file://" + modelData : ""
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    Qt.openUrlExternally("file://" + modelData);
                                }

                                Rectangle {
                                    anchors.fill: parent
                                    color: Qt.rgba(1, 1, 1, 0.1)
                                    visible: parent.containsMouse
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
