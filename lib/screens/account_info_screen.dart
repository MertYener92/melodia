import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:melodia/l10n/generated/app_localizations.dart';

import '../services/auth_service.dart';
import '../services/song_library.dart';
import '../theme/app_theme.dart';
import '../widgets/screen_header.dart';
import '../widgets/settings_section.dart';
import '../widgets/app_notice.dart';

/// Hesap Bilgileri ekranı — Ayarlar ekranıyla AYNI yapı: ortalanmış
/// başlık, bölüm başlıkları ve koyu kartlar içinde satırlar. Salt okunur
/// bilgiler. Hesap silme zaten Ayarlar'da, burada TEKRAR edilmiyor.
class AccountInfoScreen extends StatelessWidget {
  const AccountInfoScreen({
    super.key,
    required this.authService,
    required this.library,
  });

  final AuthService authService;
  final SongLibrary library;

  String get _displayName {
    // Kullanıcı bir görünen ad belirlediyse onu kullan; e-postadan
    // türetme SADECE bu alan boşken devreye giren bir fallback.
    final override = library.displayNameOverride;
    if (override != null && override.trim().isNotEmpty) return override.trim();

    final email = authService.email;
    if (email == null || email.isEmpty) return 'Kullanıcı';
    final localPart = email.split('@').first;
    final cleaned = localPart.replaceAll(RegExp(r'[._]+'), ' ').trim();
    if (cleaned.isEmpty) return 'Kullanıcı';
    return cleaned
        .split(' ')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  String? _formatDate(String? iso) {
    if (iso == null || iso.isEmpty) return null;
    final date = DateTime.tryParse(iso);
    if (date == null) return null;
    const months = [
      'Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz',
      'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _planLabelFor(String? plan, AppLocalizations l10n) {
    switch (plan) {
      case 'pro_weekly':
        return l10n.planProWeekly;
      case 'pro_monthly':
        return l10n.planProMonthly;
      case 'pro_yearly':
        return l10n.planProYearly;
      default:
        return l10n.planFree;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final userId = authService.userId ?? '—';
    final email = authService.email ?? '—';
    final memberSince = _formatDate(library.memberSince);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGlow),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              ScreenHeader(title: l10n.settingsAccountInfo),
              SettingsSectionTitle(l10n.settingsSectionAccount),
              SettingsCard(
                children: [
                  // Destek talebi açarken bu ID istenebiliyor --
                  // dokununca panoya kopyalanıyor.
                  SettingsRow(
                    icon: Icons.badge_outlined,
                    label: l10n.accountUserId,
                    value: userId,
                    monospace: true,
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: userId));
                      AppNotice.show(context, l10n.accountIdCopied, type: NoticeType.success);
                    },
                    trailing: const Icon(
                      Icons.copy_rounded,
                      color: AppColors.textMuted,
                      size: 16,
                    ),
                  ),
                  SettingsRow(
                    icon: Icons.person_outline,
                    label: l10n.accountName,
                    value: _displayName,
                  ),
                  SettingsRow(
                    icon: Icons.email_outlined,
                    label: l10n.accountEmail,
                    value: email,
                  ),
                ],
              ),
              SettingsSectionTitle(l10n.settingsSectionMembership),
              SettingsCard(
                children: [
                  SettingsRow(
                    icon: Icons.calendar_today_outlined,
                    label: l10n.accountMemberSince,
                    value: memberSince ?? l10n.accountUnknown,
                  ),
                  SettingsRow(
                    icon: Icons.workspace_premium_outlined,
                    label: l10n.accountCurrentPlan,
                    value: _planLabelFor(library.plan, l10n),
                  ),
                ],
              ),
              SettingsSectionTitle(l10n.settingsSectionUsage),
              SettingsCard(
                children: [
                  SettingsRow(
                    icon: Icons.library_music_outlined,
                    label: l10n.accountTotalSongs,
                    value: '${library.songs.length}',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
