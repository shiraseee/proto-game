import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/memory.dart';

class DatabaseService {
  static Database? _db;

  static final _stopWords = <String>{
    // English
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
    'that', 'this', 'what', 'which', 'who', 'how', 'when', 'where',
    'why', 'its', 'it', 'i', 'me', 'my', 'you', 'your', 'he',
    'him', 'his', 'she', 'her', 'we', 'our', 'they', 'them', 'their',
    // French
    'le', 'la', 'les', 'un', 'une', 'des', 'du', 'de', 'et',
    'est', 'en', 'que', 'qui', 'dans', 'pour', 'pas', 'sur',
    'ce', 'il', 'je', 'tu', 'nous', 'vous', 'ils', 'elles',
    'son', 'sa', 'ses', 'mon', 'ma', 'mes', 'ton', 'ta', 'tes',
    'avec', 'mais', 'donc', 'car', 'ni', 'ou', 'si', 'ne',
  };

  // ── Init ──────────────────────────────────────────────────

  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  static Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'animind.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE memories (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            content TEXT NOT NULL,
            timestamp TEXT NOT NULL,
            importance_score REAL DEFAULT 0.5
          )
        ''');
        await db.execute('''
          CREATE TABLE meta (
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL
          )
        ''');
        // Record first launch
        await db.insert('meta', {
          'key': 'first_launch',
          'value': DateTime.now().toIso8601String(),
        });
      },
    );
  }

  // ── Memory CRUD ───────────────────────────────────────────

  static Future<int> addMemory(String content, {double importance = 0.5}) async {
    final db = await database;
    return db.insert('memories', {
      'content': content,
      'timestamp': DateTime.now().toIso8601String(),
      'importance_score': importance,
    });
  }

  static Future<List<Memory>> getAllMemories() async {
    final db = await database;
    final rows = await db.query('memories', orderBy: 'timestamp DESC');
    return rows.map((r) => Memory.fromMap(r)).toList();
  }

  static Future<void> deleteMemory(int id) async {
    final db = await database;
    await db.delete('memories', where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> clearAllMemories() async {
    final db = await database;
    await db.delete('memories');
  }

  // ── Simple keyword RAG search ─────────────────────────────

  static Future<List<Memory>> searchMemories(String query, {int limit = 5}) async {
    final db = await database;
    final allRows = await db.query('memories');
    final all = allRows.map((r) => Memory.fromMap(r)).toList();

    // Extract keywords
    final keywords = query
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((w) => w.length > 2 && !_stopWords.contains(w))
        .toList();

    if (keywords.isEmpty) {
      // Return most important/recent
      all.sort((a, b) {
        final cmp = b.importanceScore.compareTo(a.importanceScore);
        return cmp != 0 ? cmp : b.timestamp.compareTo(a.timestamp);
      });
      return all.take(limit).toList();
    }

    // Score by keyword match
    final scored = all.map((mem) {
      final lower = mem.content.toLowerCase();
      int matchCount = 0;
      for (final kw in keywords) {
        if (lower.contains(kw)) matchCount++;
      }
      final totalScore = matchCount * 2.0 + mem.importanceScore;
      return (memory: mem, score: totalScore);
    }).toList();

    scored.sort((a, b) => b.score.compareTo(a.score));

    return scored
        .where((s) => s.score > 0)
        .take(limit)
        .map((s) => s.memory)
        .toList();
  }

  // ── Meta helpers ──────────────────────────────────────────

  static Future<int> getDayCount() async {
    final db = await database;
    final rows = await db.query('meta', where: "key = 'first_launch'");
    if (rows.isEmpty) return 1;
    final first = DateTime.parse(rows.first['value'] as String);
    final now = DateTime.now();
    return now.difference(first).inDays + 1;
  }

  static Future<void> updateLastSession() async {
    final db = await database;
    await db.insert(
      'meta',
      {'key': 'last_session', 'value': DateTime.now().toIso8601String()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
