package com.animind.app.viewmodels

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.animind.app.models.ChatMessage
import com.animind.app.models.Memory
import com.animind.app.models.MessageRole
import com.animind.app.models.PetMood
import com.animind.app.services.DatabaseService
import com.animind.app.services.GeminiService
import com.animind.app.services.SecureStorage
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch

class AppViewModel(application: Application) : AndroidViewModel(application) {
    private val context get() = getApplication<Application>()

    // State
    private val _apiKey = MutableStateFlow("")
    val apiKey: StateFlow<String> = _apiKey

    private val _dayCount = MutableStateFlow(1)
    val dayCount: StateFlow<Int> = _dayCount

    private val _greeting = MutableStateFlow("")
    val greeting: StateFlow<String> = _greeting

    private val _mood = MutableStateFlow(PetMood.SLEEPY)
    val mood: StateFlow<PetMood> = _mood

    private val _messages = MutableStateFlow<List<ChatMessage>>(emptyList())
    val messages: StateFlow<List<ChatMessage>> = _messages

    private val _isLoading = MutableStateFlow(false)
    val isLoading: StateFlow<Boolean> = _isLoading

    private val _memories = MutableStateFlow<List<Memory>>(emptyList())
    val memories: StateFlow<List<Memory>> = _memories

    private var chatCount = 0
    private var greetingShown = false

    val hasApiKey: Boolean get() = _apiKey.value.isNotBlank()

    fun initialize() {
        val db = DatabaseService.shared
        _dayCount.value = db.getDayCount()
        db.updateLastSession()

        _apiKey.value = SecureStorage.loadApiKey(context)

        viewModelScope.launch {
            _greeting.value = GeminiService.getGreeting(_apiKey.value)
        }
    }

    fun setApiKey(key: String) {
        val trimmed = key.trim()
        _apiKey.value = trimmed
        if (trimmed.isEmpty()) {
            SecureStorage.clearApiKey(context)
        } else {
            SecureStorage.saveApiKey(context, trimmed)
        }
        viewModelScope.launch {
            _greeting.value = GeminiService.getGreeting(trimmed)
        }
    }

    fun showGreetingIfNeeded() {
        if (!greetingShown && _greeting.value.isNotBlank()) {
            greetingShown = true
            _messages.value = _messages.value + ChatMessage(
                text = _greeting.value,
                role = MessageRole.PET,
            )
        }
    }

    fun sendMessage(text: String) {
        val trimmed = text.trim()
        if (trimmed.isEmpty() || _isLoading.value) return

        _messages.value = _messages.value + ChatMessage(text = trimmed, role = MessageRole.USER)
        _isLoading.value = true

        viewModelScope.launch {
            try {
                val response = GeminiService.chatWithPet(trimmed, _apiKey.value)
                incrementChat()
                _messages.value = _messages.value + ChatMessage(text = response, role = MessageRole.PET)
            } catch (e: Exception) {
                val msg = e.message?.removePrefix("Exception: ") ?: "Unknown error"
                _messages.value = _messages.value + ChatMessage(text = msg, role = MessageRole.ERROR)
            }
            _isLoading.value = false
        }
    }

    fun loadMemories() {
        _memories.value = DatabaseService.shared.getAllMemories()
    }

    fun deleteMemory(id: Long) {
        DatabaseService.shared.deleteMemory(id)
        loadMemories()
    }

    fun clearAllMemories() {
        DatabaseService.shared.clearAllMemories()
        loadMemories()
    }

    private fun incrementChat() {
        chatCount++
        _mood.value = when {
            chatCount == 0 -> PetMood.SLEEPY
            chatCount < 3 -> PetMood.HAPPY
            chatCount < 7 -> PetMood.EXCITED
            else -> PetMood.CURIOUS
        }
    }
}
