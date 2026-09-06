/// Suno'nun "get-timestamped-lyrics" uç noktasından dönen, tek bir
/// kelimenin şarkı içindeki zamanlamasını temsil eder.
class AlignedWord {
  AlignedWord({
    required this.word,
    required this.startS,
    required this.endS,
    required this.success,
  });

  /// Ham kelime metni. Suno bazen içine "[Verse]\n" gibi bölüm etiketleri
  /// ve satır sonu (\n) karakterleri gömer.
  final String word;
  final double startS;
  final double endS;
  final bool success;

  factory AlignedWord.fromJson(Map<String, dynamic> json) {
    return AlignedWord(
      word: json['word']?.toString() ?? '',
      startS: (json['startS'] as num?)?.toDouble() ?? 0,
      endS: (json['endS'] as num?)?.toDouble() ?? 0,
      success: json['success'] == true,
    );
  }

  bool isActiveAt(Duration position) {
    final seconds = position.inMilliseconds / 1000.0;
    return seconds >= startS && seconds < endS;
  }
}