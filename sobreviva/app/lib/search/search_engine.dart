import '../core/text_normalizer.dart';
import '../data/library_db.dart';
import '../data/models.dart';

class SearchFilters {
  const SearchFilters({this.category, this.difficulty, this.environment});
  final String? category;
  final String? difficulty;
  final String? environment;

  bool get isEmpty => category == null && difficulty == null && environment == null;
  int get count => [category, difficulty, environment].where((e) => e != null).length;

  SearchFilters copyWith({
    String? category,
    String? difficulty,
    String? environment,
    bool clearCategory = false,
    bool clearDifficulty = false,
    bool clearEnvironment = false,
  }) => SearchFilters(
    category: clearCategory ? null : (category ?? this.category),
    difficulty: clearDifficulty ? null : (difficulty ?? this.difficulty),
    environment: clearEnvironment ? null : (environment ?? this.environment),
  );
}

class SearchResult {
  const SearchResult(this.article, this.score, this.matchedConcepts, this.totalConcepts);
  final ArticleSummary article;
  final double score;
  final int matchedConcepts;
  final int totalConcepts;
}

class SearchOutcome {
  const SearchOutcome({required this.query, required this.results, this.correctedQuery, this.expansions = const []});
  final String query;
  final List<SearchResult> results;

  /// Consulta corrigida quando houve erro de digitação (ex.: "bussula" → "bussola").
  final String? correctedQuery;

  /// Termos equivalentes usados na expansão (exibidos ao usuário).
  final List<String> expansions;
}

enum SuggestionKind { article, history, term }

class Suggestion {
  const Suggestion(this.kind, this.text, {this.articleId});
  final SuggestionKind kind;
  final String text;
  final String? articleId;
}

/// Um conceito da consulta: um termo digitado e seus equivalentes.
class _Concept {
  _Concept(this.label, this.terms);
  final String label;
  final Set<String> terms;
}

/// Pesquisa offline: FTS5 + correção ortográfica + sinônimos + ranking por cobertura.
///
/// Não depende de rede nem de IA. Funciona assim:
///  1. normaliza a consulta (minúsculas, sem acentos) e remove palavras vazias;
///  2. detecta expressões do dicionário de sinônimos ("purificar agua");
///  3. corrige palavras desconhecidas pelo vocabulário do índice (distância de edição);
///  4. expande cada conceito com seus sinônimos;
///  5. pontua cada artigo pelo BM25 do FTS5 e pela quantidade de conceitos atendidos.
class SearchEngine {
  SearchEngine(this.library) {
    reload();
  }

  final LibraryDatabase library;
  late Map<String, int> _vocab;
  late List<List<String>> _groups;
  late Map<String, Set<int>> _termToGroups;
  late Set<String> _knownWords;

  /// Recarrega vocabulário e sinônimos (chamar após importar pacotes).
  void reload() {
    _vocab = library.vocabulary();
    _groups = library.synonymGroups();
    _termToGroups = {};
    _knownWords = {..._vocab.keys};
    for (var g = 0; g < _groups.length; g++) {
      for (final term in _groups[g]) {
        _termToGroups.putIfAbsent(term, () => {}).add(g);
        _termToGroups.putIfAbsent(lightStem(term), () => {}).add(g);
        _knownWords.addAll(term.split(' '));
      }
    }
  }

  bool _isKnown(String token) {
    if (_knownWords.contains(token) || _knownWords.contains(lightStem(token))) return true;
    if (token.length >= 3) {
      for (final w in _vocab.keys) {
        if (w.startsWith(token)) return true;
      }
    }
    return false;
  }

  /// Corrige um termo desconhecido usando o vocabulário (prefere termos frequentes).
  String? _correct(String token) {
    if (token.length < 3 || RegExp(r'^\d+$').hasMatch(token)) return null;
    final maxDist = token.length <= 4 ? 1 : 2;
    String? best;
    var bestKey = (maxDist + 1, 1, 0);
    for (final candidate in _knownWords) {
      if ((candidate.length - token.length).abs() > maxDist || candidate.length < 3) continue;
      final d = editDistance(token, candidate, max: maxDist);
      if (d > maxDist) continue;
      // Desempate: quem digita rápido costuma omitir letras, então candidatos
      // mais longos que o termo digitado vêm antes; depois, os mais frequentes.
      final key = (d, candidate.length >= token.length ? 0 : 1, -(_vocab[candidate] ?? 0));
      if (_compareKeys(key, bestKey) < 0) {
        best = candidate;
        bestKey = key;
      }
    }
    return best;
  }

  static int _compareKeys((int, int, int) a, (int, int, int) b) {
    if (a.$1 != b.$1) return a.$1.compareTo(b.$1);
    if (a.$2 != b.$2) return a.$2.compareTo(b.$2);
    return a.$3.compareTo(b.$3);
  }

  /// Analisa a consulta e devolve os conceitos, a consulta corrigida e as expansões.
  ({List<_Concept> concepts, String? corrected, List<String> expansions}) _analyze(String query) {
    final normalized = normalize(query);
    var tokens = tokenize(query, dropStopwords: true);
    if (tokens.isEmpty) tokens = tokenize(query);

    // Correção ortográfica antes de detectar expressões.
    var changed = false;
    tokens = [
      for (final t in tokens)
        if (_isKnown(t)) t else (_correct(t) ?? t),
    ];
    final originalTokens = tokenize(query, dropStopwords: true);
    if (originalTokens.isNotEmpty && originalTokens.join(' ') != tokens.join(' ')) changed = true;

    final concepts = <_Concept>[];
    final consumed = <int>{};
    final joined = ' ${tokens.join(' ')} ';
    final fullNormalized = ' $normalized ';

    // Expressões com várias palavras ("purificar agua", "golpe de calor").
    for (var g = 0; g < _groups.length; g++) {
      for (final term in _groups[g]) {
        if (!term.contains(' ')) continue;
        final content = tokenize(term, dropStopwords: true);
        if (content.isEmpty) continue;
        final hit = fullNormalized.contains(' $term ') || joined.contains(' ${content.join(' ')} ');
        if (!hit) continue;
        for (var i = 0; i < tokens.length; i++) {
          if (content.contains(tokens[i])) consumed.add(i);
        }
        concepts.add(_Concept(term, {..._groups[g]}));
        break;
      }
    }

    for (var i = 0; i < tokens.length; i++) {
      if (consumed.contains(i)) continue;
      final t = tokens[i];
      final terms = <String>{t};
      for (final key in {t, lightStem(t)}) {
        for (final g in _termToGroups[key] ?? const <int>{}) {
          terms.addAll(_groups[g]);
        }
      }
      concepts.add(_Concept(t, terms));
    }

    final expansions = <String>{for (final c in concepts) ...c.terms.where((x) => x != c.label)}.take(12).toList();
    return (concepts: concepts, corrected: changed ? tokens.join(' ') : null, expansions: expansions);
  }

  static String _quote(String s) => '"${s.replaceAll('"', '')}"';

  /// Expressão FTS5 para um conceito: termos simples com prefixo, expressões como frase.
  String _conceptExpression(_Concept c) {
    final parts = <String>{};
    for (final term in c.terms) {
      final words = tokenize(term, dropStopwords: true);
      if (words.isEmpty) continue;
      if (words.length == 1) {
        final w = words.first;
        parts.add(w.length >= 4 ? '${_quote(lightStem(w))}*' : _quote(w));
      } else {
        parts.add('(${words.map((w) => w.length >= 4 ? '${_quote(lightStem(w))}*' : _quote(w)).join(' AND ')})');
      }
    }
    return parts.isEmpty ? '' : '(${parts.join(' OR ')})';
  }

  SearchOutcome search(String query, {SearchFilters filters = const SearchFilters(), int limit = 50}) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      if (filters.isEmpty) return SearchOutcome(query: query, results: const []);
      final list = library.articles(category: filters.category, difficulty: filters.difficulty, environment: filters.environment);
      return SearchOutcome(query: query, results: [for (final a in list) SearchResult(a, 0, 0, 0)]);
    }
    final analysis = _analyze(trimmed);
    final concepts = analysis.concepts.where((c) => _conceptExpression(c).isNotEmpty).toList();
    if (concepts.isEmpty) return SearchOutcome(query: query, results: const []);

    final scores = <String, double>{};
    final coverage = <String, int>{};
    final full = concepts.map(_conceptExpression).join(' OR ');
    for (final (id, rank) in library.ftsMatch(full, limit: 200)) {
      scores[id] = -rank; // bm25: menor é melhor
    }
    for (final c in concepts) {
      for (final (id, _) in library.ftsMatch(_conceptExpression(c), limit: 200)) {
        coverage[id] = (coverage[id] ?? 0) + 1;
      }
    }

    // Bônus quando todas as palavras digitadas aparecem no título.
    final titleTokens = analysis.concepts.map((c) => lightStem(c.label)).toList();
    final ids = scores.keys
        .where((id) => library.articleMatchesFilters(id, category: filters.category, difficulty: filters.difficulty, environment: filters.environment))
        .toList();
    final summaries = {for (final s in library.summaries(ids)) s.id: s};
    final results = <SearchResult>[];
    for (final id in ids) {
      final s = summaries[id];
      if (s == null) continue;
      final cov = coverage[id] ?? 0;
      final title = normalize(s.title);
      final titleBonus = titleTokens.every((t) => title.contains(t)) ? 4.0 : 0.0;
      final score = (cov / concepts.length) * 20 + (scores[id] ?? 0) + titleBonus;
      results.add(SearchResult(s, score, cov, concepts.length));
    }
    results.sort((a, b) => b.score.compareTo(a.score));
    return SearchOutcome(query: query, results: results.take(limit).toList(), correctedQuery: analysis.corrected, expansions: analysis.expansions);
  }

  /// Sugestões enquanto o usuário digita: títulos, histórico e termos do índice.
  List<Suggestion> suggest(String input, {List<String> history = const [], int limit = 8}) {
    final n = normalize(input);
    if (n.isEmpty) return [for (final h in history.take(limit)) Suggestion(SuggestionKind.history, h)];
    final out = <Suggestion>[];
    final seen = <String>{};
    for (final h in history) {
      if (normalize(h).contains(n) && seen.add(normalize(h))) out.add(Suggestion(SuggestionKind.history, h));
      if (out.length >= 3) break;
    }
    final words = n.split(' ');
    final last = words.last;
    final head = words.sublist(0, words.length - 1);
    final contentWords = [...head.where((w) => !stopwords.contains(w)), last];
    final expr = [
      for (var i = 0; i < contentWords.length; i++)
        if (i == contentWords.length - 1) '${_quote(contentWords[i])}*' else _quote(contentWords[i]),
    ].join(' AND ');
    try {
      for (final (id, title) in library.titleSuggestions(expr)) {
        if (seen.add(normalize(title))) out.add(Suggestion(SuggestionKind.article, title, articleId: id));
      }
    } catch (_) {
      // expressão inválida para o FTS (caracteres especiais): ignora sugestões de título
    }
    if (last.length >= 2) {
      final terms = _vocab.entries.where((e) => e.key.startsWith(last) && e.key != last).toList()..sort((a, b) => b.value.compareTo(a.value));
      for (final e in terms.take(3)) {
        final text = [...head, e.key].join(' ');
        if (seen.add(text)) out.add(Suggestion(SuggestionKind.term, text));
      }
    }
    return out.take(limit).toList();
  }

  /// Artigos relacionados: os indicados pelo editor e, em seguida, os mais parecidos.
  List<ArticleSummary> related(Article article, {int limit = 5}) {
    final ids = <String>[...article.relatedIds];
    if (ids.length < limit) {
      final words = {for (final t in article.tags) ...tokenize(t, dropStopwords: true)}.where((w) => w.length >= 4).take(8).toList();
      if (words.isNotEmpty) {
        final expr = words.map((w) => '${_quote(lightStem(w))}*').join(' OR ');
        for (final (id, _) in library.ftsMatch(expr, limit: 20)) {
          if (id != article.id && !ids.contains(id)) ids.add(id);
          if (ids.length >= limit) break;
        }
      }
    }
    return library.summaries(ids.take(limit).toList());
  }
}
