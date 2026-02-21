import Foundation

// MARK: - Memory

struct Memory: Identifiable {
    let id: Int64
    let content: String
    let timestamp: Date
    let importanceScore: Double

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy HH:mm"
        return formatter.string(from: timestamp)
    }

    var importanceStars: Int {
        Int((importanceScore * 5).rounded())
    }
}

// MARK: - Chat

enum MessageRole {
    case user, pet, error
}

struct ChatMessage: Identifiable {
    let id = UUID()
    let text: String
    let role: MessageRole
    let time: Date

    init(text: String, role: MessageRole, time: Date = Date()) {
        self.text = text
        self.role = role
        self.time = time
    }
}

// MARK: - Pet Mood

enum PetMood: String {
    case happy, curious, sleepy, excited

    var emoji: String {
        switch self {
        case .happy: return "🐣"
        case .curious: return "🐥"
        case .sleepy: return "😴"
        case .excited: return "✨"
        }
    }

    var label: String {
        switch self {
        case .happy: return "Happy"
        case .curious: return "Curious"
        case .sleepy: return "Sleepy"
        case .excited: return "Excited"
        }
    }
}
