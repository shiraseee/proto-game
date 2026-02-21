import * as SQLite from 'expo-sqlite';

let db = null;

export async function getDatabase() {
  if (!db) {
    db = await SQLite.openDatabaseAsync('animind.db');
    await initTables();
  }
  return db;
}

async function initTables() {
  await db.execAsync(`
    CREATE TABLE IF NOT EXISTS memories (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      content TEXT NOT NULL,
      timestamp TEXT NOT NULL,
      importance_score REAL DEFAULT 0.5
    );

    CREATE TABLE IF NOT EXISTS meta (
      key TEXT PRIMARY KEY,
      value TEXT NOT NULL
    );
  `);

  // Set first_launch date if not exists
  const row = await db.getFirstAsync('SELECT value FROM meta WHERE key = ?', ['first_launch']);
  if (!row) {
    await db.runAsync(
      'INSERT INTO meta (key, value) VALUES (?, ?)',
      ['first_launch', new Date().toISOString()]
    );
  }
}

// ── Memory CRUD ──────────────────────────────────────────────

export async function addMemory(content, importanceScore = 0.5) {
  const database = await getDatabase();
  const result = await database.runAsync(
    'INSERT INTO memories (content, timestamp, importance_score) VALUES (?, ?, ?)',
    [content, new Date().toISOString(), importanceScore]
  );
  return result.lastInsertRowId;
}

export async function getAllMemories() {
  const database = await getDatabase();
  return database.getAllAsync(
    'SELECT * FROM memories ORDER BY timestamp DESC'
  );
}

export async function deleteMemory(id) {
  const database = await getDatabase();
  await database.runAsync('DELETE FROM memories WHERE id = ?', [id]);
}

export async function clearAllMemories() {
  const database = await getDatabase();
  await database.runAsync('DELETE FROM memories');
}

// ── Simple keyword RAG search ────────────────────────────────

export async function searchMemories(query, limit = 5) {
  const database = await getDatabase();

  // Extract keywords (lowercase, no short words)
  const keywords = query
    .toLowerCase()
    .split(/\s+/)
    .filter((w) => w.length > 2)
    .filter((w) => !STOP_WORDS.has(w));

  if (keywords.length === 0) {
    // Fallback: return most recent + most important
    return database.getAllAsync(
      'SELECT * FROM memories ORDER BY importance_score DESC, timestamp DESC LIMIT ?',
      [limit]
    );
  }

  // Score each memory by keyword matches
  const allMemories = await database.getAllAsync('SELECT * FROM memories');

  const scored = allMemories.map((mem) => {
    const lower = mem.content.toLowerCase();
    let matchScore = 0;
    for (const kw of keywords) {
      if (lower.includes(kw)) {
        matchScore += 1;
      }
    }
    // Combine keyword match with importance
    const totalScore = matchScore * 2 + mem.importance_score;
    return { ...mem, matchScore: totalScore };
  });

  scored.sort((a, b) => b.matchScore - a.matchScore);
  return scored.slice(0, limit).filter((m) => m.matchScore > 0);
}

// ── Meta helpers ─────────────────────────────────────────────

export async function getDayCount() {
  const database = await getDatabase();
  const row = await database.getFirstAsync(
    'SELECT value FROM meta WHERE key = ?',
    ['first_launch']
  );
  if (!row) return 1;
  const first = new Date(row.value);
  const now = new Date();
  const diff = Math.floor((now - first) / (1000 * 60 * 60 * 24));
  return diff + 1;
}

export async function getLastSession() {
  const database = await getDatabase();
  const row = await database.getFirstAsync(
    'SELECT value FROM meta WHERE key = ?',
    ['last_session']
  );
  return row ? row.value : null;
}

export async function updateLastSession() {
  const database = await getDatabase();
  await database.runAsync(
    `INSERT INTO meta (key, value) VALUES ('last_session', ?)
     ON CONFLICT(key) DO UPDATE SET value = excluded.value`,
    [new Date().toISOString()]
  );
}

// ── Stop words ───────────────────────────────────────────────

const STOP_WORDS = new Set([
  'the', 'a', 'an', 'is', 'are', 'was', 'were', 'be', 'been',
  'being', 'have', 'has', 'had', 'do', 'does', 'did', 'will',
  'would', 'could', 'should', 'may', 'might', 'can', 'shall',
  'to', 'of', 'in', 'for', 'on', 'with', 'at', 'by', 'from',
  'as', 'into', 'about', 'like', 'through', 'after', 'over',
  'between', 'out', 'against', 'during', 'without', 'before',
  'under', 'around', 'among', 'and', 'but', 'or', 'nor', 'not',
  'so', 'yet', 'both', 'either', 'neither', 'each', 'every',
  'all', 'any', 'few', 'more', 'most', 'other', 'some', 'such',
  'no', 'only', 'own', 'same', 'than', 'too', 'very', 'just',
  'because', 'that', 'this', 'these', 'those', 'what', 'which',
  'who', 'whom', 'how', 'when', 'where', 'why', 'its', 'it',
  'i', 'me', 'my', 'you', 'your', 'he', 'him', 'his', 'she',
  'her', 'we', 'our', 'they', 'them', 'their',
  // French stop words
  'le', 'la', 'les', 'un', 'une', 'des', 'du', 'de', 'et',
  'est', 'en', 'que', 'qui', 'dans', 'pour', 'pas', 'sur',
  'ce', 'il', 'je', 'tu', 'nous', 'vous', 'ils', 'elles',
  'son', 'sa', 'ses', 'mon', 'ma', 'mes', 'ton', 'ta', 'tes',
  'avec', 'mais', 'donc', 'car', 'ni', 'ou', 'si', 'ne',
]);
