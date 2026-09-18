import 'package:flutter/material.dart';
import 'package:melodia/l10n/generated/app_localizations.dart';
import '../theme/app_theme.dart';

/// Profile > Songs bölümünde kullanıcının hiç şarkısı yoksa gösterilen
/// boş durum: üç adet soluk (iskelet) şarkı satırı, ortasında
/// "Henüz yayınlanmış şarkı yok" yazısı ve altında çift-nota ikonlu
/// beyaz buton. Buton mevcut şarkı oluşturma ekranına yönlendirir --
/// burada YENİ bir akış tanımlanmıyor.
class EmptySongsState extends StatelessWidget {
  const EmptySongsState({super.key, required this.onCreatePressed});

  final VoidCallback onCreatePressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Stack(
      alignment: Alignment.center,
      children: [
        Column(
          children: [
            for (var i = 0; i < 3; i++) ...[
              if (i > 0) const SizedBox(height: 14),
              const _GhostRow(),
            ],
          ],
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.profileNoSongsYet,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: onCreatePressed,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3EEE6),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.library_music_rounded, color: Colors.black, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      l10n.profileBrowseSongs,
                      style: const TextStyle(
                        fontFamily: AppFonts.rounded,
                        fontFamilyFallback: AppFonts.roundedFallback,
                        color: Colors.black,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Soluk iskelet satır: yuvarlak köşeli kare + iki çubuk.
class _GhostRow extends StatelessWidget {
  const _GhostRow();

  @override
  Widget build(BuildContext context) {
    final fill = AppColors.surfaceElevated.withValues(alpha: 0.7);
    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FractionallySizedBox(
                widthFactor: 0.75,
                child: Container(
                  height: 10,
                  decoration: BoxDecoration(
                    color: fill,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              FractionallySizedBox(
                widthFactor: 0.5,
                child: Container(
                  height: 10,
                  decoration: BoxDecoration(
                    color: fill,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
