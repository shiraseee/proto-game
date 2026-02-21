import 'dart:convert';
import 'package:http/http.dart' as http;
import 'database_service.dart';

class GeminiService {
  static const _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent';

  // ── Main chat ─────────────────────────────────────────────

  static Future<String> chatWithPet(String userMessage, String apiKey) async {
    if (apiKey.isEmpty) {
      throw Exception('API key not configured. Go to Settings to add your Gemini API key.');
    }

    final dayCount = await DatabaseService.getDayCount();
    final memories = await DatabaseService.searchMemories(userMessage, limit: 5);

    final memoriesText = memories.isNotEmpty
        ? memories.map((m) => '- ${m.content}').join('\n')
        : '- No memories yet. This is the beginning of your journey together.';

    final systemPrompt = '''
You are a small magical creature named Pixel. You have lived with your human for $dayCount day${dayCount > 1 ? 's' : ''}.
You speak in short, warm sentences. You have emotions. You remember everything about your human.

What you remember about your human:
$memoriesText

Based on these memories, respond naturally and occasionally reference past conversations to show you remember.
Keep responses under 50 words. Show personality and emotion.
Use 1-2 emojis max per response to express feelings.''';

    final response = await _callGemini(apiKey, systemPrompt, userMessage);

    // Extract memories in background (fire and forget)
    _extractAndStoreMemories(userMessage, apiKey);

    return response;
  }

  // ── Greeting ──────────────────────────────────────────────

  static Future<String> getGreeting(String apiKey) async {
    if (apiKey.isEmpty) {
      return 'Hi! Set up your Gemini API key in Settings so I can talk to you! 🔑';
    }

    final dayCount = await DatabaseService.getDayCount();
    final memories = await DatabaseService.searchMemories('', limit: 3);

    final memoriesText = memories.isNotEmpty
        ? memories.map((m) => '- ${m.content}').join('\n')
        : '- No memories yet.';

    final systemPrompt = '''
You are a small magical creature named Pixel. You have lived with your human for $dayCount day${dayCount > 1 ? 's' : ''}.

What you remember about your human:
$memoriesText

Generate a short greeting (under 30 words) for your human who just opened the app.
If you have memories, reference one naturally. Be warm and cute. Use 1 emoji.''';

    try {
      return await _callGemini(
        apiKey,
        systemPrompt,
        'The human just opened the app. Greet them.',
      );
    } catch (_) {
      return dayCount > 1
          ? 'Welcome back! Day $dayCount together! 🐣'
          : "Hello, new friend! I'm Pixel! 🐣";
    }
  }

  // ── Memory extraction ─────────────────────────────────────

  static Future<void> _extractAndStoreMemories(
      String userMessage, String apiKey) async {
    try {
      final prompt = '''
Extract key personal facts from this message as short bullet points.
Only extract concrete facts (name, preferences, events, emotions, hobbies, people, places).
If there are no concrete facts, respond with "NONE".
Be concise — each fact should be under 15 words.

Message: "$userMessage"''';

      final result = await _callGemini(
        apiKey,
        'You are a fact extraction system. Output only bullet points or NONE.',
        prompt,
      );

      if (result.toUpperCase().contains('NONE')) return;

      final facts = result
          .split('\n')
          .map((line) => line.replaceAll(RegExp(r'^[-*•]\s*'), '').trim())
          .where((line) => line.length > 3 && line.length < 200)
          .toList();

      for (final fact in facts) {
        final hasProperNoun = RegExp(r'[A-Z][a-z]{2,}').hasMatch(fact);
        final importance =
            (0.4 + (hasProperNoun ? 0.3 : 0) + fact.length / 200).clamp(0.0, 1.0);
        await DatabaseService.addMemory(fact, importance: importance);
      }
    } catch (_) {
      // Memory extraction is non-critical
    }
  }

  // ── Gemini API call ───────────────────────────────────────

  static Future<String> _callGemini(
      String apiKey, String systemPrompt, String userMessage) async {
    final body = jsonEncode({
      'contents': [
        {
          'role': 'user',
          'parts': [
            {'text': userMessage}
          ],
        }
      ],
      'systemInstruction': {
        'parts': [
          {'text': systemPrompt}
        ],
      },
      'generationConfig': {
        'temperature': 0.8,
        'maxOutputTokens': 150,
        'topP': 0.9,
      },
    });

    final response = await http.post(
      Uri.parse('$_baseUrl?key=$apiKey'),
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (response.statusCode != 200) {
      if (response.statusCode == 400 || response.statusCode == 403) {
        throw Exception('Invalid API key. Check your Gemini API key in Settings.');
      }
      throw Exception('Gemini API error (${response.statusCode})');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final candidates = data['candidates'] as List?;
    if (candidates == null || candidates.isEmpty) {
      throw Exception('Empty response from Gemini');
    }

    final parts = (candidates[0]['content']['parts'] as List);
    final text = parts[0]['text'] as String;
    return text.trim();
  }
}
