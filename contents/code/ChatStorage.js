.pragma library
    .import QtQuick.LocalStorage 2.0 as Sql

// Initialize the database
function getDB() {
    var db = Sql.LocalStorage.openDatabaseSync("GeminiWidgetDB", "1.0", "Chat History", 1000000);
    db.transaction(function (tx) {
        tx.executeSql('CREATE TABLE IF NOT EXISTS Sessions(id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT, lastModified INTEGER)');
        tx.executeSql('CREATE TABLE IF NOT EXISTS Messages(id INTEGER PRIMARY KEY AUTOINCREMENT, sessionId INTEGER, role TEXT, text TEXT, timestamp INTEGER, FOREIGN KEY(sessionId) REFERENCES Sessions(id))');
    });
    return db;
}

// Create a new session and return its ID
function createSession(title) {
    var db = getDB();
    var id = -1;
    db.transaction(function (tx) {
        var res = tx.executeSql('INSERT INTO Sessions(title, lastModified) VALUES(?, ?)', [title, Date.now()]);
        id = res.insertId;
    });
    return id;
}

// Get all sessions ordered by last modified desc
function getSessions() {
    var db = getDB();
    var sessions = [];
    db.transaction(function (tx) {
        var rs = tx.executeSql('SELECT * FROM Sessions ORDER BY lastModified DESC');
        for (var i = 0; i < rs.rows.length; i++) {
            sessions.push(rs.rows.item(i));
        }
    });
    return sessions;
}

// Save a message to a session
function saveMessage(sessionId, role, text) {
    var db = getDB();
    db.transaction(function (tx) {
        tx.executeSql('INSERT INTO Messages(sessionId, role, text, timestamp) VALUES(?, ?, ?, ?)', [sessionId, role, text, Date.now()]);
        tx.executeSql('UPDATE Sessions SET lastModified = ? WHERE id = ?', [Date.now(), sessionId]);
    });
}

// Get all messages for a session
function getMessages(sessionId) {
    var db = getDB();
    var messages = [];
    db.transaction(function (tx) {
        var rs = tx.executeSql('SELECT * FROM Messages WHERE sessionId = ? ORDER BY id ASC', [sessionId]);
        for (var i = 0; i < rs.rows.length; i++) {
            messages.push(rs.rows.item(i));
        }
    });
    return messages;
}

// Update session title
function updateTitle(sessionId, title) {
    var db = getDB();
    db.transaction(function (tx) {
        tx.executeSql('UPDATE Sessions SET title = ? WHERE id = ?', [title, sessionId]);
    });
}

// Delete a session
function deleteSession(sessionId) {
    var db = getDB();
    db.transaction(function (tx) {
        tx.executeSql('DELETE FROM Messages WHERE sessionId = ?', [sessionId]);
        tx.executeSql('DELETE FROM Sessions WHERE id = ?', [sessionId]);
    });
}
