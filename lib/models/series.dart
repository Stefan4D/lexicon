class Series {
  final int? seriesId;
  final String seriesName;

  Series({this.seriesId, required this.seriesName});

  Map<String, dynamic> toMap() {
    return {'series_id': seriesId, 'series_name': seriesName};
  }

  factory Series.fromMap(Map<String, dynamic> map) {
    return Series(
      seriesId: map['series_id'] as int?,
      seriesName: map['series_name'] as String,
    );
  }

  @override
  String toString() {
    return 'Series{seriesId: $seriesId, seriesName: $seriesName}';
  }

  Series copyWith({int? seriesId, String? seriesName}) {
    return Series(
      seriesId: seriesId ?? this.seriesId,
      seriesName: seriesName ?? this.seriesName,
    );
  }
}
