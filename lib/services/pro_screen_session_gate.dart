/// PRO ekranının bu UYGULAMA OTURUMU içinde otomatik olarak zaten
/// gösterilip gösterilmediğini tutar.
///
/// BİLİNÇLİ TASARIM KARARI: Bu SADECE bellekte (RAM) tutulan statik bir
/// değişken — hiçbir şekilde disk'e (SharedPreferences, FlutterSecureStorage,
/// dosya vb.) YAZILMIYOR. Uygulama tamamen kapatılıp yeniden açıldığında
/// (Dart VM'i yeniden başladığında) bu değer otomatik olarak `false`'a
/// döner ve PRO ekranı o yeni oturumda tekrar gösterilebilir.
///
/// Uygulama sadece arka plana alınıp öne getirildiğinde (Dart VM canlı
/// kalır, process sonlanmaz) bu değer KORUNUR — bu da "arka plana atıp
/// geri gelince tekrar gösterme" davranışını otomatik olarak sağlar,
/// ekstra bir yaşam döngüsü (lifecycle) yönetimi gerekmeden.
class ProScreenSessionGate {
  ProScreenSessionGate._();

  static bool shownThisSession = false;
}