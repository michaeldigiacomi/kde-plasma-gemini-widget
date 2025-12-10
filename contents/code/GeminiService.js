.pragma library
    .import "../code/HttpClient.js" as Http

function generateContent(apiKey, modelName, chatHistory, newPrompt, callback) {
    if (!apiKey) {
        callback({ error: "API Key is missing. Please configure it in the settings." });
        return;
    }

    // Strip models/ prefix if present to avoid doubling it up
    if (modelName.startsWith("models/")) {
        modelName = modelName.substring(7);
    }
    var url = "https://generativelanguage.googleapis.com/v1beta/models/" + modelName + ":generateContent?key=" + apiKey;

    // Construct the contents array from history + new prompt
    var contents = [];
    for (var i = 0; i < chatHistory.length; i++) {
        contents.push({
            role: chatHistory[i].role,
            parts: [{ text: chatHistory[i].text }]
        });
    }
    contents.push({
        role: "user",
        parts: [{ text: newPrompt }]
    });

    var requestBody = { contents: contents };

    Http.post(url, requestBody, function (response) {
        if (response.error) {
            callback({ error: response.error });
        } else {
            var data = response.data;
            if (data.candidates && data.candidates.length > 0 &&
                data.candidates[0].content &&
                data.candidates[0].content.parts &&
                data.candidates[0].content.parts.length > 0) {
                callback({ success: true, text: data.candidates[0].content.parts[0].text });
            } else {
                callback({ error: "No content generated." });
            }
        }
    });
}

function getModels(apiKey, callback) {
    if (!apiKey) {
        callback({ error: "API Key is missing." });
        return;
    }

    var url = "https://generativelanguage.googleapis.com/v1beta/models?key=" + apiKey;

    Http.get(url, function (response) {
        if (response.error) {
            callback({ error: response.error });
        } else {
            var modelList = [];
            var models = response.data.models || [];
            for (var i = 0; i < models.length; i++) {
                var m = models[i];
                // Filter to models that support generateContent
                if (m.supportedGenerationMethods &&
                    m.supportedGenerationMethods.indexOf("generateContent") !== -1) {
                    var name = m.name;
                    if (name.startsWith("models/")) {
                        name = name.substring(7);
                    }
                    modelList.push(name);
                }
            }
            callback({ success: true, models: modelList });
        }
    });
}
