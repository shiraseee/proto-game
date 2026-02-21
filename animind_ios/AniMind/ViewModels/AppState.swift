import Foundation

@MainActor
final class AppState: ObservableObject {
    @Published var apiKey: String = ""
    @Published var dayCount: Int = 1
    @Published var greeting: String = ""
    @Published var mood: PetMood = .sleepy
    @Published var isReady: Bool = false

    private var chatCount = 0

    var moodEmoji: String { mood.emoji }
    var moodLabel: String { mood.label }
    var hasApiKey: Bool { !apiKey.isEmpty }

    func initialize() {
        let db = DatabaseService.shared
        db.initialize()
        dayCount = db.getDayCount()
        db.updateLastSession()

        apiKey = KeychainService.load() ?? ""
        isReady = true

        Task {
            greeting = await GeminiService.getGreeting(apiKey: apiKey)
        }
    }

    func setApiKey(_ key: String) {
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
        apiKey = trimmed
        if trimmed.isEmpty {
            KeychainService.delete()
        } else {
            KeychainService.save(key: trimmed)
        }

        // Refresh greeting
        Task {
            greeting = await GeminiService.getGreeting(apiKey: apiKey)
        }
    }

    func incrementChat() {
        chatCount += 1
        switch chatCount {
        case 0: mood = .sleepy
        case 1..<3: mood = .happy
        case 3..<7: mood = .excited
        default: mood = .curious
        }
    }
}
