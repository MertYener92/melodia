/// Backend'deki `/music-spec` endpoint'inin döndürdüğü, kullanıcının
/// doğal dildeki cevaplarından Bedrock (Claude) tarafından çıkarılan
/// profesyonel müzik üretim şartnamesi.
class MusicSpec {
  MusicSpec({
    required this.genre,
    required this.subgenre,
    required this.bpm,
    required this.key,
    required this.mood,
    required this.energyCurve,
    required this.instrumentation,
    required this.drumStyle,
    required this.bassStyle,
    required this.vocalCharacter,
    required this.vocalGender,
    required this.arrangement,
    required this.lyricalTheme,
    required this.lyricalLanguage,
    required this.productionStyle,
    required this.mixCharacter,
    required this.generationPrompt,
    required this.title,
    required this.summaryTr,
  });

  final String genre;
  final String subgenre;
  final num bpm;
  final String key;
  final List<String> mood;
  final String energyCurve;
  final List<String> instrumentation;
  final String drumStyle;
  final String bassStyle;
  final String vocalCharacter;

  /// 'male' | 'female' | 'duet' | 'instrumental'
  final String vocalGender;
  final List<String> arrangement;
  final String lyricalTheme;
  final String lyricalLanguage;
  final String productionStyle;
  final String mixCharacter;

  /// Suno'nun "style" alanına doğrudan yapıştırılabilecek İngilizce prompt.
  final String generationPrompt;
  final String title;

  /// "Senin Şarkın" özet ekranında satır satır gösterilecek kısa Türkçe
  /// maddeler (\n ile ayrılmış).
  final String summaryTr;

  List<String> get summaryLines => summaryTr
      .split('\n')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();

  bool get isInstrumental => vocalGender == 'instrumental';

  /// SunoApiService.generateAndWait'in beklediği vocalGender kısaltması.
  String? get sunoVocalGender {
    switch (vocalGender) {
      case 'male':
        return 'm';
      case 'female':
        return 'f';
      default:
        return null; // duet / instrumental -> backend varsayılanına bırak
    }
  }

  factory MusicSpec.fromJson(Map<String, dynamic> json) {
    List<String> stringList(dynamic value) => (value as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList();

    return MusicSpec(
      genre: json['genre']?.toString() ?? '',
      subgenre: json['subgenre']?.toString() ?? '',
      bpm: (json['bpm'] as num?) ?? 100,
      key: json['key']?.toString() ?? '',
      mood: stringList(json['mood']),
      energyCurve: json['energy_curve']?.toString() ?? '',
      instrumentation: stringList(json['instrumentation']),
      drumStyle: json['drum_style']?.toString() ?? '',
      bassStyle: json['bass_style']?.toString() ?? '',
      vocalCharacter: json['vocal_character']?.toString() ?? '',
      vocalGender: json['vocal_gender']?.toString() ?? 'instrumental',
      arrangement: stringList(json['arrangement']),
      lyricalTheme: json['lyrical_theme']?.toString() ?? '',
      lyricalLanguage: json['lyrical_language']?.toString() ?? 'tr',
      productionStyle: json['production_style']?.toString() ?? '',
      mixCharacter: json['mix_character']?.toString() ?? '',
      generationPrompt: json['generation_prompt']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Adsız Şarkı',
      summaryTr: json['summary_tr']?.toString() ?? '',
    );
  }
}

class MusicSpecException implements Exception {
  MusicSpecException(this.message);
  final String message;
  @override
  String toString() => message;
}