import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/song_library.dart';
import '../services/suno_api_service.dart';
import '../theme/app_theme.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({
    super.key,
    required this.library,
    required this.service,
    required this.authService,
    required this.onLoggedOut,
  });

  final SongLibrary library;
  final SunoApiService service;
  final AuthService authService;

  /// Çıkış yapıldığında ya da hesap silindiğinde çağrılır (main.dart'a
  /// kadar bubbling yaparak login ekranına dönmeyi sağlar).
  final VoidCallback onLoggedOut;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListenableBuilder(
        listenable: library,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            children: [
              Center(
                child: Container(
                  width: 84,
                  height: 84,
                  decoration: const BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Center(
                child: Text(
                  'Your profile',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  _StatCard(
                    label: 'Songs',
                    value: '${library.songs.length}',
                  ),
                  const SizedBox(width: 12),
                  _StatCard(
                    label: 'Favorites',
                    value:
                        '${library.songs.where((s) => s.isFavorite).length}',
                  ),
                ],
              ),
              const SizedBox(height: 28),
              _MenuTile(
                icon: Icons.settings_outlined,
                label: 'Settings',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => SettingsScreen(
                      service: service,
                      authService: authService,
                      onAccountDeleted: onLoggedOut,
                    ),
                  ),
                ),
              ),
              const _MenuTile(icon: Icons.workspace_premium_outlined, label: 'Upgrade Plan'),
              const _MenuTile(icon: Icons.help_outline, label: 'Help & Support'),
              const _MenuTile(icon: Icons.info_outline, label: 'About Melodia Studio'),
            ],
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: AppColors.glassCard(radius: 16),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({required this.icon, required this.label, this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: AppColors.glassCard(radius: 14),
      child: ListTile(
        leading: Icon(icon, color: AppColors.textSecondary),
        title: Text(label, style: const TextStyle(color: AppColors.textPrimary)),
        trailing: const Icon(
          Icons.chevron_right,
          color: AppColors.textMuted,
        ),
        onTap: onTap ?? () {},
      ),
    );
  }
}