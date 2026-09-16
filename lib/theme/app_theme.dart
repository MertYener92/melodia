import 'package:flutter/material.dart';

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

  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.purple,
        secondary: AppColors.pink,
        surface: AppColors.surface,
      ),
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
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