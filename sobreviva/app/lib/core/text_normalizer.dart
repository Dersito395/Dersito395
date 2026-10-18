/// Normalização de texto em português para indexação e pesquisa offline.
library;

const Map<String, String> _accents = {
  'á': 'a',
  'à': 'a',
  'â': 'a',
  'ã': 'a',
  'ä': 'a',
  'é': 'e',
  'è': 'e',
  'ê': 'e',
  'ë': 'e',
  'í': 'i',
  'ì': 'i',
  'î': 'i',
  'ï': 'i',
  'ó': 'o',
  'ò': 'o',
  'ô': 'o',
  'õ': 'o',
  'ö': 'o',
  'ú': 'u',
  'ù': 'u',
  'û': 'u',
  'ü': 'u',
  'ç': 'c',
  'ñ': 'n',
};

final RegExp _nonWord = RegExp(r'[^a-z0-9]+');

/// Palavras muito comuns que não ajudam a encontrar artigos.
/// "sem", "nao" e "ajuda" foram mantidas fora da lista de propósito quando têm valor de busca.
const Set<String> stopwords = {
  'a',
  'o',
  'as',
  'os',
  'um',
  'uma',
  'uns',
  'umas',
  'de',
  'da',
  'do',
  'das',
  'dos',
  'em',
  'no',
  'na',
  'nos',
  'nas',
  'num',
  'numa',
  'por',
  'pelo',
  'pela',
  'pelos',
  'pelas',
  'para',
  'pra',
  'pro',
  'com',
  'e',
  'ou',
  'que',
  'como',
  'qual',
  'quais',
  'quando',
  'onde',
  'meu',
  'minha',
  'meus',
  'minhas',
  'seu',
  'sua',
  'eu',
  'me',
  'te',
  'lhe',
  'se',
  'ao',
  'aos',
  'estou',
  'esta',
  'estamos',
  'estao',
  'ser',
  'sou',
  'ha',
  'tem',
  'tenho',
  'nao',
  'fazer',
  'faco',
  'devo',
  'posso',
  'pode',
  'apos',
  'depois',
  'isso',
  'esse',
  'essa',
  'este',
  'ja',
  'agora',
  'preciso',
  'saber',
  'quero',
  'muito',
  'mais',
  'mesmo',
  'ate',
  'sobre',
  'entre',
  'foi',
  'vai',
  'tive',
  'ter',
  'algo',
  'alguem',
  'alguma',
  'algum',
};

/// Converte para minúsculas, remove acentos e pontuação.
String normalize(String input) {
  final lower = input.toLowerCase();
  final buf = StringBuffer();
  for (final rune in lower.runes) {
    final ch = String.fromCharCode(rune);
    buf.write(_accents[ch] ?? ch);
  }
  return buf.toString().replaceAll(_nonWord, ' ').trim().replaceAll(RegExp(r'\s+'), ' ');
}

/// Separa um texto normalizado em palavras.
List<String> tokenize(String input, {bool dropStopwords = false}) {
  final n = normalize(input);
  if (n.isEmpty) return const [];
  final tokens = n.split(' ');
  if (!dropStopwords) return tokens;
  return tokens.where((t) => !stopwords.contains(t)).toList();
}

/// Radical simplificado: remove plural regular para comparar "abrigos" e "abrigo".
String lightStem(String token) {
  if (token.length > 4 && token.endsWith('oes')) return '${token.substring(0, token.length - 3)}ao';
  if (token.length > 4 && token.endsWith('aes')) return '${token.substring(0, token.length - 3)}ao';
  if (token.length > 3 && token.endsWith('s')) return token.substring(0, token.length - 1);
  return token;
}

/// Distância de edição de Damerau-Levenshtein (transposições contam como 1).
/// Interrompe cedo quando ultrapassa [max].
int editDistance(String a, String b, {int max = 3}) {
  if ((a.length - b.length).abs() > max) return max + 1;
  final m = a.length, n = b.length;
  var prevPrev = List<int>.filled(n + 1, 0);
  var prev = List<int>.generate(n + 1, (j) => j);
  var cur = List<int>.filled(n + 1, 0);
  for (var i = 1; i <= m; i++) {
    cur[0] = i;
    var rowMin = cur[0];
    for (var j = 1; j <= n; j++) {
      final cost = a.codeUnitAt(i - 1) == b.codeUnitAt(j - 1) ? 0 : 1;
      var v = [prev[j] + 1, cur[j - 1] + 1, prev[j - 1] + cost].reduce((x, y) => x < y ? x : y);
      if (i > 1 && j > 1 && a.codeUnitAt(i - 1) == b.codeUnitAt(j - 2) && a.codeUnitAt(i - 2) == b.codeUnitAt(j - 1)) {
        final t = prevPrev[j - 2] + 1;
        if (t < v) v = t;
      }
      cur[j] = v;
      if (v < rowMin) rowMin = v;
    }
    if (rowMin > max) return max + 1;
    final tmp = prevPrev;
    prevPrev = prev;
    prev = cur;
    cur = tmp;
  }
  return prev[n];
}
