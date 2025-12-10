import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import "../code/GeminiService.js" as GeminiService
import "../code/OllamaService.js" as OllamaService

Kirigami.FormLayout {
    
    property alias cfg_apiKey: apiKeyField.text
    property alias cfg_modelName: modelNameField.editText
    property alias cfg_backend: backendField.currentIndex
    property alias cfg_ollamaUrl: ollamaUrlField.text
    
    // Config page title
    property string title: "General"

    // Silence QML warnings about missing default properties
    readonly property string cfg_apiKeyDefault: ""
    readonly property string cfg_modelNameDefault: "gemini-pro"
    readonly property int cfg_backendDefault: 0
    readonly property string cfg_ollamaUrlDefault: "http://localhost:11434"

    property var geminiModels: ["gemini-1.5-flash", "gemini-pro", "gemini-1.0-pro", "gemini-1.5-pro"]
    property var ollamaModels: []
    property bool isLoadingModels: false

    ComboBox {
        id: backendField
        Kirigami.FormData.label: "Backend:"
        model: ["Gemini", "Ollama"]
        
        onCurrentIndexChanged: {
            // When backend switches to Ollama (1), ensure the saved model is in the list
            if (currentIndex === 1 && ollamaModels.length === 0 && cfg_modelName) {
                ollamaModels = [cfg_modelName]
            }
        }
    }

    TextField {
        id: apiKeyField
        Kirigami.FormData.label: "API Key:"
        placeholderText: "Enter your Gemini API Key"
        echoMode: TextInput.Password
        visible: backendField.currentIndex === 0
    }

    TextField {
        id: ollamaUrlField
        Kirigami.FormData.label: "Ollama URL:"
        placeholderText: "http://localhost:11434"
        visible: backendField.currentIndex === 1
    }
    
    RowLayout {
        Kirigami.FormData.label: "Model Name:"
        
        ComboBox {
            id: modelNameField
            Layout.fillWidth: true
            editable: true // Allow custom models if the list is incomplete
            model: backendField.currentIndex === 0 ? geminiModels : ollamaModels
            
            // Allow manual entry to override connection to backend config
            onAccepted: {
                if (find(displayText) === -1) {
                    // It's a custom entry, we need to handle it or just rely on text property binding
                }
            }
        }
        
        Button {
            icon.name: isLoadingModels ? "view-refresh" : "view-refresh"
            text: isLoadingModels ? "Loading..." : "Refresh"
            enabled: !isLoadingModels
            onClicked: fetchModels()
            ToolTip.visible: hovered
            ToolTip.text: "Fetch available models from API"
        }
    }

    function fetchModels() {
        var backend = backendField.currentIndex;
        isLoadingModels = true;
        
        if (backend === 0) { // Gemini
            var key = apiKeyField.text;
            if (!key) {
                isLoadingModels = false;
                return;
            }
            GeminiService.getModels(key, handleModelsResponse);
        } else if (backend === 1) { // Ollama
            var url = ollamaUrlField.text;
            if (!url) {
                isLoadingModels = false;
                return;
            }
            OllamaService.getModels(url, handleModelsResponse);
        }
    }

    function handleModelsResponse(response) {
        isLoadingModels = false;
        
        if (response.success) {
            var current = modelNameField.editText;
            
            if (backendField.currentIndex === 0) {
                geminiModels = response.models;
            } else {
                ollamaModels = response.models;
            }

            // Restore selection if possible, or set to first item
            var idx = modelNameField.find(current);
            if (idx >= 0) {
                modelNameField.currentIndex = idx;
            } else if (response.models.length > 0) {
                modelNameField.currentIndex = 0;
            }
        } else {
            console.error("Failed to fetch models: " + response.error);
        }
    }

    // Auto-fetch if key is present on load? Maybe slightly aggressive, user can click refresh.

    Item {
        Kirigami.FormData.label: ""
        visible: backendField.currentIndex === 0
        Layout.fillWidth: true
        implicitHeight: helpLabel.implicitHeight

        Label {
            id: helpLabel
            width: parent.width
            text: "Get your API key from <a href='https://aistudio.google.com/app/apikey'>Google AI Studio</a>"
            onLinkActivated: Qt.openUrlExternally(link)
            wrapMode: Text.Wrap
        }
    }
}
