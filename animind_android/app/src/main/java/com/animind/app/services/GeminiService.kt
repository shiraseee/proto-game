package com.animind.app.services

import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import kotlinx.coroutines.CoroutineScope
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import org.json.JSONArray
import org.json.JSONObject
import java.util.concurrent.TimeUnit

object GeminiService {
    private const val BASE_URL =
        "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent"

    private val client = OkHttpClient.Builder()
        .connectTimeout(30, TimeUnit.SECONDS)
        .readTimeout(30, TimeUnit.SECONDS)
        .build()

    // MARK: - Chat

    suspend fun chatWithPet(message: String, apiKey: String): String {
        require(apiKey.isNotBlank()) { "Please set your Gemini API key in Settings." }

        val db = DatabaseService.shared
        val dayCount = db.getDayCount()
        val memories = db.searchMemories(message, limit = 5)
        val memoriesText = if (memories.isEmpty()) "No memories yet."
        else memories.joinToString("\n") { "- ${it.content}" }

        val system = """
            You are a small magical creature named Pixel.
            You have lived with your human for $dayCount day(s).
            You speak in short, warm sentences. You have emotions.
            You remember everything about your human.

            What you remember about your human:
            $memoriesText

            Based on these memories, respond naturally and occasionally reference past conversations.
            Keep responses under 50 words. Show personality and emotion.
            Use 1-2 emojis max per response.
        """.trimIndent()

        val response = callGemini(apiKey, system, message)

        // Fire-and-forget memory extraction
        CoroutineScope(Dispatchers.IO).launch {
            runCatching { extractAndStoreMemories(message, apiKey) }
        }

        return response
    }

    // MARK: - Greeting

    suspend fun getGreeting(apiKey: String): String {
        val db = DatabaseService.shared
        val dayCount = db.getDayCount()

        if (apiKey.isBlank()) {
            return "Hi! Set up your Gemini API key in Settings so I can talk to you!"
        }

        val memories = db.searchMemories("greeting hello name like", limit = 3)
        val memoriesText = if (memories.isEmpty()) "No memories yet."
        else memories.joinToString("\n") { "- ${it.content}" }

        val system = """
            You are Pixel, a small magical pet creature.
            Day $dayCount with your human.

            What you know:
            $memoriesText

            Generate a short, warm greeting. If you have memories, reference one.
            Under 30 words. 1 emoji max.
        """.trimIndent()

        return try {
            callGemini(apiKey, system, "Say hello to your human!")
        } catch (_: Exception) {
            if (dayCount <= 1) "Hi there! I'm Pixel! 🐣 I'm so happy to meet you!"
            else "Welcome back! Day $dayCount together! ✨"
        }
    }

    // MARK: - Memory Extraction

    private suspend fun extractAndStoreMemories(message: String, apiKey: String) {
        val system = """
            Extract key personal facts from this message. Return bullet points.
            Only extract concrete facts (names, preferences, events, feelings).
            If no personal facts, return "NONE".
        """.trimIndent()

        val response = callGemini(apiKey, system, message)
        if (response.uppercase().trim() == "NONE") return

        val properNounRegex = Regex("[A-Z][a-z]{2,}")
        val db = DatabaseService.shared

        response.lines()
            .map { it.trim().removePrefix("-").removePrefix("*").removePrefix("•").trim() }
            .filter { it.length in 3..200 }
            .forEach { fact ->
                var importance = 0.4
                if (properNounRegex.containsMatchIn(fact)) importance += 0.3
                importance += (fact.length.toDouble() / 200.0).coerceAtMost(0.3)
                importance = importance.coerceIn(0.0, 1.0)
                db.addMemory(fact, importance)
            }
    }

    // MARK: - API Call

    private suspend fun callGemini(apiKey: String, system: String, user: String): String =
        withContext(Dispatchers.IO) {
            val body = JSONObject().apply {
                put("contents", JSONArray().put(JSONObject().apply {
                    put("role", "user")
                    put("parts", JSONArray().put(JSONObject().put("text", user)))
                }))
                put("systemInstruction", JSONObject().apply {
                    put("parts", JSONArray().put(JSONObject().put("text", system)))
                })
                put("generationConfig", JSONObject().apply {
                    put("temperature", 0.8)
                    put("maxOutputTokens", 150)
                    put("topP", 0.9)
                })
            }

            val request = Request.Builder()
                .url("$BASE_URL?key=$apiKey")
                .post(body.toString().toRequestBody("application/json".toMediaType()))
                .build()

            val response = client.newCall(request).execute()
            val responseBody = response.body?.string() ?: throw Exception("Empty response")

            if (!response.isSuccessful) {
                val code = response.code
                if (code == 400 || code == 403) {
                    throw Exception("Invalid API key. Check your key in Settings.")
                }
                throw Exception("Server error ($code). Try again later.")
            }

            val json = JSONObject(responseBody)
            json.getJSONArray("candidates")
                .getJSONObject(0)
                .getJSONObject("content")
                .getJSONArray("parts")
                .getJSONObject(0)
                .getString("text")
                .trim()
        }
}
