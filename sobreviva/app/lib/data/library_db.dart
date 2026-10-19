import 'dart:convert';

import 'package:sqlite3/sqlite3.dart';

import '../core/text_normalizer.dart';
import 'models.dart';

/// Formato de pacote suportado por esta versão do aplicativo.
const int supportedPackageFormat = 1;

class PackageFormatException implements Exception {
  PackageFormatException(this.message);
  final String message;
  @override
  String toString() => message;
}

class ImportResult {
  const ImportResult({required this.packageId, required this.version, required this.inserted, required this.updated, required this.skipped});
  final String packageId;
  final int version;
  final int inserted;
  final int updated;
  final int skipped;
}

/// Biblioteca local: conteúdo editorial + índice de pesquisa FTS5.
///
/// Fica em um arquivo separado dos dados pessoais (favoritos, notas, listas),
/// de modo que atualizações de conteúdo nunca tocam dados do usuário.
class LibraryDatabase {
  LibraryDatabase._(this.db) {
    _migrate();
  }

  factory LibraryDatabase.open(String path) => LibraryDatabase._(sqlite3.open(path));
  factory LibraryDatabase.inMemory() => LibraryDatabase._(sqlite3.openInMemory());

  final Database db;
  static const int schemaVersion = 2;

  void close() => db.close();

  void _migrate() {
    db.execute('PRAGMA foreign_keys = ON');
    db.execute('PRAGMA journal_mode = WAL');
    final current = db.userVersion;
    if (current >= schemaVersion) return;
    db.execute('BEGIN');
    try {
      if (current < 1) {
        db.execute('''
          CREATE TABLE meta (key TEXT PRIMARY KEY, value TEXT);
          CREATE TABLE category (id TEXT PRIMARY KEY, name TEXT NOT NULL, icon TEXT, description TEXT, position INTEGER);
          CREATE TABLE subcategory (category_id TEXT NOT NULL REFERENCES category(id) ON DELETE CASCADE, id TEXT NOT NULL, name TEXT NOT NULL, position INTEGER, PRIMARY KEY (category_id, id));
          CREATE TABLE article (
            id TEXT PRIMARY KEY, version INTEGER NOT NULL, lang TEXT NOT NULL, status TEXT NOT NULL,
            title TEXT NOT NULL, summary TEXT NOT NULL, category_id TEXT NOT NULL, subcategory_id TEXT,
            difficulty TEXT NOT NULL, time_estimate TEXT, objective TEXT, essential INTEGER NOT NULL DEFAULT 1,
            technical_required INTEGER NOT NULL DEFAULT 0, technical_status TEXT, reviewer TEXT, reviewed_at TEXT,
            updated_at TEXT, installed_at TEXT NOT NULL, package_id TEXT
          );
          CREATE INDEX article_category ON article(category_id);
          CREATE TABLE article_environment (article_id TEXT NOT NULL REFERENCES article(id) ON DELETE CASCADE, environment TEXT NOT NULL);
          CREATE TABLE article_step (article_id TEXT NOT NULL REFERENCES article(id) ON DELETE CASCADE, position INTEGER NOT NULL, text TEXT NOT NULL, image_file TEXT);
          CREATE TABLE article_material (article_id TEXT NOT NULL REFERENCES article(id) ON DELETE CASCADE, position INTEGER NOT NULL, text TEXT NOT NULL);
          CREATE TABLE article_caution (article_id TEXT NOT NULL REFERENCES article(id) ON DELETE CASCADE, position INTEGER NOT NULL, text TEXT NOT NULL);
          CREATE TABLE article_alternative (article_id TEXT NOT NULL REFERENCES article(id) ON DELETE CASCADE, position INTEGER NOT NULL, text TEXT NOT NULL);
          CREATE TABLE image (file TEXT PRIMARY KEY, mime TEXT, sha256 TEXT, size INTEGER, credit TEXT, license TEXT, location TEXT NOT NULL);
          CREATE TABLE article_image (article_id TEXT NOT NULL REFERENCES article(id) ON DELETE CASCADE, position INTEGER NOT NULL, file TEXT NOT NULL, caption TEXT, alt TEXT);
          CREATE TABLE source (id TEXT PRIMARY KEY, institution TEXT, author TEXT, title TEXT, publisher TEXT, year TEXT, url TEXT, license TEXT, language TEXT);
          CREATE TABLE article_source (article_id TEXT NOT NULL REFERENCES article(id) ON DELETE CASCADE, source_id TEXT NOT NULL, position INTEGER NOT NULL, note TEXT);
          CREATE TABLE tag (id INTEGER PRIMARY KEY, name TEXT NOT NULL UNIQUE);
          CREATE TABLE article_tag (article_id TEXT NOT NULL REFERENCES article(id) ON DELETE CASCADE, tag_id INTEGER NOT NULL REFERENCES tag(id), kind TEXT NOT NULL);
          CREATE TABLE article_related (article_id TEXT NOT NULL REFERENCES article(id) ON DELETE CASCADE, related_id TEXT NOT NULL, position INTEGER NOT NULL);
          CREATE TABLE content_package (id TEXT PRIMARY KEY, title TEXT, description TEXT, version INTEGER NOT NULL, released_at TEXT, installed_at TEXT NOT NULL, bundled INTEGER NOT NULL, article_count INTEGER, size_bytes INTEGER);
          CREATE TABLE package_article (package_id TEXT NOT NULL REFERENCES content_package(id) ON DELETE CASCADE, article_id TEXT NOT NULL, PRIMARY KEY (package_id, article_id));
          CREATE TABLE editorial_version (article_id TEXT NOT NULL, version INTEGER NOT NULL, status TEXT, technical_status TEXT, updated_at TEXT, installed_at TEXT NOT NULL, package_id TEXT, PRIMARY KEY (article_id, version));
          CREATE TABLE emergency_guide (id TEXT PRIMARY KEY, title TEXT NOT NULL, icon TEXT, position INTEGER, data TEXT NOT NULL);
          CREATE TABLE emergency_number (number TEXT PRIMARY KEY, name TEXT NOT NULL, purpose TEXT, priority INTEGER, sms INTEGER NOT NULL DEFAULT 0);
          CREATE TABLE synonym_term (group_id INTEGER NOT NULL, term TEXT NOT NULL);
          CREATE INDEX synonym_term_idx ON synonym_term(term);
          CREATE VIRTUAL TABLE article_fts USING fts5(article_id UNINDEXED, title, tags, summary, body, tokenize = 'unicode61 remove_diacritics 2');
          CREATE VIRTUAL TABLE article_vocab USING fts5vocab(article_fts, 'row');
        ''');
      }
      if (current < 2) {
        // v2: roteiros de cenários de crise prolongada.
        db.execute('CREATE TABLE scenario (id TEXT PRIMARY KEY, title TEXT NOT NULL, icon TEXT, position INTEGER, data TEXT NOT NULL)');
      }
      db.userVersion = schemaVersion;
      db.execute('COMMIT');
    } catch (_) {
      db.execute('ROLLBACK');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // Importação de pacotes
  // ---------------------------------------------------------------------------

  /// Importa um pacote em uma única transação. Qualquer erro desfaz tudo e
  /// mantém a biblioteca exatamente como estava.
  ImportResult importPackage(Map<String, dynamic> pkg, {required bool mediaInFiles, int sizeBytes = 0}) {
    final format = pkg['format'];
    if (format is! int || format > supportedPackageFormat) {
      throw PackageFormatException('Formato de pacote não suportado ($format). Atualize o aplicativo.');
    }
    final meta = (pkg['package'] as Map?)?.cast<String, dynamic>();
    if (meta == null || meta['id'] is! String || meta['version'] is! int) {
      throw PackageFormatException('Pacote sem identificação ou versão.');
    }
    final articles = (pkg['articles'] as List?)?.cast<Map<String, dynamic>>();
    if (articles == null) throw PackageFormatException('Pacote sem artigos.');

    final now = DateTime.now().toUtc().toIso8601String();
    final packageId = meta['id'] as String;
    final version = meta['version'] as int;
    var inserted = 0, updated = 0, skipped = 0;

    db.execute('BEGIN IMMEDIATE');
    try {
      _importCategories((pkg['categories'] as List? ?? const []).cast<Map<String, dynamic>>());
      _importSources((pkg['sources'] as List? ?? const []).cast<Map<String, dynamic>>());
      if (pkg['synonyms'] is List) _importSynonyms((pkg['synonyms'] as List).cast<List<dynamic>>());
      if (pkg['numbers'] is List) _importNumbers((pkg['numbers'] as List).cast<Map<String, dynamic>>());
      if (pkg['emergencies'] is List) _importEmergencies((pkg['emergencies'] as List).cast<Map<String, dynamic>>());
      if (pkg['scenarios'] is List) _importScenarios((pkg['scenarios'] as List).cast<Map<String, dynamic>>());
      for (final m in (pkg['media'] as List? ?? const []).cast<Map<String, dynamic>>()) {
        db.execute(
          'INSERT INTO image (file, mime, sha256, size, credit, license, location) VALUES (?,?,?,?,?,?,?) '
          'ON CONFLICT(file) DO UPDATE SET mime=excluded.mime, sha256=excluded.sha256, size=excluded.size, credit=excluded.credit, license=excluded.license, '
          "location=CASE WHEN image.location='file' THEN 'file' ELSE excluded.location END",
          [m['file'], m['mime'], m['sha256'], m['size'], m['credit'], m['license'], mediaInFiles ? 'file' : 'asset'],
        );
      }

      final ids = <String>[];
      for (final a in articles) {
        final id = a['id'];
        final v = a['version'];
        if (id is! String || v is! int || a['title'] is! String) throw PackageFormatException('Artigo inválido no pacote.');
        ids.add(id);
        final existing = db.select('SELECT version FROM article WHERE id = ?', [id]);
        if (existing.isNotEmpty && (existing.first['version'] as int) > v) {
          skipped++;
          continue;
        }
        if (existing.isNotEmpty && (existing.first['version'] as int) == v) {
          skipped++;
          continue;
        }
        _upsertArticle(a, packageId, now);
        existing.isEmpty ? inserted++ : updated++;
      }

      db.execute(
        'INSERT INTO content_package (id, title, description, version, released_at, installed_at, bundled, article_count, size_bytes) VALUES (?,?,?,?,?,?,?,?,?) '
        'ON CONFLICT(id) DO UPDATE SET title=excluded.title, description=excluded.description, version=excluded.version, released_at=excluded.released_at, '
        'installed_at=excluded.installed_at, bundled=excluded.bundled, article_count=excluded.article_count, size_bytes=excluded.size_bytes',
        [packageId, meta['title'], meta['description'], version, meta['released_at'], now, meta['bundled'] == true ? 1 : 0, articles.length, sizeBytes],
      );
      db.execute('DELETE FROM package_article WHERE package_id = ?', [packageId]);
      final stmt = db.prepare('INSERT OR IGNORE INTO package_article (package_id, article_id) VALUES (?, ?)');
      for (final id in ids) {
        stmt.execute([packageId, id]);
      }
      stmt.close();
      final lib = db.select("SELECT value FROM meta WHERE key = 'library_version'");
      final libVersion = lib.isEmpty ? 0 : int.tryParse(lib.first['value'] as String) ?? 0;
      if (version > libVersion) {
        db.execute("INSERT OR REPLACE INTO meta (key, value) VALUES ('library_version', ?)", ['$version']);
      }
      db.execute("INSERT OR REPLACE INTO meta (key, value) VALUES ('last_update', ?)", [now]);
      db.execute('COMMIT');
    } catch (e) {
      db.execute('ROLLBACK');
      rethrow;
    }
    return ImportResult(packageId: packageId, version: version, inserted: inserted, updated: updated, skipped: skipped);
  }

  void _importCategories(List<Map<String, dynamic>> cats) {
    for (var i = 0; i < cats.length; i++) {
      final c = cats[i];
      db.execute(
        'INSERT INTO category (id, name, icon, description, position) VALUES (?,?,?,?,?) '
        'ON CONFLICT(id) DO UPDATE SET name=excluded.name, icon=excluded.icon, description=excluded.description, position=excluded.position',
        [c['id'], c['name'], c['icon'], c['description'], i],
      );
      db.execute('DELETE FROM subcategory WHERE category_id = ?', [c['id']]);
      final subs = (c['subcategories'] as List? ?? const []);
      for (var j = 0; j < subs.length; j++) {
        final s = subs[j] as List;
        db.execute('INSERT INTO subcategory (category_id, id, name, position) VALUES (?,?,?,?)', [c['id'], s[0], s[1], j]);
      }
    }
  }

  void _importSources(List<Map<String, dynamic>> sources) {
    for (final s in sources) {
      db.execute('INSERT OR REPLACE INTO source (id, institution, author, title, publisher, year, url, license, language) VALUES (?,?,?,?,?,?,?,?,?)', [
        s['id'],
        s['institution'],
        s['author'],
        s['title'],
        s['publisher'],
        s['year'],
        s['url'],
        s['license'],
        s['language'],
      ]);
    }
  }

  void _importSynonyms(List<List<dynamic>> groups) {
    db.execute('DELETE FROM synonym_term');
    final stmt = db.prepare('INSERT INTO synonym_term (group_id, term) VALUES (?, ?)');
    for (var g = 0; g < groups.length; g++) {
      for (final term in groups[g]) {
        final n = normalize(term.toString());
        if (n.isNotEmpty) stmt.execute([g, n]);
      }
    }
    stmt.close();
  }

  void _importNumbers(List<Map<String, dynamic>> numbers) {
    db.execute('DELETE FROM emergency_number');
    for (final n in numbers) {
      db.execute('INSERT INTO emergency_number (number, name, purpose, priority, sms) VALUES (?,?,?,?,?)', [
        n['number'],
        n['name'],
        n['purpose'],
        n['priority'] ?? 9,
        n['sms'] == true ? 1 : 0,
      ]);
    }
  }

  void _importScenarios(List<Map<String, dynamic>> list) {
    db.execute('DELETE FROM scenario');
    for (var i = 0; i < list.length; i++) {
      final sc = list[i];
      db.execute('INSERT INTO scenario (id, title, icon, position, data) VALUES (?,?,?,?,?)', [
        sc['id'],
        sc['title'],
        sc['icon'],
        sc['order'] ?? i,
        jsonEncode(sc),
      ]);
    }
  }

  void _importEmergencies(List<Map<String, dynamic>> list) {
    db.execute('DELETE FROM emergency_guide');
    for (var i = 0; i < list.length; i++) {
      final e = list[i];
      db.execute('INSERT INTO emergency_guide (id, title, icon, position, data) VALUES (?,?,?,?,?)', [
        e['id'],
        e['title'],
        e['icon'],
        e['order'] ?? i,
        jsonEncode(e),
      ]);
    }
  }

  void _upsertArticle(Map<String, dynamic> a, String packageId, String now) {
    final id = a['id'] as String;
    final review = (a['review'] as Map?)?.cast<String, dynamic>() ?? const {};
    db.execute('DELETE FROM article WHERE id = ?', [id]); // remove filhos por cascata
    db.execute('DELETE FROM article_fts WHERE article_id = ?', [id]);
    db.execute(
      'INSERT INTO article (id, version, lang, status, title, summary, category_id, subcategory_id, difficulty, time_estimate, objective, essential, '
      'technical_required, technical_status, reviewer, reviewed_at, updated_at, installed_at, package_id) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)',
      [
        id,
        a['version'],
        a['lang'] ?? 'pt-BR',
        a['status'] ?? 'publicado',
        a['title'],
        a['summary'] ?? '',
        a['category'],
        a['subcategory'],
        a['difficulty'] ?? 'basica',
        a['time_estimate'],
        a['objective'],
        a['essential'] == false ? 0 : 1,
        review['technical_required'] == true ? 1 : 0,
        review['technical_status'],
        review['reviewer'],
        review['reviewed_at'],
        a['updated_at'],
        now,
        packageId,
      ],
    );
    List<String> strings(String key) => (a[key] as List? ?? const []).map((e) => e.toString()).toList();
    void insertList(String table, List<String> values) {
      for (var i = 0; i < values.length; i++) {
        db.execute('INSERT INTO $table (article_id, position, text) VALUES (?,?,?)', [id, i, values[i]]);
      }
    }

    for (final env in strings('environments')) {
      db.execute('INSERT INTO article_environment (article_id, environment) VALUES (?,?)', [id, env]);
    }
    final steps = (a['steps'] as List? ?? const []);
    for (var i = 0; i < steps.length; i++) {
      final s = steps[i];
      final text = s is Map ? s['text'].toString() : s.toString();
      final img = s is Map ? s['image'] as String? : null;
      db.execute('INSERT INTO article_step (article_id, position, text, image_file) VALUES (?,?,?,?)', [id, i, text, img]);
    }
    insertList('article_material', strings('materials'));
    insertList('article_caution', strings('cautions'));
    insertList('article_alternative', strings('alternatives'));
    final images = (a['images'] as List? ?? const []).cast<Map<String, dynamic>>();
    for (var i = 0; i < images.length; i++) {
      db.execute('INSERT INTO article_image (article_id, position, file, caption, alt) VALUES (?,?,?,?,?)', [
        id,
        i,
        images[i]['file'],
        images[i]['caption'],
        images[i]['alt'],
      ]);
    }
    final sources = (a['sources'] as List? ?? const []).cast<Map<String, dynamic>>();
    for (var i = 0; i < sources.length; i++) {
      db.execute('INSERT INTO article_source (article_id, source_id, position, note) VALUES (?,?,?,?)', [id, sources[i]['ref'], i, sources[i]['note']]);
    }
    void insertTags(List<String> values, String kind) {
      for (final t in values) {
        db.execute('INSERT OR IGNORE INTO tag (name) VALUES (?)', [t]);
        final tagId = db.select('SELECT id FROM tag WHERE name = ?', [t]).first['id'];
        db.execute('INSERT INTO article_tag (article_id, tag_id, kind) VALUES (?,?,?)', [id, tagId, kind]);
      }
    }

    insertTags(strings('tags'), 'tag');
    insertTags(strings('keywords'), 'keyword');
    final related = strings('related');
    for (var i = 0; i < related.length; i++) {
      db.execute('INSERT INTO article_related (article_id, related_id, position) VALUES (?,?,?)', [id, related[i], i]);
    }
    db.execute(
      'INSERT OR REPLACE INTO editorial_version (article_id, version, status, technical_status, updated_at, installed_at, package_id) VALUES (?,?,?,?,?,?,?)',
      [id, a['version'], a['status'] ?? 'publicado', review['technical_status'], a['updated_at'], now, packageId],
    );

    // Índice textual: título, etiquetas, resumo e corpo (normalizados).
    final catName = db.select('SELECT name FROM category WHERE id = ?', [a['category']]);
    final subName = db.select('SELECT name FROM subcategory WHERE category_id = ? AND id = ?', [a['category'], a['subcategory']]);
    final body = [
      a['objective'] ?? '',
      ...steps.map((s) => s is Map ? s['text'] : s),
      ...strings('materials'),
      ...strings('cautions'),
      ...strings('alternatives'),
      ...images.map((i) => i['caption'] ?? ''),
    ].join(' ');
    final tags = [
      ...strings('tags'),
      ...strings('keywords'),
      if (catName.isNotEmpty) catName.first['name'],
      if (subName.isNotEmpty) subName.first['name'],
    ].join(' ');
    db.execute('INSERT INTO article_fts (article_id, title, tags, summary, body) VALUES (?,?,?,?,?)', [
      id,
      normalize(a['title'] as String),
      normalize(tags),
      normalize(a['summary']?.toString() ?? ''),
      normalize(body),
    ]);
  }

  // ---------------------------------------------------------------------------
  // Consultas
  // ---------------------------------------------------------------------------

  int get libraryVersion {
    final r = db.select("SELECT value FROM meta WHERE key = 'library_version'");
    return r.isEmpty ? 0 : int.tryParse(r.first['value'] as String) ?? 0;
  }

  String? get lastUpdate {
    final r = db.select("SELECT value FROM meta WHERE key = 'last_update'");
    return r.isEmpty ? null : r.first['value'] as String;
  }

  int get articleCount => db.select('SELECT COUNT(*) AS n FROM article').first['n'] as int;

  List<Category> categories() {
    final rows = db.select('SELECT c.*, (SELECT COUNT(*) FROM article a WHERE a.category_id = c.id) AS n FROM category c ORDER BY position');
    return [
      for (final r in rows)
        Category(
          id: r['id'] as String,
          name: r['name'] as String,
          icon: (r['icon'] as String?) ?? 'menu_book',
          description: (r['description'] as String?) ?? '',
          articleCount: r['n'] as int,
          subcategories: [
            for (final s in db.select('SELECT id, name FROM subcategory WHERE category_id = ? ORDER BY position', [r['id']]))
              Subcategory(s['id'] as String, s['name'] as String),
          ],
        ),
    ];
  }

  static const String _summaryColumns =
      'a.id, a.title, a.summary, a.category_id, c.name AS category_name, a.difficulty, a.time_estimate, a.technical_required, a.technical_status, '
      '(SELECT file FROM article_image i WHERE i.article_id = a.id ORDER BY position LIMIT 1) AS cover';

  ArticleSummary _summaryFromRow(Row r) => ArticleSummary(
    id: r['id'] as String,
    title: r['title'] as String,
    summary: r['summary'] as String,
    categoryId: r['category_id'] as String,
    categoryName: (r['category_name'] as String?) ?? '',
    difficulty: r['difficulty'] as String,
    timeEstimate: (r['time_estimate'] as String?) ?? '',
    coverImage: r['cover'] as String?,
    technicalReviewPending: r['technical_required'] == 1 && r['technical_status'] != 'aprovado',
  );

  List<ArticleSummary> articles({String? category, String? subcategory, String? difficulty, String? environment, bool onlyWithImages = false}) {
    final where = <String>[];
    final args = <Object?>[];
    if (category != null) {
      where.add('a.category_id = ?');
      args.add(category);
    }
    if (subcategory != null) {
      where.add('a.subcategory_id = ?');
      args.add(subcategory);
    }
    if (difficulty != null) {
      where.add('a.difficulty = ?');
      args.add(difficulty);
    }
    if (environment != null) {
      where.add("EXISTS (SELECT 1 FROM article_environment e WHERE e.article_id = a.id AND (e.environment = ? OR e.environment = 'qualquer'))");
      args.add(environment);
    }
    if (onlyWithImages) where.add('EXISTS (SELECT 1 FROM article_image i WHERE i.article_id = a.id)');
    final sql =
        'SELECT $_summaryColumns FROM article a LEFT JOIN category c ON c.id = a.category_id '
        '${where.isEmpty ? '' : 'WHERE ${where.join(' AND ')}'} ORDER BY c.position, a.title';
    return db.select(sql, args).map(_summaryFromRow).toList();
  }

  /// Retorna resumos na mesma ordem dos ids informados (ids ausentes são ignorados).
  List<ArticleSummary> summaries(List<String> ids) {
    if (ids.isEmpty) return const [];
    final placeholders = List.filled(ids.length, '?').join(',');
    final rows = db.select('SELECT $_summaryColumns FROM article a LEFT JOIN category c ON c.id = a.category_id WHERE a.id IN ($placeholders)', ids);
    final byId = {for (final r in rows) r['id'] as String: _summaryFromRow(r)};
    return [for (final id in ids) ?byId[id]];
  }

  ArticleSummary? summary(String id) {
    final l = summaries([id]);
    return l.isEmpty ? null : l.first;
  }

  bool articleMatchesFilters(String id, {String? category, String? difficulty, String? environment}) {
    final r = db.select('SELECT category_id, difficulty FROM article WHERE id = ?', [id]);
    if (r.isEmpty) return false;
    if (category != null && r.first['category_id'] != category) return false;
    if (difficulty != null && r.first['difficulty'] != difficulty) return false;
    if (environment != null) {
      final e = db.select("SELECT 1 FROM article_environment WHERE article_id = ? AND (environment = ? OR environment = 'qualquer')", [id, environment]);
      if (e.isEmpty) return false;
    }
    return true;
  }

  Article? article(String id) {
    final rows = db.select(
      'SELECT a.*, c.name AS category_name, s.name AS sub_name FROM article a LEFT JOIN category c ON c.id = a.category_id '
      'LEFT JOIN subcategory s ON s.category_id = a.category_id AND s.id = a.subcategory_id WHERE a.id = ?',
      [id],
    );
    if (rows.isEmpty) return null;
    final r = rows.first;
    List<String> texts(String table) =>
        db.select('SELECT text FROM $table WHERE article_id = ? ORDER BY position', [id]).map((e) => e['text'] as String).toList();
    return Article(
      id: id,
      version: r['version'] as int,
      title: r['title'] as String,
      summary: r['summary'] as String,
      categoryId: r['category_id'] as String,
      categoryName: (r['category_name'] as String?) ?? '',
      subcategoryName: r['sub_name'] as String?,
      difficulty: r['difficulty'] as String,
      timeEstimate: (r['time_estimate'] as String?) ?? '',
      objective: (r['objective'] as String?) ?? '',
      lang: r['lang'] as String,
      environments: db.select('SELECT environment FROM article_environment WHERE article_id = ?', [id]).map((e) => e['environment'] as String).toList(),
      materials: texts('article_material'),
      cautions: texts('article_caution'),
      alternatives: texts('article_alternative'),
      steps: [
        for (final s in db.select('SELECT text, image_file FROM article_step WHERE article_id = ? ORDER BY position', [id]))
          ArticleStep(s['text'] as String, s['image_file'] as String?),
      ],
      images: [
        for (final i in db.select(
          'SELECT ai.file, ai.caption, ai.alt, im.credit, im.license FROM article_image ai LEFT JOIN image im ON im.file = ai.file WHERE ai.article_id = ? ORDER BY ai.position',
          [id],
        ))
          ArticleImage(
            file: i['file'] as String,
            caption: (i['caption'] as String?) ?? '',
            alt: (i['alt'] as String?) ?? '',
            credit: i['credit'] as String?,
            license: i['license'] as String?,
          ),
      ],
      sources: [
        for (final s in db.select('SELECT s.*, x.note FROM article_source x JOIN source s ON s.id = x.source_id WHERE x.article_id = ? ORDER BY x.position', [
          id,
        ]))
          _sourceFromRow(s),
      ],
      tags: db
          .select("SELECT t.name FROM article_tag x JOIN tag t ON t.id = x.tag_id WHERE x.article_id = ? AND x.kind = 'tag'", [id])
          .map((e) => e['name'] as String)
          .toList(),
      relatedIds: db
          .select('SELECT related_id FROM article_related WHERE article_id = ? ORDER BY position', [id])
          .map((e) => e['related_id'] as String)
          .toList(),
      technicalRequired: r['technical_required'] == 1,
      technicalStatus: (r['technical_status'] as String?) ?? 'pendente',
      updatedAt: r['updated_at'] as String?,
    );
  }

  SourceRef _sourceFromRow(Row s) => SourceRef(
    id: s['id'] as String,
    institution: (s['institution'] as String?) ?? '',
    author: (s['author'] as String?) ?? '',
    title: (s['title'] as String?) ?? '',
    publisher: (s['publisher'] as String?) ?? '',
    year: (s['year'] as String?) ?? '',
    url: (s['url'] as String?) ?? '',
    license: (s['license'] as String?) ?? '',
    language: (s['language'] as String?) ?? '',
    note: s.containsKey('note') ? s['note'] as String? : null,
  );

  List<SourceRef> allSources() => db.select('SELECT * FROM source ORDER BY institution, title').map(_sourceFromRow).toList();

  List<SourceRef> sourcesByIds(List<String> ids) {
    if (ids.isEmpty) return const [];
    final placeholders = List.filled(ids.length, '?').join(',');
    return db.select('SELECT * FROM source WHERE id IN ($placeholders)', ids).map(_sourceFromRow).toList();
  }

  List<Scenario> scenarios() => db.select('SELECT data FROM scenario ORDER BY position').map((r) => Scenario.decode(r['data'] as String)).toList();

  Scenario? scenario(String id) {
    final r = db.select('SELECT data FROM scenario WHERE id = ?', [id]);
    return r.isEmpty ? null : Scenario.decode(r.first['data'] as String);
  }

  List<EmergencyGuide> emergencies() =>
      db.select('SELECT data FROM emergency_guide ORDER BY position').map((r) => EmergencyGuide.decode(r['data'] as String)).toList();

  EmergencyGuide? emergency(String id) {
    final r = db.select('SELECT data FROM emergency_guide WHERE id = ?', [id]);
    return r.isEmpty ? null : EmergencyGuide.decode(r.first['data'] as String);
  }

  List<EmergencyNumber> numbers() => [
    for (final r in db.select('SELECT * FROM emergency_number ORDER BY priority, number'))
      EmergencyNumber(
        number: r['number'] as String,
        name: r['name'] as String,
        purpose: (r['purpose'] as String?) ?? '',
        priority: (r['priority'] as int?) ?? 9,
        sms: r['sms'] == 1,
      ),
  ];

  List<InstalledPackage> packages() => [
    for (final r in db.select('SELECT * FROM content_package ORDER BY bundled DESC, title'))
      InstalledPackage(
        id: r['id'] as String,
        title: (r['title'] as String?) ?? r['id'] as String,
        description: (r['description'] as String?) ?? '',
        version: r['version'] as int,
        releasedAt: r['released_at'] as String?,
        installedAt: r['installed_at'] as String,
        bundled: r['bundled'] == 1,
        articleCount: (r['article_count'] as int?) ?? 0,
        sizeBytes: (r['size_bytes'] as int?) ?? 0,
      ),
  ];

  /// Local de armazenamento de uma imagem: 'asset' (embarcada) ou 'file' (baixada).
  String? imageLocation(String file) {
    final r = db.select('SELECT location FROM image WHERE file = ?', [file]);
    return r.isEmpty ? null : r.first['location'] as String;
  }

  /// Grupos de sinônimos (termos normalizados).
  List<List<String>> synonymGroups() {
    final map = <int, List<String>>{};
    for (final r in db.select('SELECT group_id, term FROM synonym_term ORDER BY group_id')) {
      map.putIfAbsent(r['group_id'] as int, () => []).add(r['term'] as String);
    }
    return map.values.toList();
  }

  /// Vocabulário do índice com o número de artigos em que cada termo aparece.
  Map<String, int> vocabulary() => {for (final r in db.select('SELECT term, doc FROM article_vocab')) r['term'] as String: r['doc'] as int};

  /// Consulta FTS5 bruta: retorna (id, bm25) ordenado pela relevância.
  List<(String, double)> ftsMatch(String expression, {int limit = 100}) {
    final rows = db.select(
      'SELECT article_id, bm25(article_fts, 0.0, 10.0, 5.0, 3.0, 1.0) AS rank FROM article_fts WHERE article_fts MATCH ? ORDER BY rank LIMIT ?',
      [expression, limit],
    );
    return [for (final r in rows) (r['article_id'] as String, (r['rank'] as num).toDouble())];
  }

  /// Títulos que começam a ser digitados (autocompletar).
  List<(String, String)> titleSuggestions(String ftsExpression, {int limit = 6}) {
    final rows = db.select(
      'SELECT f.article_id, a.title FROM article_fts f JOIN article a ON a.id = f.article_id WHERE article_fts MATCH ? ORDER BY bm25(article_fts, 0.0, 10.0, 1.0, 1.0, 0.2) LIMIT ?',
      ['title : ($ftsExpression)', limit],
    );
    return [for (final r in rows) (r['article_id'] as String, r['title'] as String)];
  }

  /// Artigos com ilustrações para a seção "Guias práticos em destaque".
  List<ArticleSummary> featured({int limit = 6}) {
    final rows = db.select(
      'SELECT $_summaryColumns FROM article a LEFT JOIN category c ON c.id = a.category_id '
      'WHERE EXISTS (SELECT 1 FROM article_image i WHERE i.article_id = a.id) AND a.essential = 1 ORDER BY a.category_id, a.title',
    );
    final all = rows.map(_summaryFromRow).toList();
    // Um guia por categoria, para variedade.
    final seen = <String>{};
    final picked = <ArticleSummary>[];
    for (final s in all) {
      if (seen.add(s.categoryId)) picked.add(s);
      if (picked.length >= limit) break;
    }
    return picked;
  }
}
