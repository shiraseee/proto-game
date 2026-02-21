package com.animind.app.services

import android.content.ContentValues
import android.content.Context
import android.database.sqlite.SQLiteDatabase
import android.database.sqlite.SQLiteOpenHelper
import com.animind.app.models.Memory
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class DatabaseService private constructor(context: Context) :
    SQLiteOpenHelper(context, "animind.db", null, 1) {

    private val isoFormat = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'", Locale.US)

    companion object {
        @Volatile
        private var instance: DatabaseService? = null

        fun initialize(context: Context) {
            if (instance == null) {
                synchronized(this) {
                    instance = DatabaseService(context.applicationContext)
                }
            }
        }

        val shared: DatabaseService
            get() = instance ?: throw IllegalStateException("DatabaseService not initialized")

        private val STOPWORDS = setOf(
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
        )
    }

    override fun onCreate(db: SQLiteDatabase) {
        db.execSQL("""
            CREATE TABLE IF NOT EXISTS memories (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                content TEXT NOT NULL,
                timestamp TEXT NOT NULL,
                importance_score REAL DEFAULT 0.5
            )
        """)
        db.execSQL("""
            CREATE TABLE IF NOT EXISTS meta (
                key TEXT PRIMARY KEY,
                value TEXT NOT NULL
            )
        """)
        // First launch
        setMeta(db, "first_launch", isoFormat.format(Date()))
    }

    override fun onUpgrade(db: SQLiteDatabase, old: Int, new: Int) {}

    // MARK: - Memory CRUD

    fun addMemory(content: String, importance: Double = 0.5) {
        val values = ContentValues().apply {
            put("content", content)
            put("timestamp", isoFormat.format(Date()))
            put("importance_score", importance)
        }
        writableDatabase.insert("memories", null, values)
    }

    fun getAllMemories(): List<Memory> {
        val cursor = readableDatabase.rawQuery(
            "SELECT id, content, timestamp, importance_score FROM memories ORDER BY timestamp DESC",
            null
        )
        val result = mutableListOf<Memory>()
        while (cursor.moveToNext()) {
            result.add(Memory(
                id = cursor.getLong(0),
                content = cursor.getString(1),
                timestamp = isoFormat.parse(cursor.getString(2)) ?: Date(),
                importanceScore = cursor.getDouble(3),
            ))
        }
        cursor.close()
        return result
    }

    fun deleteMemory(id: Long) {
        writableDatabase.delete("memories", "id = ?", arrayOf(id.toString()))
    }

    fun clearAllMemories() {
        writableDatabase.delete("memories", null, null)
    }

    // MARK: - Search (keyword-based RAG)

    fun searchMemories(query: String, limit: Int = 5): List<Memory> {
        val keywords = extractKeywords(query)
        if (keywords.isEmpty()) return emptyList()

        val all = getAllMemories()
        return all
            .map { memory ->
                val lower = memory.content.lowercase()
                val matchCount = keywords.count { lower.contains(it) }
                memory to (matchCount * 2.0 + memory.importanceScore)
            }
            .filter { it.second > 0 }
            .sortedByDescending { it.second }
            .take(limit)
            .map { it.first }
    }

    // MARK: - Meta

    fun getDayCount(): Int {
        val firstLaunch = getMeta("first_launch") ?: return 1
        val date = isoFormat.parse(firstLaunch) ?: return 1
        val days = ((Date().time - date.time) / (1000 * 60 * 60 * 24)).toInt()
        return days + 1
    }

    fun updateLastSession() {
        setMeta(writableDatabase, "last_session", isoFormat.format(Date()))
    }

    // MARK: - Private

    private fun getMeta(key: String): String? {
        val cursor = readableDatabase.rawQuery(
            "SELECT value FROM meta WHERE key = ?", arrayOf(key)
        )
        val value = if (cursor.moveToFirst()) cursor.getString(0) else null
        cursor.close()
        return value
    }

    private fun setMeta(db: SQLiteDatabase, key: String, value: String) {
        val cv = ContentValues().apply {
            put("key", key)
            put("value", value)
        }
        db.insertWithOnConflict("meta", null, cv, SQLiteDatabase.CONFLICT_REPLACE)
    }

    private fun extractKeywords(text: String): List<String> {
        return text.lowercase()
            .split(Regex("[^a-zA-Z0-9]+"))
            .filter { it.length >= 3 && it !in STOPWORDS }
    }
}
