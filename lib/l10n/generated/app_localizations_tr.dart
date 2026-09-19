// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get navAiMusic => 'AI Müzik';

  @override
  String get navAiVideo => 'AI Video';

  @override
  String get navLibrary => 'Kütüphane';

  @override
  String get navProfile => 'Profil';

  @override
  String get createBadge => 'AI ŞARKI ÜRETİCİ';

  @override
  String get createTitle => 'Şarkını Oluştur';

  @override
  String get createSubtitle =>
      'Fikirlerinizi saniyeler içinde yapay zeka ile özgün şarkılara dönüştürün.';

  @override
  String get createButton => 'Şarkı Oluştur';

  @override
  String get profileTitle => 'Profilin';

  @override
  String get profileSongs => 'Şarkılarım';

  @override
  String get profileFavorites => 'Favori';

  @override
  String get profileSettings => 'Ayarlar';

  @override
  String get profileUpgradePlan => 'Planı Yükselt';

  @override
  String get profileHelpSupport => 'Yardım & Destek';

  @override
  String get profileAboutApp => 'Melodia Studio Hakkında';

  @override
  String get settingsLanguage => 'Dil';

  @override
  String get settingsLanguagePickerTitle => 'Dil Seç';

  @override
  String get settingsLanguageSystemDefault => 'Sistem Dili';

  @override
  String get libraryHeroTitle => 'Kütüphane';

  @override
  String get libraryHeroSubtitle => 'Tüm yaratımların burada.';

  @override
  String get libraryQuote => 'İyi fikirler\nher zaman\nbir yerlerde saklıdır.';

  @override
  String get libraryTagline => 'YARAT  ·  KEŞFET  ·  SAKLA';

  @override
  String get librarySongsTitle => 'Şarkılarım';

  @override
  String get librarySongsSubtitle => 'Ürettiğin tüm şarkılar.';

  @override
  String librarySongsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count şarkı',
      zero: 'Şarkı yok',
    );
    return '$_temp0';
  }

  @override
  String get libraryVideosTitle => 'Videolarım';

  @override
  String get libraryVideosSubtitle => 'Ürettiğin tüm videolar.';

  @override
  String libraryVideosCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count video',
      zero: 'Video yok',
    );
    return '$_temp0';
  }

  @override
  String get libraryFavoritesTitle => 'Favorilerim';

  @override
  String get libraryFavoritesSubtitle => 'Beğendiğin içerikler.';

  @override
  String libraryFavoritesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count içerik',
      zero: 'İçerik yok',
    );
    return '$_temp0';
  }

  @override
  String get libraryDownloadsTitle => 'İndirdiklerim';

  @override
  String get libraryDownloadsSubtitle => 'Cihazına indirdiklerin.';

  @override
  String get actionCancel => 'İptal';

  @override
  String get actionLogout => 'Çıkış Yap';

  @override
  String get dangerZoneTitle => 'TEHLİKELİ BÖLGE';

  @override
  String get deleteAccountConfirmTitle => 'Hesabını kalıcı olarak sil';

  @override
  String get deleteAccountConfirmBody =>
      'Bu işlem geri alınamaz. Tüm şarkıların, video kliplerin ve hesap bilgilerin KALICI olarak silinecek. Devam etmek istediğine emin misin?';

  @override
  String get deleteAccountShort => 'Hesabımı Sil';

  @override
  String get deleteAccountBody =>
      'Tüm şarkıların, video kliplerin ve hesap bilgilerin kalıcı olarak silinir. Bu işlem geri alınamaz.';

  @override
  String get deleteAccountPermanentButton => 'Hesabımı Kalıcı Olarak Sil';

  @override
  String get genericUnexpectedError => 'Beklenmeyen bir hata oluştu.';

  @override
  String get searchSongsHint => 'Şarkı ara...';

  @override
  String get noSongsFound => 'Şarkı bulunamadı';

  @override
  String get removeFromFavorites => 'Favorilerden kaldır';

  @override
  String get addToFavorites => 'Favorilere ekle';

  @override
  String get actionRename => 'Yeniden adlandır';

  @override
  String get actionShare => 'Paylaş';

  @override
  String get shareComingSoonMessage => 'Paylaşım özelliği yakında eklenecek.';

  @override
  String get actionDownload => 'İndir';

  @override
  String get downloadComingSoonMessage => 'İndirme özelliği yakında eklenecek.';

  @override
  String get actionDelete => 'Sil';

  @override
  String get renameSongTitle => 'Şarkıyı yeniden adlandır';

  @override
  String get actionSave => 'Kaydet';

  @override
  String get favoritesEmptyTitle => 'Henüz favori eklemedin';

  @override
  String get favoritesEmptyBody => 'Şarkı ya da klip oynatırken ♥ ikonuna bas.';

  @override
  String get sectionSongs => 'Şarkılar';

  @override
  String get sectionVideos => 'Videolar';

  @override
  String get untitledClip => 'Adsız klip';

  @override
  String get comingSoonTitle => 'Bu özellik yakında';

  @override
  String get downloadsComingSoonBody =>
      'Cihazına indirdiğin şarkı ve videoları burada görebileceğin bu özellik üzerinde çalışıyoruz.';

  @override
  String get aiMusicSubtitle =>
      'Aklındaki şarkıyı tarif et, gerisini biz halledelim.';

  @override
  String get modeAdvancedTitle => 'Gelişmiş';

  @override
  String get modeAdvancedSubtitle =>
      'Müziği insan gibi tarif et — dünyasını, hissini, hikayesini anlat. Yapay zeka profesyonel bir prodüksiyona çevirsin.';

  @override
  String get modeStandardTitle => 'Standart';

  @override
  String get modeStandardSubtitle =>
      'Tarz, ruh hali, vokal ve şarkı süresini kendin seç — hızlı, net ve tamamen senin kontrolünde bir form ile şarkını birkaç adımda oluştur.';

  @override
  String get modeQuickTitle => 'Hızlı';

  @override
  String get modeQuickSubtitle =>
      'Aklındaki fikri tek cümlede anlat, gerisini yapay zeka tamamlasın — tür, tempo, vokal ve söz teması dahil her şey otomatik olarak seçilsin.';

  @override
  String get createFormAppBarTitle => 'Şarkını oluştur';

  @override
  String get createFormHeadline => 'Bir sonraki şarkını oluştur';

  @override
  String get createFormSubtitle => 'Fikirlerini yapay zeka ile müziğe dönüştür';

  @override
  String get describeSongFirst => 'Lütfen önce şarkını tarif et.';

  @override
  String get songReadyMessage => 'Şarkın hazır! 🎶';

  @override
  String get describeSongLabel => 'Şarkını tarif et';

  @override
  String get describeSongHint =>
      'Yaz geceleri hakkında romantik bir pop şarkısı...';

  @override
  String get labelGenre => 'TÜR';

  @override
  String get labelMood => 'RUH HALİ';

  @override
  String get labelVocal => 'VOKAL';

  @override
  String get labelSongLength => 'ŞARKI SÜRESİ';

  @override
  String get quickCreateHeadline => 'Şarkını tek cümlede anlat';

  @override
  String get quickCreateSubtitle =>
      'Gerisini yapay zeka tamamlasın — tür, tempo, vokal, söz teması, hepsi otomatik.';

  @override
  String get quickCreateHint =>
      'Örn: Gece arabayla İstanbul\'da dolaşırken dinlenecek, havalı ama biraz karanlık bir şarkı';

  @override
  String get preparingLabel => 'Hazırlanıyor...';

  @override
  String get actionCreate => 'Oluştur';

  @override
  String unexpectedErrorWithDetail(String error) {
    return 'Beklenmeyen bir hata oluştu: $error';
  }

  @override
  String get proUpsellTitle => 'Yaratıcılığının Kilidini Aç';

  @override
  String get proUpsellSubtitle => 'Daha fazla üret. Daha iyi üret.';

  @override
  String get planWeeklyTitle => '7 Günlük Erişim';

  @override
  String get planWeeklySubtitle => 'Sınırsız erişim, haftalık faturalandırılır';

  @override
  String get planYearlyTitle => 'Yıllık Erişim';

  @override
  String get planYearlyBadge => 'En Avantajlı';

  @override
  String get featureSongsVideos =>
      'Yapay Zeka ile Şarkı & Müzik Videosu Oluştur';

  @override
  String get featureVoiceCovers => 'Kendi Sesinle Yapay Zeka Coverları Yap';

  @override
  String get featurePriorityGeneration => 'Öncelikli Üretim';

  @override
  String get featureCommercialLicense => 'Ticari Lisans Dahil';

  @override
  String get ctaContinue => 'Devam Et';

  @override
  String get cancelAnytimeNote => 'İstediğin zaman iptal et.';

  @override
  String get restorePurchasesAction => 'Satın alımları geri yükle';

  @override
  String get purchaseSuccessMessage => 'Aboneliğin aktif! Pro\'ya hoş geldin.';

  @override
  String saveBadge(int percent) {
    return '%$percent Tasarruf';
  }

  @override
  String productsLoadErrorWithDetail(String error) {
    return 'Ürünler yüklenemedi: $error';
  }

  @override
  String purchaseStartErrorWithDetail(String error) {
    return 'Satın alma başlatılamadı: $error';
  }

  @override
  String get loginHeadline => 'Aklındaki müziği\nhayata geçir.';

  @override
  String get loginSignInWithApple => 'Apple ile devam et';

  @override
  String get loginOr => 'veya';

  @override
  String get loginEmailLabel => 'E-posta';

  @override
  String get loginPasswordLabel => 'Şifre (en az 8 karakter)';

  @override
  String get loginVerificationCodeLabel => 'Doğrulama kodu';

  @override
  String get loginTitleSignIn => 'Devam etmek için giriş yap';

  @override
  String get loginTitleSignUp => 'Yeni bir hesap oluştur';

  @override
  String get loginTitleConfirm => 'E-postanı doğrula';

  @override
  String get loginButtonSignIn => 'Giriş yap';

  @override
  String get loginButtonSignUp => 'Kayıt ol';

  @override
  String get loginButtonConfirm => 'Doğrula';

  @override
  String get loginNoAccount => 'Hesabın yok mu? Kayıt ol';

  @override
  String get loginHaveAccount => 'Zaten hesabın var mı? Giriş yap';

  @override
  String loginAppleSignInFailedWithDetail(String error) {
    return 'Apple ile giriş başarısız: $error';
  }

  @override
  String loginConfirmCodeSentTo(String email) {
    return '$email adresine gönderilen 6 haneli kodu girin.';
  }

  @override
  String get settingsSectionSettings => 'Ayarlar';

  @override
  String get settingsSectionSupport => 'Destek';

  @override
  String get settingsSectionAbout => 'Hakkında';

  @override
  String get settingsSectionAccount => 'Hesap';

  @override
  String get settingsDisplayLanguage => 'Görüntüleme Dili';

  @override
  String get settingsHomepagePreference => 'Ana Sayfa Tercihi';

  @override
  String get settingsEmailSupport => 'E-posta Desteği';

  @override
  String get settingsHelpCenter => 'Yardım Merkezi';

  @override
  String get settingsRequestFeature => 'Özellik İste';

  @override
  String get settingsUploadVoice => 'Ses Yükle';

  @override
  String get settingsShareWithFriends => 'Arkadaşlarla Paylaş';

  @override
  String get settingsRateIt => 'Uygulamayı Puanla';

  @override
  String get settingsTermsPrivacy => 'Şartlar ve Gizlilik';

  @override
  String get settingsCopyrightRemoval => 'Telif Hakkı Kaldırma Talebi';

  @override
  String get settingsAboutUs => 'Hakkımızda';

  @override
  String get settingsComingSoon => 'Yakında';

  @override
  String get settingsShareMessage =>
      'Melodia\'ya göz at — yapay zekayla kendi şarkılarını oluştur!';

  @override
  String get profileEditProfile => 'Profili Düzenle';

  @override
  String get profileCompleteTitle => 'Profilini Tamamla';

  @override
  String get profileNoSongsYet => 'Henüz yayınlanmış şarkı yok';

  @override
  String get profileBrowseSongs => 'Şarkılarına göz at';

  @override
  String get profileStepTitle0 => 'Sana nasıl hitap edelim?';

  @override
  String get profileStepSubtitle0 => 'Görünen adını belirle';

  @override
  String get profileStepTitle1 => 'Bir profil fotoğrafı seç';

  @override
  String get profileStepSubtitle1 => 'Profiline bir yüz ver';

  @override
  String get profileStepTitle2 => 'Hangi müzik türlerini seviyorsun?';

  @override
  String get profileStepSubtitle2 => 'En sevdiğin 1-5 türü seç';

  @override
  String get profileStepTitle3 => 'Melodia\'da ne oluşturmak istiyorsun?';

  @override
  String get profileStepSubtitle3 => 'Sana özel önerileri şekillendirelim';

  @override
  String get settingsAccountInfo => 'Hesap Bilgileri';

  @override
  String get settingsSubscription => 'Abonelik ve Ödeme';

  @override
  String get settingsCredits => 'Kredi';

  @override
  String profileStepOf(int step) {
    return 'Adım $step / 4';
  }

  @override
  String get settingsSectionMembership => 'Üyelik';

  @override
  String get settingsSectionUsage => 'Kullanım';

  @override
  String get accountUserId => 'Kullanıcı ID';

  @override
  String get accountName => 'İsim';

  @override
  String get accountEmail => 'E-posta';

  @override
  String get accountMemberSince => 'Üyelik Başlangıcı';

  @override
  String get accountCurrentPlan => 'Mevcut Plan';

  @override
  String get accountTotalSongs => 'Toplam Üretilen Şarkı';

  @override
  String get accountIdCopied => 'Kullanıcı ID kopyalandı';

  @override
  String get accountUnknown => 'Bilinmiyor';

  @override
  String get planFree => 'Ücretsiz Plan';

  @override
  String get planProWeekly => 'Pro • Haftalık';

  @override
  String get planProMonthly => 'Pro • Aylık';

  @override
  String get planProYearly => 'Pro • Yıllık';

  @override
  String get playerMinimize => 'Küçült';

  @override
  String get playerMoreActions => 'Diğer';

  @override
  String get playerAiGenerated => 'AI ile üretildi';

  @override
  String get playerRemix => 'Remix';

  @override
  String get playerShare => 'Paylaş';

  @override
  String get playerPlaylist => 'Çalma listesi';

  @override
  String get playerComment => 'Yorum';

  @override
  String get playerComingSoon => 'Yakında';

  @override
  String get playerAddFavorite => 'Favorilere ekle';

  @override
  String get playerRemoveFavorite => 'Favorilerden çıkar';

  @override
  String get playerDownload => 'İndir';

  @override
  String get playerLyrics => 'Sözler';

  @override
  String get playerCreateVideo => 'Müzik klibi oluştur';

  @override
  String get playerShuffle => 'Karışık çal';

  @override
  String get playerRepeat => 'Tekrarla';

  @override
  String get playerPrevious => 'Önceki';

  @override
  String get playerNext => 'Sonraki';

  @override
  String get playerPlay => 'Oynat';

  @override
  String get playerPause => 'Duraklat';

  @override
  String get playerNoSong => 'Çalan şarkı yok';

  @override
  String get remixHint => 'Yeni tarzı tarif et…';

  @override
  String get remixCreate => 'Remix oluştur';

  @override
  String get remixInstrumental => 'Enstrümantal';

  @override
  String get remixStarted => 'Remix hazırlanıyor';

  @override
  String get remixReady => 'Remix hazır';

  @override
  String get remixFailed => 'Remix oluşturulamadı';

  @override
  String get remixView => 'Görüntüle';

  @override
  String get remixListen => 'Dinle';

  @override
  String get remixBuyCredits => 'Kredi al';

  @override
  String get remixCreditsNeeded => 'Remix için yeterli kredin yok.';

  @override
  String get remixStyleAcoustic => 'Akustik';

  @override
  String get remixStyleRock => 'Rock';

  @override
  String get remixStyleLofi => 'Lo-fi';

  @override
  String get remixStyleEdm => 'EDM';

  @override
  String get remixStyleJazz => 'Caz';

  @override
  String get remixStyleOrchestral => 'Orkestral';

  @override
  String get remixStyleRnb => 'R&B';

  @override
  String get remixStyleTrap => 'Trap';

  @override
  String get remixStyle80s => '80\'ler Synthwave';

  @override
  String get remixStyleLatin => 'Latin';

  @override
  String get remixStartedDetail => 'Hazır olduğunda haber vereceğiz.';

  @override
  String get remixFailedDetail => 'Kredin harcanmadı, tekrar deneyebilirsin.';

  @override
  String get libraryFilterAll => 'Tümü';

  @override
  String get libraryFilterMusic => 'Müzik';

  @override
  String get libraryFilterVideo => 'Video';

  @override
  String get libraryFilterRemix => 'Remix';

  @override
  String get libraryEmptyAll => 'Henüz bir şey oluşturmadın';

  @override
  String get libraryEmptyFiltered => 'Bu filtrede içerik yok';

  @override
  String get libraryVideoInProgress => 'Klip hazırlanıyor';

  @override
  String get libraryVideoFailed => 'Klip üretilemedi';

  @override
  String get libraryVideoNotReady =>
      'Klibin henüz hazır değil, hazır olunca burada oynatabilirsin.';

  @override
  String get libraryDeleteVideoTitle => 'Klibi sil';

  @override
  String libraryDeleteVideoMessage(String title) {
    return '\"$title\" kalıcı olarak silinecek. Bu işlem geri alınamaz.';
  }
}
