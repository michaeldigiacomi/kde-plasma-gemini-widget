import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami
import "../code/GeminiService.js" as GeminiService
import "../code/ChatStorage.js" as ChatStorage

PlasmoidItem {
    id: root
    
    TextEdit {
        id: clipboardHelper
        visible: false
    }
    
    property var chatHistory: [] 
    property bool isLoading: false
    property int currentSessionId: -1
    property string currentTitle: "New Chat"

    ListModel { id: chatModel }
    ListModel { id: historyModel }

    Component.onCompleted: {
        // Load last session or create new
        var sessions = ChatStorage.getSessions();
        if (sessions.length > 0) {
            loadSession(sessions[0].id, sessions[0].title);
        } else {
            createNewSession();
        }
        refreshHistory();
    }

    function refreshHistory() {
        historyModel.clear();
        var sessions = ChatStorage.getSessions();
        for (var i = 0; i < sessions.length; i++) {
            historyModel.append(sessions[i]);
        }
    }

    function createNewSession() {
        chatModel.clear();
        chatHistory = [];
        // Create actual DB entry on first message, or now?
        // Let's create it on first message to avoid empty spam, 
        // OR just track it as -1 until send.
        currentSessionId = -1;
        currentTitle = "New Chat";
    }

    function loadSession(sid, title) {
        currentSessionId = sid;
        currentTitle = title;
        chatModel.clear();
        chatHistory = []; // We need to rebuild this for the AI context context
        
        var msgs = ChatStorage.getMessages(sid);
        for (var i = 0; i < msgs.length; i++) {
            var m = msgs[i];
            chatModel.append({ role: m.role, text: m.text });
            // Only add user/model to history, not system errors if stored (though we might not store errors usually)
            if (m.role === "user" || m.role === "model") {
                chatHistory.push({ role: m.role, text: m.text });
            }
        }
    } 

    function sendMessage() {
        var text = inputField.text.trim();
        if (text === "") return;
        
        var apiKey = Plasmoid.configuration.apiKey;
        var modelName = Plasmoid.configuration.modelName;

        if (!apiKey) {
            chatModel.append({ role: "system", text: "Please configure your API Key in the widget settings (Right-click -> Configure Gemini Desktop)." });
            return;
        }

        // Initialize session if needed
        if (currentSessionId === -1) {
            var title = text.length > 20 ? text.substring(0, 20) + "..." : text;
            currentSessionId = ChatStorage.createSession(title);
            currentTitle = title;
            refreshHistory(); // Refresh drawer list
        }

        // Add user message
        chatModel.append({ role: "user", text: text });
        chatHistory.push({ role: "user", text: text });
        ChatStorage.saveMessage(currentSessionId, "user", text);
        
        inputField.text = "";
        root.isLoading = true;

        GeminiService.generateContent(apiKey, modelName, chatHistory, text, function(response) {
            root.isLoading = false;
            if (response.error) {
                chatModel.append({ role: "system", text: "Error: " + response.error });
            } else {
                chatModel.append({ role: "model", text: response.text });
                chatHistory.push({ role: "model", text: response.text });
                ChatStorage.saveMessage(currentSessionId, "model", response.text);
            }
        });
    }

    // Default to full view (chat window)
    preferredRepresentation: fullRepresentation

    // Keep compact for panels, but on desktop we want full
    compactRepresentation: PlasmaComponents.ItemDelegate {
        icon.name: "google-gemini"
        text: "Gemini"
        onClicked: root.expanded = !root.expanded
    }

    fullRepresentation: Item {
        id: fullRep
        Layout.minimumWidth: Kirigami.Units.gridUnit * 20
        Layout.minimumHeight: Kirigami.Units.gridUnit * 30
        clip: true
        
        property bool historyOpen: false

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            // Header
            Rectangle {
                Layout.fillWidth: true
                height: Kirigami.Units.gridUnit * 2.5
                color: Kirigami.Theme.backgroundColor // headerBackgroundColor might be undefined
                
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: Kirigami.Units.smallSpacing
                    
                    Button {
                        icon.name: "view-history"
                        text: ""
                        ToolTip.visible: hovered
                        ToolTip.text: "History"
                        onClicked: fullRep.historyOpen = !fullRep.historyOpen
                    }
                    
                    Label {
                        Layout.fillWidth: true
                        text: root.currentTitle
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                    }
                    
                    Button {
                        icon.name: "document-new"
                        text: ""
                        ToolTip.visible: hovered
                        ToolTip.text: "New Chat"
                        onClicked: root.createNewSession()
                    }
                }
                
                // Bottom border
                Rectangle {
                    width: parent.width
                    height: 1
                    color: Kirigami.Theme.disabledTextColor // separatorColor might be undefined
                    anchors.bottom: parent.bottom
                }
            }


            
            ListView {
                id: chatView
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                model: chatModel
                displayMarginBeginning: 40
                displayMarginEnd: 40
                spacing: Kirigami.Units.largeSpacing
                
                // ... delegate ...

                delegate: ColumnLayout {
                    width: ListView.view.width
                    spacing: Kirigami.Units.smallSpacing
                    
                    property bool isUser: model.role === "user"
                    property bool isSystem: model.role === "system"

                    Layout.alignment: isSystem ? Qt.AlignHCenter : (isUser ? Qt.AlignRight : Qt.AlignLeft)

                    // Bubble
                    Rectangle {
                        Layout.maximumWidth: parent.width * 0.8
                        Layout.alignment: isSystem ? Qt.AlignHCenter : (isUser ? Qt.AlignRight : Qt.AlignLeft)
                        
                        // User: Highlight color, Model: Card/Background, System: transparent/gray
                        color: {
                            if (isSystem) return "transparent"
                            return isUser ? Kirigami.Theme.highlightColor : Kirigami.Theme.backgroundColor
                        }
                        
                        radius: Kirigami.Units.smallSpacing
                        border.width: isModel ? 1 : 0
                        border.color: Kirigami.Theme.disabledTextColor
                        
                        property bool isModel: model.role === "model"

                        implicitWidth: msgText.implicitWidth + (Kirigami.Units.largeSpacing * 2)
                        implicitHeight: msgText.implicitHeight + (Kirigami.Units.largeSpacing * 2)

                        Label {
                            id: msgText
                            anchors.centerIn: parent
                            width: Math.min(implicitWidth, parent.parent.width * 0.8 - (Kirigami.Units.largeSpacing * 2))
                            
                            text: model.text
                            color: {
                                if (isSystem) return Kirigami.Theme.disabledTextColor
                                return isUser ? Kirigami.Theme.highlightedTextColor : Kirigami.Theme.textColor
                            }
                            wrapMode: Text.Wrap
                            textFormat: Text.MarkdownText
                            
                            // Adjust padding via anchors in the parent rectangle slightly effectively
                            // But cleaner is just to let the Rect size itself.
                        }

                        MouseArea {
                            anchors.fill: parent
                            acceptedButtons: Qt.RightButton
                            onClicked: contextMenu.popup()
                        }

                        Menu {
                            id: contextMenu
                            MenuItem {
                                text: "Copy"
                                icon.name: "edit-copy"
                                onTriggered: {
                                    clipboardHelper.text = model.text
                                    clipboardHelper.selectAll()
                                    clipboardHelper.copy()
                                }
                            }
                        }
                    }
                    
                    // Small label for role (optional, maybe clearer without it for now to look cleaner)
                    Label {
                        visible: isSystem
                        text: model.text
                        font.italic: true
                        color: Kirigami.Theme.disabledTextColor
                        Layout.alignment: Qt.AlignHCenter
                        Layout.maximumWidth: parent.width * 0.9
                        wrapMode: Text.Wrap
                        horizontalAlignment: Text.AlignHCenter
                    }
                }

                // Scroll to bottom on add
                onCountChanged: {
                    Qt.callLater(function() {
                        chatView.positionViewAtEnd()
                    })
                }
            }

            // Input Area
            Rectangle {
                Layout.fillWidth: true
                height: inputRow.implicitHeight + Kirigami.Units.largeSpacing
                color: Kirigami.Theme.backgroundColor
                opacity: 0.8
                
                // Top border
                Rectangle {
                    width: parent.width
                    height: 1
                    color: Kirigami.Theme.disabledTextColor
                    anchors.top: parent.top
                }

                RowLayout {
                    id: inputRow
                    anchors.fill: parent
                    anchors.margins: Kirigami.Units.smallSpacing
                    
                    ScrollView {
                        Layout.fillWidth: true
                        Layout.maximumHeight: Kirigami.Units.gridUnit * 4
                        
                        TextArea {
                            id: inputField
                            placeholderText: "Message Gemini..."
                            enabled: !root.isLoading
                            wrapMode: Text.Wrap
                            color: Kirigami.Theme.textColor
                            
                            // Capture enter key to send, shift+enter for new line
                            Keys.onPressed: (event) => {
                                if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                    if (!(event.modifiers & Qt.ShiftModifier)) {
                                        sendMessage();
                                        event.accepted = true;
                                    }
                                }
                            }
                        }
                    }

                    Button {
                        Layout.alignment: Qt.AlignBottom
                        icon.name: "document-send"
                        text: "" 
                        enabled: inputField.text.length > 0 && !root.isLoading
                        onClicked: sendMessage()
                        ToolTip.visible: hovered
                        ToolTip.text: "Send Message"
                    }
                }
            }
        }

        // --- Custom Drawer Implementation ---
        // Dim background
        Rectangle {
            anchors.fill: parent
            color: "black"
            opacity: fullRep.historyOpen ? 0.3 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 200 } }
            MouseArea { anchors.fill: parent; onClicked: fullRep.historyOpen = false }
            z: 99
        }

        // Sliding Drawer
        Rectangle {
            id: drawer
            z: 100
            width: parent.width * 0.75
            // Start below the main header so the toggle button remains clickable
            y: Kirigami.Units.gridUnit * 2.5
            height: parent.height - y
            
            color: Kirigami.Theme.backgroundColor
            x: fullRep.historyOpen ? 0 : -width
            Behavior on x { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
            
            // Drawer separator
            Rectangle {
                width: 1
                height: parent.height
                anchors.right: parent.right
                color: Kirigami.Theme.disabledTextColor
            }

            ColumnLayout {
                anchors.fill: parent
                spacing: 0
                
                // History Header inside Drawer
                Rectangle {
                    Layout.fillWidth: true
                    height: Kirigami.Units.gridUnit * 2.5
                    color: Kirigami.Theme.backgroundColor
                    
                    Label {
                        anchors.centerIn: parent
                        text: "Chat History"
                        font.bold: true
                    }
                    
                    // Bottom border
                    Rectangle {
                        width: parent.width
                        height: 1
                        color: Kirigami.Theme.disabledTextColor
                        anchors.bottom: parent.bottom
                    }
                }

                ListView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    model: historyModel
                    clip: true
                    
                    Component.onCompleted: root.refreshHistory()
                    
                    delegate: PlasmaComponents.ItemDelegate {
                        text: model.title
                        width: ListView.view.width
                        onClicked: {
                            root.loadSession(model.id, model.title);
                            fullRep.historyOpen = false;
                        }
                        
                        // Delete button
                        Action {
                            icon.name: "edit-delete"
                            onTriggered: {
                                ChatStorage.deleteSession(model.id);
                                root.refreshHistory();
                                if (root.currentSessionId === model.id) {
                                    root.createNewSession();
                                }
                            }
                        }
                    } 
                }
            }
        }

        // Loading Overlay (subtle)
        BusyIndicator {
            anchors.centerIn: parent
            running: root.isLoading
            visible: root.isLoading
            z: 101
        }
    
        function sendMessage() {
            var text = inputField.text.trim();
            if (text === "") return;
            
            var apiKey = Plasmoid.configuration.apiKey;
            var modelName = Plasmoid.configuration.modelName;

            if (!apiKey) {
                chatModel.append({ role: "system", text: "Please configure your API Key in the widget settings (Right-click -> Configure Gemini Desktop)." });
                return;
            }

            // Initialize session if needed
            if (currentSessionId === -1) {
                var title = text.length > 20 ? text.substring(0, 20) + "..." : text;
                currentSessionId = ChatStorage.createSession(title);
                currentTitle = title;
                refreshHistory(); // Refresh drawer list
            }

            // Add user message
            chatModel.append({ role: "user", text: text });
            chatHistory.push({ role: "user", text: text });
            ChatStorage.saveMessage(currentSessionId, "user", text);
            
            inputField.text = "";
            root.isLoading = true;

            GeminiService.generateContent(apiKey, modelName, chatHistory, text, function(response) {
                root.isLoading = false;
                if (response.error) {
                    chatModel.append({ role: "system", text: "Error: " + response.error });
                } else {
                    chatModel.append({ role: "model", text: response.text });
                    chatHistory.push({ role: "model", text: response.text });
                    ChatStorage.saveMessage(currentSessionId, "model", response.text);
                }
            });
        }
    }
}
