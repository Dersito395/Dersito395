import 'dart:convert';

class Category {
  const Category({required this.id, required this.name, required this.icon, required this.description, required this.subcategories, this.articleCount = 0});
  final String id;
  final String name;
  final String icon;
  final String description;
  final List<Subcategory> subcategories;
  final int articleCount;
}

class Subcategory {
  const Subcategory(this.id, this.name);
  final String id;
  final String name;
}

const Map<String, String> difficultyLabels = {'basica': 'Básica', 'intermediaria': 'Intermediária', 'avancada': 'Avançada'};

const Map<String, String> environmentLabels = {
  'qualquer': 'Qualquer ambiente',
  'urbano': 'Urbano',
  'domestico': 'Doméstico',
  'mata': 'Mata',
  'montanha': 'Montanha',
  'rural': 'Rural',
  'litoral': 'Litoral e água',
};

/// Dados resumidos para listas e resultados de pesquisa.
class ArticleSummary {
  const ArticleSummary({
    required this.id,
    required this.title,
    required this.summary,
    required this.categoryId,
    required this.categoryName,
    required this.difficulty,
    required this.timeEstimate,
    this.coverImage,
    this.technicalReviewPending = false,
  });
  final String id;
  final String title;
  final String summary;
  final String categoryId;
  final String categoryName;
  final String difficulty;
  final String timeEstimate;
  final String? coverImage;
  final bool technicalReviewPending;
}

class ArticleStep {
  const ArticleStep(this.text, this.image);
  final String text;
  final String? image;
}

class ArticleImage {
  const ArticleImage({required this.file, required this.caption, required this.alt, this.credit, this.license});
  final String file;
  final String caption;
  final String alt;
  final String? credit;
  final String? license;
}

class SourceRef {
  const SourceRef({
    required this.id,
    required this.institution,
    required this.author,
    required this.title,
    required this.publisher,
    required this.year,
    required this.url,
    required this.license,
    required this.language,
    this.note,
  });
  final String id;
  final String institution;
  final String author;
  final String title;
  final String publisher;
  final String year;
  final String url;
  final String license;
  final String language;
  final String? note;

  String get citation => '$author. $title. $publisher, $year. Disponível em: $url';
}

class Article {
  const Article({
    required this.id,
    required this.version,
    required this.title,
    required this.summary,
    required this.categoryId,
    required this.categoryName,
    required this.subcategoryName,
    required this.difficulty,
    required this.timeEstimate,
    required this.objective,
    required this.environments,
    required this.materials,
    required this.steps,
    required this.cautions,
    required this.alternatives,
    required this.images,
    required this.sources,
    required this.tags,
    required this.relatedIds,
    required this.technicalRequired,
    required this.technicalStatus,
    required this.updatedAt,
    required this.lang,
  });
  final String id;
  final int version;
  final String title;
  final String summary;
  final String categoryId;
  final String categoryName;
  final String? subcategoryName;
  final String difficulty;
  final String timeEstimate;
  final String objective;
  final List<String> environments;
  final List<String> materials;
  final List<ArticleStep> steps;
  final List<String> cautions;
  final List<String> alternatives;
  final List<ArticleImage> images;
  final List<SourceRef> sources;
  final List<String> tags;
  final List<String> relatedIds;
  final bool technicalRequired;
  final String technicalStatus;
  final String? updatedAt;
  final String lang;

  bool get technicalReviewPending => technicalRequired && technicalStatus != 'aprovado';

  ArticleImage? imageFor(String file) {
    for (final i in images) {
      if (i.file == file) return i;
    }
    return null;
  }

  /// Texto simples para compartilhamento e exportação.
  String toPlainText() {
    final b = StringBuffer()
      ..writeln(title.toUpperCase())
      ..writeln('$categoryName • Dificuldade: ${difficultyLabels[difficulty] ?? difficulty} • $timeEstimate')
      ..writeln()
      ..writeln('OBJETIVO')
      ..writeln(objective)
      ..writeln();
    if (materials.isNotEmpty) {
      b.writeln('MATERIAIS');
      for (final m in materials) {
        b.writeln('- $m');
      }
      b.writeln();
    }
    b.writeln('INSTRUÇÕES');
    for (var i = 0; i < steps.length; i++) {
      b.writeln('${i + 1}. ${steps[i].text}');
    }
    b
      ..writeln()
      ..writeln('CUIDADOS');
    for (final c in cautions) {
      b.writeln('! $c');
    }
    if (alternatives.isNotEmpty) {
      b
        ..writeln()
        ..writeln('ALTERNATIVAS');
      for (final a in alternatives) {
        b.writeln('- $a');
      }
    }
    b
      ..writeln()
      ..writeln('FONTES');
    for (final s in sources) {
      b.writeln('- ${s.citation}');
    }
    b
      ..writeln()
      ..writeln('SOBREVIVA | Biblioteca de Campo — conteúdo informativo. Em emergências, ligue 192 (SAMU), 193 (Bombeiros) ou 190 (Polícia).');
    return b.toString();
  }
}

/// Roteiro de ação para um cenário de crise prolongada, organizado por fases.
class Scenario {
  const Scenario({
    required this.id,
    required this.title,
    required this.icon,
    required this.summary,
    required this.phases,
    required this.relatedIds,
    required this.sourceIds,
  });
  final String id;
  final String title;
  final String icon;
  final String summary;
  final List<ScenarioPhase> phases;
  final List<String> relatedIds;
  final List<String> sourceIds;

  factory Scenario.fromJson(Map<String, dynamic> j) {
    List<String> l(dynamic v) => (v as List? ?? const []).map((e) => e.toString()).toList();
    return Scenario(
      id: j['id'] as String,
      title: j['title'] as String,
      icon: (j['icon'] as String?) ?? 'crisis',
      summary: (j['summary'] as String?) ?? '',
      phases: [for (final p in (j['phases'] as List? ?? const [])) ScenarioPhase((p as Map)['title'].toString(), l(p['items']))],
      relatedIds: l(j['related']),
      sourceIds: l(j['sources']),
    );
  }

  static Scenario decode(String data) => Scenario.fromJson(jsonDecode(data) as Map<String, dynamic>);
}

class ScenarioPhase {
  const ScenarioPhase(this.title, this.items);
  final String title;
  final List<String> items;
}

class EmergencyGuide {
  const EmergencyGuide({
    required this.id,
    required this.title,
    required this.icon,
    required this.recognize,
    required this.safety,
    required this.doList,
    required this.avoid,
    required this.callNumbers,
    required this.callWhen,
    required this.callHow,
    required this.relatedIds,
    required this.sourceIds,
  });
  final String id;
  final String title;
  final String icon;
  final List<String> recognize;
  final List<String> safety;
  final List<String> doList;
  final List<String> avoid;
  final List<String> callNumbers;
  final String callWhen;
  final List<String> callHow;
  final List<String> relatedIds;
  final List<String> sourceIds;

  factory EmergencyGuide.fromJson(Map<String, dynamic> j) {
    List<String> l(dynamic v) => (v as List? ?? const []).map((e) => e.toString()).toList();
    final call = (j['call'] as Map?)?.cast<String, dynamic>() ?? const {};
    return EmergencyGuide(
      id: j['id'] as String,
      title: j['title'] as String,
      icon: (j['icon'] as String?) ?? 'warning',
      recognize: l(j['recognize']),
      safety: l(j['safety']),
      doList: l(j['do']),
      avoid: l(j['avoid']),
      callNumbers: l(call['numbers']),
      callWhen: (call['when'] as String?) ?? '',
      callHow: l(call['how']),
      relatedIds: l(j['related']),
      sourceIds: l(j['sources']),
    );
  }

  static EmergencyGuide decode(String data) => EmergencyGuide.fromJson(jsonDecode(data) as Map<String, dynamic>);
}

class EmergencyNumber {
  const EmergencyNumber({required this.number, required this.name, required this.purpose, required this.priority, required this.sms});
  final String number;
  final String name;
  final String purpose;
  final int priority;
  final bool sms;
}

class InstalledPackage {
  const InstalledPackage({
    required this.id,
    required this.title,
    required this.description,
    required this.version,
    required this.releasedAt,
    required this.installedAt,
    required this.bundled,
    required this.articleCount,
    required this.sizeBytes,
  });
  final String id;
  final String title;
  final String description;
  final int version;
  final String? releasedAt;
  final String installedAt;
  final bool bundled;
  final int articleCount;
  final int sizeBytes;
}

class Checklist {
  const Checklist({required this.id, required this.title, required this.kind, this.articleId, required this.updatedAt, this.total = 0, this.done = 0});
  final int id;
  final String title;

  /// artigo | equipamento | mochila | personalizada
  final String kind;
  final String? articleId;
  final String updatedAt;
  final int total;
  final int done;
}

class ChecklistItem {
  const ChecklistItem({required this.id, required this.checklistId, required this.position, required this.text, required this.done, this.section});
  final int id;
  final int checklistId;
  final int position;
  final String text;
  final bool done;
  final String? section;
}

class Note {
  const Note({required this.articleId, required this.text, required this.updatedAt, this.articleTitle});
  final String articleId;
  final String text;
  final String updatedAt;
  final String? articleTitle;
}

class HistoryEntry {
  const HistoryEntry({required this.articleId, required this.viewedAt, required this.count});
  final String articleId;
  final String viewedAt;
  final int count;
}
