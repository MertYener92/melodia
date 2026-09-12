/// Video oluşturma paketleri. Değerler (sahne sayısı, karakter oranı)
/// backend'deki `videoPackages.js` ile TUTARLI olmalı — biri değişirse
/// diğeri de güncellenmeli (şu an otomatik senkron değil, elle).
enum VideoPackageType { premium, economy }

class VideoPackage {
  const VideoPackage({
    required this.type,
    required this.title,
    required this.priceLabel,
    required this.sceneCountLabel,
    required this.characterLabel,
    required this.bullets,
  });

  final VideoPackageType type;
  final String title;

  /// GEÇİCİ — fiyatlar henüz kesinleşmedi. Kesinleşince burayı güncelle.
  final String priceLabel;

  final String sceneCountLabel;
  final String characterLabel;
  final List<String> bullets;

  String get apiValue => type == VideoPackageType.premium ? 'premium' : 'economy';

  static const premium = VideoPackage(
    type: VideoPackageType.premium,
    title: 'Premium',
    priceLabel: 'X TL', // TODO: gerçek fiyat belirlenince değiştir
    sceneCountLabel: '14-16 sahne',
    characterLabel: '%100 karakterli',
    bullets: [
      'Daha uzun, daha zengin bir klip',
      'Karakterin göründüğü, ağırlıklı şarkı söylediği sahneler',
      'Şarkının en özel anlarında (nakarat vb.) yakın plan karakter sahnesi',
      'Daha sinematik, "prodüksiyon" hissi',
    ],
  );

  static const economy = VideoPackage(
    type: VideoPackageType.economy,
    title: 'Ekonomik',
    priceLabel: 'X TL', // TODO: gerçek fiyat belirlenince değiştir
    sceneCountLabel: '8 sahne',
    characterLabel: '~%25 karakterli',
    bullets: [
      'Daha kısa, daha uygun fiyatlı bir klip',
      'Ağırlıklı olarak atmosferik/sinematik sahneler',
      'Karakter, sahnelerin bir kısmında şarkı söylerken görünür',
      'Hızlı ve bütçe dostu bir seçenek',
    ],
  );

  static const all = [premium, economy];
}