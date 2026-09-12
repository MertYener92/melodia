import 'package:flutter/material.dart';
import '../models/song.dart';
import '../models/video_package.dart';
import '../services/music_video_service.dart';
import '../services/suno_api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_button.dart';
import 'create_music_video_screen.dart';

/// "Klip oluştur" akışının İLK ekranı: kullanıcı 2 paketten birini
/// (Premium / Ekonomik) detaylı bilgiyle görüp seçiyor. Seçim sonrası
/// "ödeme" adımı henüz gerçek bir satın alma akışına bağlı değil (video
/// consumable IAP'ı ayrı bir iş, bkz. proje durumu — madde 26) — şimdilik
/// seçim yapılır yapılmaz doğrudan klip oluşturma ekranına geçiliyor.
/// Gerçek ödeme eklenince SADECE [_onSelect] içindeki mantığın
/// değişmesi yeterli, ekranın geri kalanına dokunmaya gerek yok.
class SelectVideoPackageScreen extends StatefulWidget {
  const SelectVideoPackageScreen({
    super.key,
    required this.videoService,
    required this.service,
    required this.song,
    required this.genre,
    required this.mood,
  });

  final MusicVideoService videoService;
  final SunoApiService service;
  final Song song;
  final String genre;
  final String mood;

  @override
  State<SelectVideoPackageScreen> createState() => _SelectVideoPackageScreenState();
}

class _SelectVideoPackageScreenState extends State<SelectVideoPackageScreen> {
  VideoPackageType _selected = VideoPackageType.premium;

  void _onSelect(VideoPackage package) {
    // TODO (madde 26 tamamlanınca): burada gerçek bir consumable IAP
    // satın alma akışı (App Store) başlatılıp, başarılı ödeme
    // doğrulandıktan SONRA aşağıdaki navigasyon yapılmalı. Şimdilik
    // ödeme adımı yok, seçim doğrudan klip oluşturma ekranını açıyor.
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CreateMusicVideoScreen(
          videoService: widget.videoService,
          service: widget.service,
          song: widget.song,
          genre: widget.genre,
          mood: widget.mood,
          packageType: package.type,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Klip Paketini Seç'),
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            const Text(
              'Şarkın için nasıl bir klip istersin?',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Aşağıdaki iki paketten birini seçerek devam et.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 24),
            for (final package in VideoPackage.all) ...[
              _PackageCard(
                package: package,
                isSelected: _selected == package.type,
                onTap: () => setState(() => _selected = package.type),
              ),
              const SizedBox(height: 14),
            ],
            const SizedBox(height: 10),
            GradientButton(
              label: 'Devam Et',
              onPressed: () => _onSelect(
                _selected == VideoPackageType.premium
                    ? VideoPackage.premium
                    : VideoPackage.economy,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PackageCard extends StatelessWidget {
  const _PackageCard({
    required this.package,
    required this.isSelected,
    required this.onTap,
  });

  final VideoPackage package;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isPremium = package.type == VideoPackageType.premium;
    final accentColor = isPremium ? AppColors.pink : const Color(0xFF3B82F6);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? accentColor : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(color: accentColor.withValues(alpha: 0.5)),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    isPremium ? Icons.workspace_premium_rounded : Icons.movie_filter_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    package.title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  package.priceLabel,
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _InfoPill(label: package.sceneCountLabel, color: accentColor),
                const SizedBox(width: 8),
                _InfoPill(label: package.characterLabel, color: accentColor),
              ],
            ),
            const SizedBox(height: 14),
            for (final bullet in package.bullets)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_circle_rounded, color: accentColor, size: 15),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        bullet,
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5, height: 1.3),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 11.5, fontWeight: FontWeight.w600),
      ),
    );
  }
}