# AniMind — Virtual Pet with Persistent Memory

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
│ │ blue, Alex?  │ │  │                  │  │  locally on your │
│ ├──────────────┤ │  │                  │  │  device.         │
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
- **Secure storage** — API key stored via `expo-secure-store`
- **Cross-platform** — iOS, Android, and Web via Expo

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | React Native (Expo SDK 54) |
| Database | SQLite via `expo-sqlite` |
| LLM | Google Gemini 1.5 Flash |
| Navigation | React Navigation (bottom tabs) |
| Secrets | `expo-secure-store` |

## Setup

### Prerequisites

- Node.js 18+
- Expo CLI (`npx expo`)
- A Gemini API key ([get one free](https://aistudio.google.com/apikey))

### Install & Run

```bash
# Clone and navigate
cd animind

# Install dependencies
npm install

# Start the dev server
npx expo start
```

Then:
- Press `i` for iOS simulator
- Press `a` for Android emulator
- Press `w` for web browser
- Scan QR code with **Expo Go** app on your phone

### Configure API Key

1. Open the app
2. Go to the **Settings** tab
3. Paste your Gemini API key
4. Tap **Save Key**

Alternatively, copy `.env.example` to `.env` and set your key there (for local dev reference only — the app reads the key from secure storage, not env vars).

## Architecture

```
src/
├── api/
│   └── gemini.js          # Gemini API calls, RAG prompt assembly, memory extraction
├── context/
│   └── AppContext.js       # Global state (API key, day count, mood)
├── db/
│   └── database.js         # SQLite schema, CRUD, keyword search
└── screens/
    ├── HomeScreen.js        # Pet display + chat interface
    ├── MemoryScreen.js      # Memory list (debug view)
    └── SettingsScreen.js    # API key configuration
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
-- Stored facts about the user
CREATE TABLE memories (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  content TEXT NOT NULL,
  timestamp TEXT NOT NULL,
  importance_score REAL DEFAULT 0.5
);

-- App metadata (first launch date, last session, etc.)
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

That's the moment you know it works.
