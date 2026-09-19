import 'package:flutter/material.dart';

/// Ortak ikonlar.
class AppIcons {
  AppIcons._();

  /// Tüm geri butonlarında kullanılan ince "<" oku.
  static const IconData back = Icons.arrow_back_ios_new_rounded;
}

/// Uygulamanın font aileleri (SF Pro).
///
/// iOS'ta sistem fontu zaten SF Pro'dur: 'CupertinoSystemDisplay' /
/// 'CupertinoSystemText' Flutter tarafından sistem fontuna çözülür.
/// Android'de SF Pro yoktur -- font dosyası eklenmedikçe varsayılan
/// font (Roboto) kullanılır.
class AppFonts {
  AppFonts._();

  /// Büyük başlıklar.
  static const String display = 'CupertinoSystemDisplay';

  /// Normal metinler.
  static const String text = 'CupertinoSystemText';

  /// Buton / jeton gibi yumuşak alanlar. iOS'un yuvarlak sistem fontu;
  /// bulunamazsa 'SF Pro Rounded' (eklenmişse), o da yoksa normal metin.
  static const String rounded = '.AppleSystemUIFontRounded';
  static const List<String> roundedFallback = ['SF Pro Rounded', text];

  /// Buton / jeton metinleri için hazır stil.
  static const TextStyle roundedStyle = TextStyle(
    fontFamily: rounded,
    fontFamilyFallback: roundedFallback,
  );
}

/// Melodia Studio'nun premium karanlık tema renkleri ve stilleri.
class AppColors {
  AppColors._();

  static const Color background = Color(0xFF0A0A12);
  static const Color surface = Color(0xFF14141F);
  static const Color surfaceElevated = Color(0xFF1C1C2A);
  static const Color border = Color(0xFF2A2A3C);

  static const Color textPrimary = Color(0xFFF5F5FA);
  static const Color textSecondary = Color(0xFFA0A0B8);
  static const Color textMuted = Color(0xFF6C6C82);

  static const Color purple = Color(0xFF8B5CF6);
  static const Color pink = Color(0xFFEC4899);
  static const Color purpleDeep = Color(0xFF6D28D9);
  static const Color blue = Color(0xFF3B82F6);

  /// Player'daki ana oynat butonu için pembe -> mor -> mavi geçiş. Sadece
  /// en önemli aksiyonda kullanılır, genel yüzeylerde değil.
  static const LinearGradient playGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [pink, purple, blue],
  );

  /// YENİ: Kütüphane filtre çiplerinin (Tümü/Hızlı/Standart/Gelişmiş)
  /// SEÇİLİ durumundaki gradyanlı altın çerçevesi için iki tonlu geçiş
  /// -- açık altından koyu altına.
  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFF3D27A), Color(0xFFC9A44C)],
  );

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [purple, pink],
  );

  static const LinearGradient backgroundGlow = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF1A1030), background],
  );

  /// YENİ: Kütüphane ekranları (Şarkılarım/Videolarım/Favorilerim/
  /// İndirdiklerim) için "granit" dokulu, tepeden aşağı çok katmanlı
  /// gradyan. Referans görseldeki kahverengi-siyah granit hissini,
  /// programın KENDİ renk paletiyle (purple/purpleDeep -> background)
  /// veriyor -- yeni bir renk eklemiyor, mevcut backgroundGlow'un üst
  /// tonundan (0xFF1A1030) başlayıp aradan geçen ek koyu-mor katmanlarla
  /// background'a (0xFF0A0A12) iniyor. Sadece bu 4 ekranda kullanılır --
  /// backgroundGlow'un kendisi (uygulama genelinde ~15 yerde kullanılıyor)
  /// DEĞİŞTİRİLMEDİ.
  static const LinearGradient libraryGranite = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: [0.0, 0.22, 0.46, 0.72, 1.0],
    colors: [
      Color(0xFF2B1F4A),
      Color(0xFF1A1030),
      Color(0xFF160D28),
      Color(0xFF100A1E),
      background,
    ],
  );

  static BoxDecoration glassCard({double radius = 24}) {
    return BoxDecoration(
      color: surface.withValues(alpha: 0.7),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: border, width: 1),
    );
  }
}

class AppTheme {
  AppTheme._();

  /// display/headline/titleLarge -> SF Pro Display, geri kalan -> SF Pro Text.
  static TextTheme _textTheme(TextTheme t) {
    final colored = t.apply(
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
      fontFamily: AppFonts.text,
    );
    TextStyle? d(TextStyle? x) => x?.copyWith(fontFamily: AppFonts.display);
    return colored.copyWith(
      displayLarge: d(colored.displayLarge),
      displayMedium: d(colored.displayMedium),
      displaySmall: d(colored.displaySmall),
      headlineLarge: d(colored.headlineLarge),
      headlineMedium: d(colored.headlineMedium),
      headlineSmall: d(colored.headlineSmall),
      titleLarge: d(colored.titleLarge),
    );
  }

  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.purple,
        secondary: AppColors.pink,
        surface: AppColors.surface,
      ),
      textTheme: _textTheme(base.textTheme),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(textStyle: AppFonts.roundedStyle),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(textStyle: AppFonts.roundedStyle),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(textStyle: AppFonts.roundedStyle),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(textStyle: AppFonts.roundedStyle),
      ),
      // AppBar'lı ekranların otomatik geri butonu da aynı sade "<" olsun.
      actionIconTheme: ActionIconThemeData(
        backButtonIconBuilder: (context) => const Icon(AppIcons.back, size: 20),
      ),
      // Doğrudan SnackBar kullanılan yerler için yedek stil -- uygulama
      // içindeki bildirimler normalde AppNotice (widgets/app_notice.dart).
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF1B1826),
        elevation: 0,
        contentTextStyle: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        actionTextColor: AppColors.pink,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceElevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.purple, width: 1.5),
        ),
        hintStyle: const TextStyle(color: AppColors.textMuted),
      ),
    );
  }
}
