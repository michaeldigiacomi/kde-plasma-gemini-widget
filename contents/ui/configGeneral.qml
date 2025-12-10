import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import "../code/GeminiService.js" as GeminiService

Kirigami.FormLayout {
    
    property alias cfg_apiKey: apiKeyField.text
    property alias cfg_modelName: modelNameField.editText

    TextField {
        id: apiKeyField
        Kirigami.FormData.label: "API Key:"
        placeholderText: "Enter your Gemini API Key"
        echoMode: TextInput.Password
    }
    


    RowLayout {
        Kirigami.FormData.label: "Model Name:"
        
        ComboBox {
            id: modelNameField
            Layout.fillWidth: true
            editable: true // Allow custom models if the list is incomplete
            model: ["gemini-1.5-flash", "gemini-pro", "gemini-1.0-pro", "gemini-1.5-pro"] // Default fallback list
            
            // Allow manual entry to override connection to backend config
            onAccepted: {
                if (find(displayText) === -1) {
                    // It's a custom entry, we need to handle it or just rely on text property binding
                }
            }
        }
        
        Button {
            icon.name: "view-refresh"
            text: "Refresh"
            onClicked: fetchModels()
            ToolTip.visible: hovered
            ToolTip.text: "Fetch available models from API"
        }
    }

    function fetchModels() {
        var key = apiKeyField.text;
        if (!key) return;
        
        GeminiService.getModels(key, function(response) {
            if (response.success) {
                var current = modelNameField.text;
                modelNameField.model = response.models;
                // Try to restore selection or default
                var idx = response.models.indexOf(current);
                if (idx >= 0) modelNameField.currentIndex = idx;
                else if (response.models.length > 0) modelNameField.currentIndex = 0;
            } else {
                console.error("Failed to fetch models: " + response.error);
            }
        });
    }

    // Auto-fetch if key is present on load? Maybe slightly aggressive, user can click refresh.

    Label {
        text: "Get your API key from <a href='https://aistudio.google.com/app/apikey'>Google AI Studio</a>"
        onLinkActivated: Qt.openUrlExternally(link)
    }
}
