import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Topluluk tarafından üretilen şarkıları keşfetme ekranı.
///
/// ÖNEMLİ: Bu ekran şu an MOCK (sahte/örnek) veriyle çalışıyor.
/// Gerçek bir "Discover" özelliği için şarkıları ve creator
/// bilgilerini saklayan bir BACKEND / veritabanı gerekiyor —
/// sunoapi.org bu tür bir topluluk verisi sağlamıyor. İleride
/// kendi backend'inizi (örn. Firebase, Supabase) bağlayarak bu
/// ekranı gerçek veriyle besleyebilirsiniz.
class DiscoverScreen extends StatelessWidget {
  const DiscoverScreen({super.key});

  static const _mockSongs = [
    _MockSong('Chasing the Stars', 'Pop', '@luna_ai', 128, 2400),
    _MockSong('Midnight Drive', 'Synthwave', '@neonwaves', 96, 1800),
    _MockSong('Golden Hour', 'Acoustic', '@sam_beats', 210, 3100),
    _MockSong('Electric Dreams', 'EDM', '@pulsecraft', 340, 5600),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          const Text(
            'Discover',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Explore songs created by the community',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: AppColors.glassCard(radius: 14),
            child: Row(
              children: const [
                Icon(Icons.info_outline, color: AppColors.purple, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Örnek içerik gösteriliyor — gerçek topluluk verisi '
                    'için bir backend entegrasyonu gerekir.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: const [
              _FilterPill(label: 'Trending', selected: true),
              SizedBox(width: 8),
              _FilterPill(label: 'New'),
              SizedBox(width: 8),
              _FilterPill(label: 'Popular'),
            ],
          ),
          const SizedBox(height: 20),
          ..._mockSongs.map((s) => _DiscoverTile(song: s)),
        ],
      ),
    );
  }
}

class _MockSong {
  const _MockSong(this.title, this.genre, this.creator, this.likes, this.plays);
  final String title;
  final String genre;
  final String creator;
  final int likes;
  final int plays;
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({required this.label, this.selected = false});
  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: selected ? AppColors.primaryGradient : null,
        color: selected ? null : AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: selected ? Colors.transparent : AppColors.border,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: selected ? Colors.white : AppColors.textSecondary,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }
}

class _DiscoverTile extends StatelessWidget {
  const _DiscoverTile({required this.song});
  final _MockSong song;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: AppColors.glassCard(radius: 18),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.music_note, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  song.title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${song.genre} · ${song.creator}',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Icon(
                Icons.favorite_border,
                color: AppColors.textMuted,
                size: 18,
              ),
              const SizedBox(height: 4),
              Text(
                '${song.likes}',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}