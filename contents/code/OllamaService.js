.pragma library
    .import "../code/HttpClient.js" as Http

function generateContent(baseUrl, modelName, chatHistory, newPrompt, callback) {
    if (!baseUrl) {
        callback({ error: "Ollama URL is missing. Please configure it in the settings." });
        return;
    }

    var url = baseUrl.replace(/\/$/, "") + "/api/chat";

    var messages = [];
    for (var i = 0; i < chatHistory.length; i++) {
        messages.push({
            role: chatHistory[i].role === "model" ? "assistant" : chatHistory[i].role,
            content: chatHistory[i].text
        });
    }
    messages.push({
        role: "user",
        content: newPrompt
    });

    var requestBody = {
        model: modelName,
        messages: messages,
        stream: false
    };

    Http.post(url, requestBody, function (response) {
        if (response.error) {
            callback({ error: response.error });
        } else {
            var data = response.data;
            if (data.message && data.message.content) {
                callback({ success: true, text: data.message.content });
            } else {
                callback({ error: "No content generated." });
            }
        }
    });
}

function getModels(baseUrl, callback) {
    if (!baseUrl) {
        callback({ error: "Ollama URL is missing." });
        return;
    }

    var url = baseUrl.replace(/\/$/, "") + "/api/tags";

    Http.get(url, function (response) {
        if (response.error) {
            callback({ error: response.error });
        } else {
            var modelList = [];
            var models = response.data.models || [];
            for (var i = 0; i < models.length; i++) {
                modelList.push(models[i].name);
            }
            callback({ success: true, models: modelList });
        }
    });
}
