import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:lexicon/constants/default_stop_words.dart'; // Added

// TODO: Import models if needed, e.g., Project, ContentBlock

final analysisServiceProvider = Provider<AnalysisService>((ref) {
  // TODO: Pass necessary dependencies, e.g., DatabaseHelperProvider if direct DB access needed
  // final dbHelper = ref.watch(databaseHelperProvider);
  return AnalysisService(/*dbHelper: dbHelper*/);
});

class AnalysisService {
  // final DatabaseHelper _dbHelper; // Example dependency

  AnalysisService(
    /*{required DatabaseHelper dbHelper}*/
  ) /*: _dbHelper = dbHelper*/;

  /// Retrieves all text content for a given project.
  ///
  /// This method will query the project-specific database to get all
  /// `text_content` from the `content_blocks` table.
  Future<String> _getAllTextForProject(Database projectDb) async {
    print(
      '[AnalysisService._getAllTextForProject] Querying content_blocks table...',
    );
    final List<Map<String, dynamic>> maps = await projectDb.query(
      'content_blocks',
    );
    print(
      '[AnalysisService._getAllTextForProject] Found ${maps.length} content blocks.',
    );
    if (maps.isNotEmpty) {
      final allText = maps
          .map(
            (map) => map['text_content'] as String? ?? '',
          ) // Handle potential null
          .join('\\n\\n');
      print(
        '[AnalysisService._getAllTextForProject] Combined text length: ${allText.length}',
      );
      // print('[AnalysisService._getAllTextForProject] Combined text (first 500 chars): ${allText.substring(0, allText.length > 500 ? 500 : allText.length)}');
      return allText;
    }
    print(
      '[AnalysisService._getAllTextForProject] No content blocks found or text_content is null/empty.',
    );
    return '';
  }

  /// Tokenizes text into words.
  ///
  /// - Converts text to lowercase.
  /// - Splits by non-alphanumeric characters (keeps apostrophes within words).
  /// - Removes empty strings.
  List<String> _tokenizeText(String text) {
    print('[AnalysisService._tokenizeText] Input text length: ${text.length}');
    if (text.isEmpty) {
      print(
        '[AnalysisService._tokenizeText] Text is empty, returning empty list.',
      );
      return [];
    }
    final RegExp wordRegex = RegExp(r"[a-zA-Z0-9]+(?:['’][a-zA-Z0-9]+)*");
    final tokens =
        wordRegex
            .allMatches(text.toLowerCase())
            .map((m) => m.group(0)!)
            .toList();
    print('[AnalysisService._tokenizeText] Generated ${tokens.length} tokens.');
    // print('[AnalysisService._tokenizeText] First 20 tokens: ${tokens.take(20).toList()}');
    return tokens;
  }

  /// Filters out stop words from a list of tokens.
  List<String> _filterStopWords(List<String> tokens, List<String> stopWords) {
    print(
      '[AnalysisService._filterStopWords] Input tokens: ${tokens.length}, Stop words: ${stopWords.length}',
    );
    final stopWordsSet = stopWords.map((e) => e.toLowerCase()).toSet();
    final filteredTokens =
        tokens
            .where((token) => !stopWordsSet.contains(token.toLowerCase()))
            .toList();
    print(
      '[AnalysisService._filterStopWords] Tokens after filtering: ${filteredTokens.length}',
    );
    return filteredTokens;
  }

  /// Calculates word frequencies from a list of words.
  Map<String, int> _calculateWordFrequencies(List<String> words) {
    print(
      '[AnalysisService._calculateWordFrequencies] Input words: ${words.length}',
    );
    final Map<String, int> frequencies = {};
    for (final word in words) {
      frequencies[word] = (frequencies[word] ?? 0) + 1;
    }
    print(
      '[AnalysisService._calculateWordFrequencies] Calculated ${frequencies.length} unique word frequencies.',
    );
    // print('[AnalysisService._calculateWordFrequencies] Frequencies (first 5): ${frequencies.entries.take(5).map((e) => '${e.key}: ${e.value}').toList()}');
    return frequencies;
  }

  /// Gets word frequencies for a given project.
  ///
  /// [projectDb] is the opened database connection for the specific project.
  /// [useStopWords] whether to filter out stop words.
  /// [customStopWords] an optional list of custom stop words to use instead of the default.
  Future<Map<String, int>> getWordFrequencies(
    Database projectDb, {
    bool useStopWords = false,
    List<String>? customStopWords,
  }) async {
    print(
      '[AnalysisService.getWordFrequencies] Called with useStopWords: $useStopWords, customStopWords count: ${customStopWords?.length ?? 'N/A'}',
    );
    final allText = await _getAllTextForProject(projectDb);
    if (allText.isEmpty) {
      print(
        '[AnalysisService.getWordFrequencies] All text is empty, returning empty frequencies.',
      );
      return {};
    }
    List<String> tokens = _tokenizeText(allText);
    print(
      '[AnalysisService.getWordFrequencies] Tokens after tokenization: ${tokens.length}',
    );

    if (useStopWords) {
      print(
        '[AnalysisService.getWordFrequencies] Applying stop word filtering.',
      );
      final List<String> stopWordsToUse =
          (customStopWords != null && customStopWords.isNotEmpty)
              ? customStopWords
              : defaultStopWords.toList();
      tokens = _filterStopWords(tokens, stopWordsToUse);
      print(
        '[AnalysisService.getWordFrequencies] Tokens after stop word filtering: ${tokens.length}',
      );
    }

    final frequencies = _calculateWordFrequencies(tokens);
    print(
      '[AnalysisService.getWordFrequencies] Returning ${frequencies.length} word frequencies.',
    );
    return frequencies;
  }

  /// Gets the top N most frequent words.
  /// [useStopWords] whether to filter out stop words.
  /// [customStopWords] an optional list of custom stop words to use instead of the default.
  Future<Map<String, int>> getTopNWords(
    Database projectDb,
    int n, {
    bool useStopWords = false,
    List<String>? customStopWords,
  }) async {
    print(
      '[AnalysisService.getTopNWords] Called for top $n words. useStopWords: $useStopWords, customStopWords count: ${customStopWords?.length ?? 'N/A'}',
    );
    final frequencies = await getWordFrequencies(
      projectDb,
      useStopWords: useStopWords,
      customStopWords: customStopWords,
    );
    if (frequencies.isEmpty) {
      print(
        '[AnalysisService.getTopNWords] Frequencies map is empty, returning empty top N.',
      );
      return {};
    }
    print(
      '[AnalysisService.getTopNWords] Got ${frequencies.length} frequencies. Sorting...',
    );
    final sortedWords =
        frequencies.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    final topN = sortedWords.take(n);
    print('[AnalysisService.getTopNWords] Returning ${topN.length} top words.');
    return Map.fromEntries(topN);
  }

  // Future ideas:
  // - N-gram analysis
  // - Stop word filtering
  // - Comparison across projects
}
