import 'package:flutter_test/flutter_test.dart';
import 'package:lexicon/models/series.dart';

void main() {
  group('Series Model Tests', () {
    test('toMap() and fromMap() should work correctly', () {
      final originalSeries = Series(seriesId: 1, seriesName: 'Test Series');

      final seriesMap = originalSeries.toMap();
      final seriesFromMap = Series.fromMap(seriesMap);

      expect(seriesFromMap.seriesId, originalSeries.seriesId);
      expect(seriesFromMap.seriesName, originalSeries.seriesName);

      // Verify that fields removed from the model are not present in the map
      expect(seriesMap.containsKey('series_description'), isFalse);
      expect(seriesMap.containsKey('series_author'), isFalse);
      expect(seriesMap.containsKey('series_genre'), isFalse);
      expect(seriesMap.containsKey('series_tags'), isFalse);
      expect(seriesMap.containsKey('created_date'), isFalse);
      expect(seriesMap.containsKey('last_modified_date'), isFalse);
      expect(seriesMap.containsKey('cover_image'), isFalse);
      expect(seriesMap.containsKey('custom_fields'), isFalse);
    });

    // copyWith is not implemented in the Series model, so this test is removed.
    // If copyWith is added later, this test can be reinstated and updated.
  });
}
