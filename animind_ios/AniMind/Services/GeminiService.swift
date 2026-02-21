import Foundation

struct GeminiService {
    private static let baseURL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent"

    // MARK: - Chat

    static func chatWithPet(_ message: String, apiKey: String) async throws -> String {
        guard !apiKey.isEmpty else {
            throw GeminiError.noApiKey
        }

        let db = DatabaseService.shared
        let dayCount = db.getDayCount()
        let memories = db.searchMemories(query: message, limit: 5)
        let memoriesText = memories.isEmpty
            ? "No memories yet."
            : memories.map { "- \($0.content)" }.joined(separator: "\n")

        let systemPrompt = """
        You are a small magical creature named Pixel.
        You have lived with your human for \(dayCount) day(s).
        You speak in short, warm sentences. You have emotions.
        You remember everything about your human.

        What you remember about your human:
        \(memoriesText)

        Based on these memories, respond naturally and occasionally reference past conversations.
        Keep responses under 50 words. Show personality and emotion.
        Use 1-2 emojis max per response.
        """

        let response = try await callGemini(apiKey: apiKey, system: systemPrompt, user: message)

        // Fire-and-forget memory extraction
        Task.detached {
            try? await extractAndStoreMemories(message, apiKey: apiKey)
        }

        return response
    }

    // MARK: - Greeting

    static func getGreeting(apiKey: String) async -> String {
        let db = DatabaseService.shared
        let dayCount = db.getDayCount()

        guard !apiKey.isEmpty else {
            return "Hi! Set up your Gemini API key in Settings so I can talk to you!"
        }

        let memories = db.searchMemories(query: "greeting hello name like", limit: 3)
        let memoriesText = memories.isEmpty
            ? "No memories yet."
            : memories.map { "- \($0.content)" }.joined(separator: "\n")

        let system = """
        You are Pixel, a small magical pet creature.
        Day \(dayCount) with your human.

        What you know:
        \(memoriesText)

        Generate a short, warm greeting. If you have memories, reference one.
        Under 30 words. 1 emoji max.
        """

        do {
            return try await callGemini(apiKey: apiKey, system: system, user: "Say hello to your human!")
        } catch {
            return dayCount <= 1
                ? "Hi there! I'm Pixel! 🐣 I'm so happy to meet you!"
                : "Welcome back! Day \(dayCount) together! ✨"
        }
    }

    // MARK: - Memory Extraction

    private static func extractAndStoreMemories(_ message: String, apiKey: String) async throws {
        let system = """
        Extract key personal facts from this message. Return bullet points.
        Only extract concrete facts (names, preferences, events, feelings).
        If no personal facts, return "NONE".
        """

        let response = try await callGemini(apiKey: apiKey, system: system, user: message)

        guard response.uppercased() != "NONE" else { return }

        let facts = response
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces)
                    .replacingOccurrences(of: "^[\\-\\*•]\\s*", with: "", options: .regularExpression) }
            .filter { $0.count >= 3 && $0.count <= 200 }

        let db = DatabaseService.shared
        for fact in facts {
            var importance = 0.4
            // Boost for proper nouns
            if fact.range(of: "[A-Z][a-z]{2,}", options: .regularExpression) != nil {
                importance += 0.3
            }
            importance += min(Double(fact.count) / 200.0, 0.3)
            importance = min(max(importance, 0.0), 1.0)
            db.addMemory(content: fact, importance: importance)
        }
    }

    // MARK: - API Call

    private static func callGemini(apiKey: String, system: String, user: String) async throws -> String {
        guard let url = URL(string: "\(baseURL)?key=\(apiKey)") else {
            throw GeminiError.invalidURL
        }

        let body: [String: Any] = [
            "contents": [
                ["role": "user", "parts": [["text": user]]]
            ],
            "systemInstruction": [
                "parts": [["text": system]]
            ],
            "generationConfig": [
                "temperature": 0.8,
                "maxOutputTokens": 150,
                "topP": 0.9,
            ],
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        if let httpResponse = response as? HTTPURLResponse {
            switch httpResponse.statusCode {
            case 200: break
            case 400, 403:
                throw GeminiError.invalidApiKey
            default:
                throw GeminiError.serverError(httpResponse.statusCode)
            }
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = json["candidates"] as? [[String: Any]],
              let content = candidates.first?["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let text = parts.first?["text"] as? String else {
            throw GeminiError.parseError
        }

        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - Errors

enum GeminiError: LocalizedError {
    case noApiKey
    case invalidURL
    case invalidApiKey
    case serverError(Int)
    case parseError

    var errorDescription: String? {
        switch self {
        case .noApiKey: return "Please set your Gemini API key in Settings."
        case .invalidURL: return "Invalid API URL."
        case .invalidApiKey: return "Invalid API key. Check your key in Settings."
        case .serverError(let code): return "Server error (\(code)). Try again later."
        case .parseError: return "Couldn't understand Pixel's response."
        }
    }
}
