import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/auth_service.dart';
import '../services/song_library.dart';
import '../theme/app_theme.dart';
import '../widgets/premium_back_button.dart';

/// Hesap Bilgileri ekranı — settings_screen.dart ile AYNI header deseni
/// (standart AppBar YOK, PremiumBackButton + gradyan en tepeden başlıyor).
/// Salt okunur bilgiler: ID, isim, e-posta, üyelik tarihi/süresi, plan,
/// toplam üretilen şarkı. Hesap silme zaten Ayarlar ekranında var, burada
/// TEKRAR edilmiyor.
class AccountInfoScreen extends StatelessWidget {
  const AccountInfoScreen({super.key, required this.authService, required this.library});

  final AuthService authService;
  final SongLibrary library;

  String get _displayName {
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

  /// "X gündür/aydır/yıldır kullanıyorsun" -- ham tarihin yanında,
  /// kullanıcının daha kolay ilişki kurabileceği bir süre ifadesi.
  String? _relativeSince(String? iso) {
    if (iso == null || iso.isEmpty) return null;
    final date = DateTime.tryParse(iso);
    if (date == null) return null;
    final days = DateTime.now().difference(date).inDays;
    if (days < 1) return 'Bugün katıldın';
    if (days < 30) return '$days gündür buradasın';
    if (days < 365) {
      final months = (days / 30).floor();
      return '$months aydır buradasın';
    }
    final years = (days / 365).floor();
    return '$years yıldır buradasın';
  }

  String _planLabelFor(String? plan) {
    switch (plan) {
      case 'pro_weekly':
        return 'Pro • Haftalık';
      case 'pro_monthly':
        return 'Pro • Aylık';
      case 'pro_yearly':
        return 'Pro • Yıllık';
      default:
        return 'Ücretsiz Plan';
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = authService.userId ?? '—';
    final email = authService.email ?? '—';
    final memberSince = _formatDate(library.memberSince);
    final relativeSince = _relativeSince(library.memberSince);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGlow),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: Row(
                  children: [
                    const PremiumBackButton(),
                    const SizedBox(width: 12),
                    const Text(
                      'Hesap Bilgileri',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // ---- Avatar + isim + üyelik süresi ----
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person, color: Colors.white, size: 34),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  _displayName,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (relativeSince != null) ...[
                const SizedBox(height: 4),
                Center(
                  child: Text(
                    relativeSince,
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 12.5),
                  ),
                ),
              ],
              const SizedBox(height: 28),

              // ---- Bilgi kartı ----
              Container(
                decoration: AppColors.glassCard(radius: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Column(
                    children: [
                      _InfoRow(
                        icon: Icons.badge_outlined,
                        label: 'Kullanıcı ID',
                        value: userId,
                        monospace: true,
                        // YENİ: destek talebi açarken bu ID istenebiliyor --
                        // dokununca panoya kopyalanıyor.
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: userId));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Kullanıcı ID kopyalandı')),
                          );
                        },
                        trailing: const Icon(Icons.copy_rounded, color: AppColors.textMuted, size: 16),
                      ),
                      const Divider(height: 1, thickness: 1, color: AppColors.border),
                      _InfoRow(icon: Icons.person_outline, label: 'İsim', value: _displayName),
                      const Divider(height: 1, thickness: 1, color: AppColors.border),
                      _InfoRow(icon: Icons.email_outlined, label: 'E-posta', value: email),
                      const Divider(height: 1, thickness: 1, color: AppColors.border),
                      _InfoRow(
                        icon: Icons.calendar_today_outlined,
                        label: 'Üyelik Başlangıcı',
                        value: memberSince ?? 'Bilinmiyor',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ---- İkinci kart: plan + üretim özeti ----
              // YENİ: kullanıcının "hesabım" derken merak edeceği diğer
              // iki mantıklı bilgi -- şu anki planı ve bugüne kadar
              // ürettiği toplam şarkı sayısı. ListenableBuilder ile
              // sarılmıyor çünkü bu ekran zaten her açılışta taze veriyle
              // (SongLibrary zaten profile_screen.dart'ta tazelenmiş
              // durumda) geliyor.
              Container(
                decoration: AppColors.glassCard(radius: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Column(
                    children: [
                      _InfoRow(
                        icon: Icons.workspace_premium_outlined,
                        label: 'Mevcut Plan',
                        value: _planLabelFor(library.plan),
                      ),
                      const Divider(height: 1, thickness: 1, color: AppColors.border),
                      _InfoRow(
                        icon: Icons.library_music_outlined,
                        label: 'Toplam Üretilen Şarkı',
                        value: '${library.songs.length}',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.monospace = false,
    this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool monospace;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textSecondary),
      title: Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
      subtitle: Text(
        value,
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          fontFamily: monospace ? 'monospace' : null,
        ),
        overflow: TextOverflow.ellipsis,
      ),
      trailing: trailing,
      onTap: onTap,
    );
  }
}
