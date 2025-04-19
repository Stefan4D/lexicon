import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexicon/services/text_parser.dart';
import 'package:lexicon/services/word_frequency_analyser.dart';

final wordFrequencyProvider =
    StateNotifierProvider<WordFrequencyNotifier, Map<String, int>>((ref) {
      return WordFrequencyNotifier();
    });

class WordFrequencyNotifier extends StateNotifier<Map<String, int>> {
  WordFrequencyNotifier() : super({});

  void parseText(String filePath) {
    // Parse the text file and get the word frequency
    final wordFrequency = WordFrequencyAnalyser.countWordFrequency(TextParser.parse(filePath));

    // Update the state with the new word frequency
    state = wordFrequency;
  }

  void updateWordFrequency(String content) {
    // Update the word frequency based on the parsed text
    final wordFrequency = WordFrequencyAnalyser.countWordFrequency(content);

    // Update the state with the new word frequency
    state = wordFrequency;
  }
}
