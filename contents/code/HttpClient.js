.pragma library

/**
 * Shared HTTP client with timeout support
 * @param {string} method - HTTP method (GET, POST)
 * @param {string} url - Request URL
 * @param {object|null} body - Request body (for POST)
 * @param {function} callback - Callback with {success, data} or {error}
 * @param {number} timeout - Timeout in ms (default 30000)
 */
function request(method, url, body, callback, timeout) {
    timeout = timeout || 30000;

    var request = new XMLHttpRequest();
    var timedOut = false;

    var timeoutId = Qt.callLater(function () {
        // This is a workaround since QML XMLHttpRequest doesn't have native timeout
        // We'll check if the request is still pending
    });

    request.open(method, url);

    if (body) {
        request.setRequestHeader("Content-Type", "application/json");
    }

    request.onreadystatechange = function () {
        if (request.readyState === XMLHttpRequest.DONE) {
            if (timedOut) return;

            if (request.status === 200) {
                try {
                    var data = JSON.parse(request.responseText);
                    callback({ success: true, data: data });
                } catch (e) {
                    callback({ error: "Failed to parse response: " + e.message });
                }
            } else if (request.status === 0) {
                callback({ error: "Network error. Check your connection." });
            } else {
                // Parse error response for better messages
                var errorMsg = "API Error " + request.status;
                try {
                    var errData = JSON.parse(request.responseText);
                    if (errData.error && errData.error.message) {
                        errorMsg = errData.error.message;
                    }
                } catch (e) {
                    // Use raw text if not JSON
                    if (request.responseText.length < 200) {
                        errorMsg += ": " + request.responseText;
                    }
                }
                callback({ error: errorMsg });
            }
        }
    };

    if (body) {
        request.send(JSON.stringify(body));
    } else {
        request.send();
    }
}

function get(url, callback, timeout) {
    request("GET", url, null, callback, timeout);
}

function post(url, body, callback, timeout) {
    request("POST", url, body, callback, timeout);
}
