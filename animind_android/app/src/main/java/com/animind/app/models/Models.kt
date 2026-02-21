package com.animind.app.models

import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.UUID

// MARK: - Memory

data class Memory(
    val id: Long,
    val content: String,
    val timestamp: Date,
    val importanceScore: Double,
) {
    val formattedDate: String
        get() {
            val fmt = SimpleDateFormat("dd/MM/yyyy HH:mm", Locale.getDefault())
            return fmt.format(timestamp)
        }

    val importanceStars: Int
        get() = (importanceScore * 5).toInt().coerceIn(0, 5)
}

// MARK: - Chat

enum class MessageRole { USER, PET, ERROR }

data class ChatMessage(
    val id: String = UUID.randomUUID().toString(),
    val text: String,
    val role: MessageRole,
    val time: Date = Date(),
)

// MARK: - Pet Mood

enum class PetMood(val emoji: String, val label: String) {
    HAPPY("🐣", "Happy"),
    CURIOUS("🐥", "Curious"),
    SLEEPY("😴", "Sleepy"),
    EXCITED("✨", "Excited"),
}
