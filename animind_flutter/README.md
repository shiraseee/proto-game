# AniMind — Virtual Pet with Persistent Memory (Flutter)

A mobile virtual pet prototype powered by AI that remembers everything you tell it across sessions.

## Screenshots

```
┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐
│  🐣 AniMind      │  │  🧠 Memories     │  │  ⚙️ Settings     │
│                  │  │                  │  │                  │
│  Day 3 together  │  │  ● Name is Alex  │  │  Gemini API Key  │
│                  │  │  ● Loves blue    │  │  [************]  │
│    🐣            │  │  ● Has a cat     │  │  [Save Key]      │
│   Happy          │  │  ● Plays guitar  │  │                  │
│   Pixel          │  │                  │  │  Status: ● OK    │
│                  │  │                  │  │  Days: 3         │
│ ┌──────────────┐ │  │                  │  │                  │
│ │ Pixel: Hi!   │ │  │                  │  │  About AniMind   │
│ │ Still loving  │ │  │                  │  │  Memories stored │
│ │ blue, Alex?  │ │  │                  │  │  locally.        │
│ ├──────────────┤ │  │                  │  │                  │
│ │ [Talk to...] │ │  │                  │  │                  │
│ └──────────────┘ │  │                  │  │                  │
│ 🏠  🧠  ⚙️      │  │ 🏠  🧠  ⚙️      │  │ 🏠  🧠  ⚙️      │
└──────────────────┘  └──────────────────┘  └──────────────────┘
```

## Features

- **Persistent memory** — Key facts extracted from every conversation, stored in local SQLite
- **Simple RAG** — Keyword search retrieves top 5 relevant memories and injects them into the prompt
- **Day counter** — Tracks how long you've had your pet, persists across sessions
- **Mood system** — Pet mood changes based on interaction frequency
- **3 screens** — Home (chat), Memories (debug/view), Settings (API key)
- **Secure storage** — API key stored via `flutter_secure_storage`
- **Cross-platform** — iOS and Android via Flutter

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Flutter (Dart) |
| Database | SQLite via `sqflite` |
| LLM | Google Gemini 1.5 Flash |
| State | Provider |
| Secrets | `flutter_secure_storage` |

## Setup

### Prerequisites

- Flutter SDK 3.6+ ([install](https://docs.flutter.dev/get-started/install))
- A Gemini API key ([get one free](https://aistudio.google.com/apikey))

### Install & Run

```bash
cd animind_flutter

# Install dependencies
flutter pub get

# Run on connected device/emulator
flutter run
```

### Configure API Key

1. Open the app
2. Go to the **Settings** tab
3. Paste your Gemini API key
4. Tap **Save Key**

## Architecture

```
lib/
├── main.dart                  # App entry, navigation, theme
├── models/
│   └── memory.dart            # Memory and ChatMessage data models
├── screens/
│   ├── home_screen.dart       # Pet display + chat interface
│   ├── memory_screen.dart     # Memory list (debug view)
│   └── settings_screen.dart   # API key configuration
└── services/
    ├── app_state.dart         # Global state (Provider ChangeNotifier)
    ├── database_service.dart  # SQLite schema, CRUD, keyword search
    └── gemini_service.dart    # Gemini API calls, RAG prompt, memory extraction
```

### How Memory Works

1. User sends a message to Pixel
2. Top 5 relevant memories are retrieved via keyword matching
3. Memories are injected into the system prompt
4. Gemini generates a personalized response
5. A second API call extracts key facts from the user's message
6. Facts are stored in SQLite with importance scores
7. On next interaction, those facts influence the response

### Database Schema

```sql
CREATE TABLE memories (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  content TEXT NOT NULL,
  timestamp TEXT NOT NULL,
  importance_score REAL DEFAULT 0.5
);

CREATE TABLE meta (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL
);
```

## Validation Scenario

> **Day 1:** Tell Pixel "My name is Alex and my favorite color is blue"
>
> **Day 2:** Reopen the app. Pixel greets you with something like:
> "Welcome back Alex! Day 2 together! Still loving blue? 💙"
