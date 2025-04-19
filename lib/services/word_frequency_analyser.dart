class WordFrequencyAnalyser {
  // Function to count the frequency of each word in a given text
  static Map<String, int> countWordFrequency(String text) {
    // Normalize the text to lowercase and split it into words
    List<String> words = text.toLowerCase().split(RegExp(r'\W+'));

    // Create a map to store word frequencies
    Map<String, int> wordFrequency = {};

    // Iterate through each word and count its frequency
    for (String word in words) {
      if (word.isNotEmpty) {
        wordFrequency[word] = (wordFrequency[word] ?? 0) + 1;
      }
    }

    return wordFrequency;
  }

  // Function to get the top N most frequent words
  static List<MapEntry<String, int>> getTopNWords(
    Map<String, int> wordFrequency,
    int n,
  ) {
    // Sort the map entries by frequency in descending order and take the top N
    var sortedEntries =
        wordFrequency.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    return sortedEntries.take(n).toList();
  }

  // Function to get the least N frequent words
  static List<MapEntry<String, int>> getLeastNWords(
    Map<String, int> wordFrequency,
    int n,
  ) {
    // Sort the map entries by frequency in ascending order and take the least N
    var sortedEntries =
        wordFrequency.entries.toList()
          ..sort((a, b) => a.value.compareTo(b.value));

    return sortedEntries.take(n).toList();
  }

  // Function to get the total number of unique words
  static int getUniqueWordCount(Map<String, int> wordFrequency) {
    return wordFrequency.length;
  }

  // Function to get the total number of words
  static int getTotalWordCount(Map<String, int> wordFrequency) {
    return wordFrequency.values.reduce((a, b) => a + b);
  }

  // Function to get the average word length
  static double getAverageWordLength(Map<String, int> wordFrequency) {
    int totalLength = wordFrequency.keys.fold(
      0,
      (sum, word) => sum + word.length,
    );
    int totalCount = getTotalWordCount(wordFrequency);
    return totalCount > 0 ? totalLength / totalCount : 0.0;
  }

  // Function to get the longest word
  static String getLongestWord(Map<String, int> wordFrequency) {
    return wordFrequency.keys.reduce((a, b) => a.length > b.length ? a : b);
  }

  // Function to get the shortest word
  static String getShortestWord(Map<String, int> wordFrequency) {
    return wordFrequency.keys.reduce((a, b) => a.length < b.length ? a : b);
  }

  // Function to get the most frequent word
  static String getMostFrequentWord(Map<String, int> wordFrequency) {
    return wordFrequency.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  // Function to get the least frequent word
  static String getLeastFrequentWord(Map<String, int> wordFrequency) {
    return wordFrequency.entries
        .reduce((a, b) => a.value < b.value ? a : b)
        .key;
  }

  // Function to get the frequency of a specific word
  static int getWordFrequency(Map<String, int> wordFrequency, String word) {
    return wordFrequency[word] ?? 0;
  }

  // Function to get the percentage of a specific word in the text
  static double getWordPercentage(Map<String, int> wordFrequency, String word) {
    int totalCount = getTotalWordCount(wordFrequency);
    int wordCount = getWordFrequency(wordFrequency, word);
    return totalCount > 0 ? (wordCount / totalCount) * 100 : 0.0;
  }
}
