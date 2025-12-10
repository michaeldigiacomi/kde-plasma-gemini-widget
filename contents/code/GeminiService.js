
.pragma library

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
    // History format assumed: [{role: "user"|"model", parts: [{text: "..."}]}]
    var contents = [];

    for (var i = 0; i < chatHistory.length; i++) {
        contents.push({
            role: chatHistory[i].role,
            parts: [{ text: chatHistory[i].text }]
        });
    }

    // Add the new prompt
    contents.push({
        role: "user",
        parts: [{ text: newPrompt }]
    });

    var request = new XMLHttpRequest();
    request.open("POST", url);
    request.setRequestHeader("Content-Type", "application/json");

    request.onreadystatechange = function () {
        if (request.readyState === XMLHttpRequest.DONE) {
            if (request.status === 200) {
                try {
                    var response = JSON.parse(request.responseText);
                    var text = "";
                    if (response.candidates && response.candidates.length > 0 &&
                        response.candidates[0].content &&
                        response.candidates[0].content.parts &&
                        response.candidates[0].content.parts.length > 0) {
                        text = response.candidates[0].content.parts[0].text;
                        callback({ success: true, text: text });
                    } else {
                        callback({ error: "No content generated." });
                    }
                } catch (e) {
                    callback({ error: "Failed to parse response: " + e.message });
                }
            } else {
                callback({ error: "API Error " + request.status + ": " + request.responseText });
            }
        }
    }

    var requestBody = {
        contents: contents
    };

    request.send(JSON.stringify(requestBody));
}

function getModels(apiKey, callback) {
    if (!apiKey) {
        callback({ error: "API Key is missing." });
        return;
    }

    var url = "https://generativelanguage.googleapis.com/v1beta/models?key=" + apiKey;
    var request = new XMLHttpRequest();
    request.open("GET", url);

    request.onreadystatechange = function () {
        if (request.readyState === XMLHttpRequest.DONE) {
            if (request.status === 200) {
                try {
                    var response = JSON.parse(request.responseText);
                    var modelList = [];
                    if (response.models) {
                        for (var i = 0; i < response.models.length; i++) {
                            var m = response.models[i];
                            // Filter for generateContent supported models if possible, but for now just list them
                            // The names are like "models/gemini-pro". We usually just want the logical name or the full resource name.
                            // The previous default was "gemini-pro". The API expects just the name part often or the full resource name.
                            // Let's store the full name but display a friendly name if needed.
                            // Actually the current code creates the URL as ".../models/" + modelName. 
                            // If modelName is "gemini-pro", URL is ".../models/gemini-pro...".
                            // If API returns "models/gemini-pro", passing that would make ".../models/models/gemini-pro".
                            // So we should strip "models/" prefix.
                            var name = m.name;
                            if (name.startsWith("models/")) {
                                name = name.substring(7);
                            }
                            modelList.push(name);
                        }
                    }
                    callback({ success: true, models: modelList });
                } catch (e) {
                    callback({ error: "Failed to parse response: " + e.message });
                }
            } else {
                callback({ error: "API Error " + request.status });
            }
        }
    }
    request.send();
}
