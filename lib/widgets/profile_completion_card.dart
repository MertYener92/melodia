import 'package:flutter/material.dart';
import 'package:melodia/l10n/generated/app_localizations.dart';
import '../theme/app_theme.dart';

/// "Complete Your Profile / Step 3 of 4" başlığı ve altındaki, mevcut
/// adımı gösteren tek satırlık kart (başlık + alt yazı + ">" oku).
/// profileCompleted true olduğunda ProfileScreen bu widget'ı HİÇ
/// göstermez (bkz. profile_screen.dart).
class ProfileCompletionCard extends StatelessWidget {
  const ProfileCompletionCard({
    super.key,
    required this.step,
    required this.onTap,
  });

  /// 0-4 arası tamamlanan adım sayısı.
  final int step;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final clampedStep = step.clamp(0, 3);
    final titles = [
      l10n.profileStepTitle0,
      l10n.profileStepTitle1,
      l10n.profileStepTitle2,
      l10n.profileStepTitle3,
    ];
    final subtitles = [
      l10n.profileStepSubtitle0,
      l10n.profileStepSubtitle1,
      l10n.profileStepSubtitle2,
      l10n.profileStepSubtitle3,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.profileCompleteTitle,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.profileStepOf(step.clamp(0, 4)),
          style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titles[clampedStep],
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitles[clampedStep],
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textPrimary,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
