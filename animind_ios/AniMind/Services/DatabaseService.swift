import Foundation
import SQLite3

final class DatabaseService {
    static let shared = DatabaseService()
    private var db: OpaquePointer?

    private static let stopwords: Set<String> = [
        "the", "a", "an", "is", "are", "was", "were", "be", "been", "being",
        "have", "has", "had", "do", "does", "did", "will", "would", "could",
        "should", "may", "might", "can", "shall", "to", "of", "in", "for",
        "on", "with", "at", "by", "from", "as", "into", "about", "like",
        "through", "after", "over", "between", "out", "against", "during",
        "without", "before", "under", "around", "among", "that", "this",
        "it", "its", "i", "my", "me", "we", "our", "you", "your", "he",
        "she", "they", "them", "and", "but", "or", "not", "no", "so",
        "if", "then", "than", "too", "very", "just", "de", "le", "la",
        "les", "un", "une", "du", "des", "et", "est", "je", "tu", "il",
    ]

    private init() {}

    // MARK: - Init

    func initialize() {
        let fileManager = FileManager.default
        let docsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let dbPath = docsURL.appendingPathComponent("animind.db").path

        guard sqlite3_open(dbPath, &db) == SQLITE_OK else {
            print("Failed to open database")
            return
        }

        execute("""
            CREATE TABLE IF NOT EXISTS memories (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                content TEXT NOT NULL,
                timestamp TEXT NOT NULL,
                importance_score REAL DEFAULT 0.5
            )
        """)

        execute("""
            CREATE TABLE IF NOT EXISTS meta (
                key TEXT PRIMARY KEY,
                value TEXT NOT NULL
            )
        """)

        // Set first_launch if not exists
        if getMeta(key: "first_launch") == nil {
            setMeta(key: "first_launch", value: ISO8601DateFormatter().string(from: Date()))
        }
    }

    // MARK: - Memory CRUD

    func addMemory(content: String, importance: Double = 0.5) {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let sql = "INSERT INTO memories (content, timestamp, importance_score) VALUES (?, ?, ?)"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return }
        sqlite3_bind_text(stmt, 1, (content as NSString).utf8String, -1, nil)
        sqlite3_bind_text(stmt, 2, (timestamp as NSString).utf8String, -1, nil)
        sqlite3_bind_double(stmt, 3, importance)
        sqlite3_step(stmt)
        sqlite3_finalize(stmt)
    }

    func getAllMemories() -> [Memory] {
        let sql = "SELECT id, content, timestamp, importance_score FROM memories ORDER BY timestamp DESC"
        var stmt: OpaquePointer?
        var memories: [Memory] = []

        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return [] }

        let formatter = ISO8601DateFormatter()
        while sqlite3_step(stmt) == SQLITE_ROW {
            let id = sqlite3_column_int64(stmt, 0)
            let content = String(cString: sqlite3_column_text(stmt, 1))
            let ts = String(cString: sqlite3_column_text(stmt, 2))
            let score = sqlite3_column_double(stmt, 3)
            let date = formatter.date(from: ts) ?? Date()
            memories.append(Memory(id: id, content: content, timestamp: date, importanceScore: score))
        }
        sqlite3_finalize(stmt)
        return memories
    }

    func deleteMemory(id: Int64) {
        let sql = "DELETE FROM memories WHERE id = ?"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return }
        sqlite3_bind_int64(stmt, 1, id)
        sqlite3_step(stmt)
        sqlite3_finalize(stmt)
    }

    func clearAllMemories() {
        execute("DELETE FROM memories")
    }

    // MARK: - Search (keyword-based RAG)

    func searchMemories(query: String, limit: Int = 5) -> [Memory] {
        let keywords = extractKeywords(from: query)
        guard !keywords.isEmpty else { return [] }

        let allMemories = getAllMemories()
        var scored: [(Memory, Double)] = []

        for memory in allMemories {
            let lower = memory.content.lowercased()
            var matchCount = 0
            for keyword in keywords {
                if lower.contains(keyword) { matchCount += 1 }
            }
            let score = Double(matchCount) * 2.0 + memory.importanceScore
            if score > 0 {
                scored.append((memory, score))
            }
        }

        scored.sort { $0.1 > $1.1 }
        return Array(scored.prefix(limit).map { $0.0 })
    }

    // MARK: - Meta

    func getDayCount() -> Int {
        guard let firstLaunchStr = getMeta(key: "first_launch"),
              let firstLaunch = ISO8601DateFormatter().date(from: firstLaunchStr) else {
            return 1
        }
        let days = Calendar.current.dateComponents([.day], from: firstLaunch, to: Date()).day ?? 0
        return days + 1
    }

    func updateLastSession() {
        setMeta(key: "last_session", value: ISO8601DateFormatter().string(from: Date()))
    }

    // MARK: - Private Helpers

    private func execute(_ sql: String) {
        sqlite3_exec(db, sql, nil, nil, nil)
    }

    private func getMeta(key: String) -> String? {
        let sql = "SELECT value FROM meta WHERE key = ?"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return nil }
        sqlite3_bind_text(stmt, 1, (key as NSString).utf8String, -1, nil)

        var value: String?
        if sqlite3_step(stmt) == SQLITE_ROW {
            value = String(cString: sqlite3_column_text(stmt, 1))
        }
        sqlite3_finalize(stmt)
        return value
    }

    private func setMeta(key: String, value: String) {
        let sql = "INSERT OR REPLACE INTO meta (key, value) VALUES (?, ?)"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return }
        sqlite3_bind_text(stmt, 1, (key as NSString).utf8String, -1, nil)
        sqlite3_bind_text(stmt, 2, (value as NSString).utf8String, -1, nil)
        sqlite3_step(stmt)
        sqlite3_finalize(stmt)
    }

    private func extractKeywords(from text: String) -> [String] {
        text.lowercased()
            .components(separatedBy: .alphanumerics.inverted)
            .filter { $0.count >= 3 && !Self.stopwords.contains($0) }
    }
}
