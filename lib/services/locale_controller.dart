import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Uygulamanın dilini yönetir.
///
/// Varsayılan davranış: kullanıcı henüz elle bir dil SEÇMEDİYSE, cihazın
/// sistem dili otomatik kullanılır (desteklenen diller: tr, en, es —
/// başka bir dil ise İngilizce'ye düşülür). Kullanıcı Ayarlar'dan elle bir
/// dil seçerse, bu tercih [FlutterSecureStorage]'a kaydedilir ve bir
/// sonraki açılışta da (sistem dili ne olursa olsun) o dil kullanılır.
///
/// [locale] null dönerse MaterialApp'in `locale:` parametresine de null
/// verilir — bu, Flutter'a "sistem dilini kullan (desteklenenler
/// arasından en uygununu seç)" der, [supportedLocalesList] ile birebir
/// aynı otomatik eşleştirmeyi Flutter'ın kendisi yapar.
class LocaleController extends ChangeNotifier {
  static const _storageKey = 'user_selected_locale';
  static const _storage = FlutterSecureStorage();

  static const supportedLocalesList = [
    Locale('en'),
    Locale('tr'),
    Locale('es'),
  ];

  Locale? _locale;

  /// null ise "sistemi takip et" demektir.
  Locale? get locale => _locale;

  /// Ayarlar ekranındaki seçici için: şu an aktif olan dil kodu — kullanıcı
  /// elle seçtiyse onu, seçmediyse cihazın o an algılanan (desteklenen
  /// diller arasından eşleşen) dilini döner.
  String get effectiveLanguageCode {
    if (_locale != null) return _locale!.languageCode;
    final deviceLocale = PlatformDispatcher.instance.locale;
    final match = supportedLocalesList.firstWhere(
      (l) => l.languageCode == deviceLocale.languageCode,
      orElse: () => const Locale('en'),
    );
    return match.languageCode;
  }

  /// Uygulama açılışında main.dart'tan bir kez çağrılır — kayıtlı bir
  /// tercih varsa yükler, yoksa [_locale] null kalır (sistem dili takip
  /// edilmeye devam eder).
  Future<void> load() async {
    final saved = await _storage.read(key: _storageKey);
    if (saved != null && saved.isNotEmpty) {
      _locale = Locale(saved);
      notifyListeners();
    }
  }

  /// Kullanıcı Ayarlar'dan elle bir dil seçtiğinde çağrılır. Kalıcı olarak
  /// kaydedilir — bir sonraki açılışta cihaz dili değişse bile bu tercih
  /// korunur.
  Future<void> setLocale(Locale locale) async {
    _locale = locale;
    await _storage.write(key: _storageKey, value: locale.languageCode);
    notifyListeners();
  }

  /// Kullanıcı "Sistem Dili"ne geri dönmek isterse — kayıtlı tercihi siler,
  /// tekrar cihaz diline göre otomatik davranışa döner.
  Future<void> useSystemDefault() async {
    _locale = null;
    await _storage.delete(key: _storageKey);
    notifyListeners();
  }
}