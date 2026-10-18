import 'dart:convert';

import 'package:sqlite3/sqlite3.dart';

import 'models.dart';

/// Dados pessoais do usuário: favoritos, notas, histórico, listas e preferências.
///
/// Arquivo separado da biblioteca: atualizações de conteúdo nunca o modificam.
/// Nenhum destes dados sai do aparelho, exceto por exportação explícita.
class UserDatabase {
  UserDatabase._(this.db) {
    _migrate();
  }

  factory UserDatabase.open(String path) => UserDatabase._(sqlite3.open(path));
  factory UserDatabase.inMemory() => UserDatabase._(sqlite3.openInMemory());

  final Database db;
  static const int schemaVersion = 1;
  static const int exportFormat = 1;

  void close() => db.close();

  String _now() => DateTime.now().toUtc().toIso8601String();

  void _migrate() {
    db.execute('PRAGMA foreign_keys = ON');
    db.execute('PRAGMA journal_mode = WAL');
    if (db.userVersion >= schemaVersion) return;
    db.execute('BEGIN');
    try {
      db.execute('''
        CREATE TABLE IF NOT EXISTS favorite (article_id TEXT PRIMARY KEY, created_at TEXT NOT NULL);
        CREATE TABLE IF NOT EXISTS note (article_id TEXT PRIMARY KEY, text TEXT NOT NULL, updated_at TEXT NOT NULL);
        CREATE TABLE IF NOT EXISTS history (article_id TEXT PRIMARY KEY, viewed_at TEXT NOT NULL, view_count INTEGER NOT NULL DEFAULT 1);
        CREATE TABLE IF NOT EXISTS search_history (id INTEGER PRIMARY KEY, query TEXT NOT NULL UNIQUE, created_at TEXT NOT NULL);
        CREATE TABLE IF NOT EXISTS checklist (
          id INTEGER PRIMARY KEY, title TEXT NOT NULL, kind TEXT NOT NULL, article_id TEXT, params TEXT,
          created_at TEXT NOT NULL, updated_at TEXT NOT NULL
        );
        CREATE TABLE IF NOT EXISTS checklist_item (
          id INTEGER PRIMARY KEY, checklist_id INTEGER NOT NULL REFERENCES checklist(id) ON DELETE CASCADE,
          position INTEGER NOT NULL, text TEXT NOT NULL, done INTEGER NOT NULL DEFAULT 0, section TEXT
        );
        CREATE TABLE IF NOT EXISTS pref (key TEXT PRIMARY KEY, value TEXT NOT NULL);
      ''');
      db.userVersion = schemaVersion;
      db.execute('COMMIT');
    } catch (_) {
      db.execute('ROLLBACK');
      rethrow;
    }
  }

  // Preferências ---------------------------------------------------------------

  String? pref(String key) {
    final r = db.select('SELECT value FROM pref WHERE key = ?', [key]);
    return r.isEmpty ? null : r.first['value'] as String;
  }

  void setPref(String key, String? value) {
    if (value == null) {
      db.execute('DELETE FROM pref WHERE key = ?', [key]);
    } else {
      db.execute('INSERT OR REPLACE INTO pref (key, value) VALUES (?, ?)', [key, value]);
    }
  }

  // Favoritos -----------------------------------------------------------------

  bool isFavorite(String id) => db.select('SELECT 1 FROM favorite WHERE article_id = ?', [id]).isNotEmpty;

  void setFavorite(String id, bool value) {
    if (value) {
      db.execute('INSERT OR IGNORE INTO favorite (article_id, created_at) VALUES (?, ?)', [id, _now()]);
    } else {
      db.execute('DELETE FROM favorite WHERE article_id = ?', [id]);
    }
  }

  List<String> favoriteIds() => db.select('SELECT article_id FROM favorite ORDER BY created_at DESC').map((r) => r['article_id'] as String).toList();

  // Notas ---------------------------------------------------------------------

  String? note(String articleId) {
    final r = db.select('SELECT text FROM note WHERE article_id = ?', [articleId]);
    return r.isEmpty ? null : r.first['text'] as String;
  }

  void saveNote(String articleId, String text) {
    if (text.trim().isEmpty) {
      db.execute('DELETE FROM note WHERE article_id = ?', [articleId]);
    } else {
      db.execute('INSERT OR REPLACE INTO note (article_id, text, updated_at) VALUES (?, ?, ?)', [articleId, text, _now()]);
    }
  }

  List<Note> notes() => [
    for (final r in db.select('SELECT * FROM note ORDER BY updated_at DESC'))
      Note(articleId: r['article_id'] as String, text: r['text'] as String, updatedAt: r['updated_at'] as String),
  ];

  // Histórico de leitura --------------------------------------------------------

  void recordView(String articleId) {
    db.execute(
      'INSERT INTO history (article_id, viewed_at, view_count) VALUES (?, ?, 1) '
      'ON CONFLICT(article_id) DO UPDATE SET viewed_at = excluded.viewed_at, view_count = history.view_count + 1',
      [articleId, _now()],
    );
  }

  List<HistoryEntry> history({int limit = 100}) => [
    for (final r in db.select('SELECT * FROM history ORDER BY viewed_at DESC LIMIT ?', [limit]))
      HistoryEntry(articleId: r['article_id'] as String, viewedAt: r['viewed_at'] as String, count: r['view_count'] as int),
  ];

  void clearHistory() => db.execute('DELETE FROM history');

  // Histórico de pesquisa ----------------------------------------------------------

  void addSearch(String query) {
    final q = query.trim();
    if (q.length < 2) return;
    db.execute('INSERT INTO search_history (query, created_at) VALUES (?, ?) ON CONFLICT(query) DO UPDATE SET created_at = excluded.created_at', [q, _now()]);
    db.execute('DELETE FROM search_history WHERE id NOT IN (SELECT id FROM search_history ORDER BY created_at DESC LIMIT 50)');
  }

  List<String> searchHistory({String prefix = '', int limit = 20}) => db
      .select('SELECT query FROM search_history WHERE query LIKE ? ESCAPE ? ORDER BY created_at DESC LIMIT ?', [
        '%${prefix.replaceAll('\\', '\\\\').replaceAll('%', '\\%').replaceAll('_', '\\_')}%',
        '\\',
        limit,
      ])
      .map((r) => r['query'] as String)
      .toList();

  void removeSearch(String query) => db.execute('DELETE FROM search_history WHERE query = ?', [query]);
  void clearSearchHistory() => db.execute('DELETE FROM search_history');

  // Checklists ------------------------------------------------------------------

  int createChecklist(String title, String kind, List<(String text, String? section)> items, {String? articleId, Map<String, Object?>? params}) {
    // SAVEPOINT permite chamar este método dentro de outra transação (importação).
    db.execute('SAVEPOINT create_checklist');
    try {
      final now = _now();
      db.execute('INSERT INTO checklist (title, kind, article_id, params, created_at, updated_at) VALUES (?,?,?,?,?,?)', [
        title,
        kind,
        articleId,
        params == null ? null : jsonEncode(params),
        now,
        now,
      ]);
      final id = db.lastInsertRowId;
      for (var i = 0; i < items.length; i++) {
        db.execute('INSERT INTO checklist_item (checklist_id, position, text, section) VALUES (?,?,?,?)', [id, i, items[i].$1, items[i].$2]);
      }
      db.execute('RELEASE create_checklist');
      return id;
    } catch (_) {
      db.execute('ROLLBACK TO create_checklist');
      db.execute('RELEASE create_checklist');
      rethrow;
    }
  }

  List<Checklist> checklists() => [
    for (final r in db.select(
      'SELECT c.*, (SELECT COUNT(*) FROM checklist_item i WHERE i.checklist_id = c.id) AS total, '
      '(SELECT COUNT(*) FROM checklist_item i WHERE i.checklist_id = c.id AND i.done = 1) AS done FROM checklist c ORDER BY c.updated_at DESC',
    ))
      Checklist(
        id: r['id'] as int,
        title: r['title'] as String,
        kind: r['kind'] as String,
        articleId: r['article_id'] as String?,
        updatedAt: r['updated_at'] as String,
        total: r['total'] as int,
        done: r['done'] as int,
      ),
  ];

  Checklist? checklist(int id) {
    for (final c in checklists()) {
      if (c.id == id) return c;
    }
    return null;
  }

  int? checklistForArticle(String articleId) {
    final r = db.select("SELECT id FROM checklist WHERE article_id = ? AND kind = 'artigo' ORDER BY id LIMIT 1", [articleId]);
    return r.isEmpty ? null : r.first['id'] as int;
  }

  List<ChecklistItem> items(int checklistId) => [
    for (final r in db.select('SELECT * FROM checklist_item WHERE checklist_id = ? ORDER BY position, id', [checklistId]))
      ChecklistItem(
        id: r['id'] as int,
        checklistId: checklistId,
        position: r['position'] as int,
        text: r['text'] as String,
        done: r['done'] == 1,
        section: r['section'] as String?,
      ),
  ];

  void _touch(int checklistId) => db.execute('UPDATE checklist SET updated_at = ? WHERE id = ?', [_now(), checklistId]);

  void setItemDone(int itemId, bool done) {
    db.execute('UPDATE checklist_item SET done = ? WHERE id = ?', [done ? 1 : 0, itemId]);
    final r = db.select('SELECT checklist_id FROM checklist_item WHERE id = ?', [itemId]);
    if (r.isNotEmpty) _touch(r.first['checklist_id'] as int);
  }

  void addItem(int checklistId, String text, {String? section}) {
    final pos = db.select('SELECT COALESCE(MAX(position), -1) + 1 AS p FROM checklist_item WHERE checklist_id = ?', [checklistId]).first['p'];
    db.execute('INSERT INTO checklist_item (checklist_id, position, text, section) VALUES (?,?,?,?)', [checklistId, pos, text, section]);
    _touch(checklistId);
  }

  void updateItemText(int itemId, String text) => db.execute('UPDATE checklist_item SET text = ? WHERE id = ?', [text, itemId]);

  void deleteItem(int itemId) => db.execute('DELETE FROM checklist_item WHERE id = ?', [itemId]);

  void resetChecklist(int checklistId) {
    db.execute('UPDATE checklist_item SET done = 0 WHERE checklist_id = ?', [checklistId]);
    _touch(checklistId);
  }

  void renameChecklist(int id, String title) {
    db.execute('UPDATE checklist SET title = ? WHERE id = ?', [title, id]);
    _touch(id);
  }

  void deleteChecklist(int id) => db.execute('DELETE FROM checklist WHERE id = ?', [id]);

  // Exportação e importação ---------------------------------------------------------

  /// Exporta anotações, favoritos e listas em JSON (formato documentado em docs/).
  Map<String, Object?> exportData() => {
    'app': 'sobreviva',
    'format': exportFormat,
    'exported_at': _now(),
    'favorites': favoriteIds(),
    'notes': [
      for (final n in notes()) {'article_id': n.articleId, 'text': n.text, 'updated_at': n.updatedAt},
    ],
    'checklists': [
      for (final c in checklists())
        {
          'title': c.title,
          'kind': c.kind,
          'article_id': c.articleId,
          'items': [
            for (final i in items(c.id)) {'text': i.text, 'done': i.done, 'section': i.section},
          ],
        },
    ],
  };

  /// Importa dados exportados, mesclando sem apagar o que já existe.
  /// Retorna um resumo do que foi importado.
  ({int notes, int favorites, int checklists}) importData(Map<String, dynamic> data) {
    if (data['app'] != 'sobreviva' || data['format'] is! int || (data['format'] as int) > exportFormat) {
      throw const FormatException('Arquivo não reconhecido como exportação do SOBREVIVA.');
    }
    var n = 0, f = 0, c = 0;
    db.execute('BEGIN');
    try {
      for (final id in (data['favorites'] as List? ?? const [])) {
        if (id is String && !isFavorite(id)) {
          setFavorite(id, true);
          f++;
        }
      }
      for (final raw in (data['notes'] as List? ?? const [])) {
        final m = (raw as Map).cast<String, dynamic>();
        final id = m['article_id'], text = m['text'];
        if (id is! String || text is! String) continue;
        final existing = note(id);
        if (existing == null) {
          saveNote(id, text);
        } else if (!existing.contains(text)) {
          saveNote(id, '$existing\n\n— Importado —\n$text');
        } else {
          continue;
        }
        n++;
      }
      for (final raw in (data['checklists'] as List? ?? const [])) {
        final m = (raw as Map).cast<String, dynamic>();
        final title = m['title'];
        if (title is! String) continue;
        final items = [
          for (final i in (m['items'] as List? ?? const []))
            if (i is Map && i['text'] is String) (i['text'] as String, i['section'] as String?),
        ];
        final id = createChecklist(title, (m['kind'] as String?) ?? 'personalizada', items, articleId: m['article_id'] as String?);
        final done = [
          for (final i in (m['items'] as List? ?? const []))
            if (i is Map && i['text'] is String) i['done'] == true,
        ];
        final created = this.items(id);
        for (var k = 0; k < created.length && k < done.length; k++) {
          if (done[k]) db.execute('UPDATE checklist_item SET done = 1 WHERE id = ?', [created[k].id]);
        }
        c++;
      }
      db.execute('COMMIT');
    } catch (_) {
      db.execute('ROLLBACK');
      rethrow;
    }
    return (notes: n, favorites: f, checklists: c);
  }
}
