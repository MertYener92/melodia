import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/music_video_service.dart';
import '../services/suno_api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/credit_badges.dart';
import 'pro_upsell_screen.dart';

/// GEÇİCİ: "My Songs" sekmesinin yerini alan yeni "AI Video" sekmesi.
/// İçerik henüz tasarlanmadı — asıl klip oluşturma akışı ayrı ekranlarda
/// (select_video_package_screen.dart vb.) yaşıyor.
///
/// DEĞİŞTİ: Video artık bir jeton/kredi sistemi KULLANMIYOR — kullanıcı
/// video oluşturmak istediğinde tek seferlik, video başına ücret alınacak
/// (ayrı bir satın alma akışı, henüz yazılmadı). Bu yüzden burada jeton
/// rozeti YOK, sadece sabit Pro rozeti gösteriliyor.
class AiVideoScreen extends StatelessWidget {
  const AiVideoScreen({
    super.key,
    required this.service,
    required this.authService,
    required this.apiService,
  });

  // NOT: service şu an bu ekranda kullanılmıyor (jeton rozeti kaldırıldı),
  // ama video başına satın alma akışı eklenince (proje durum tablosu #26)
  // burada tekrar gerekecek — imzada tutuluyor, çağıran taraf (home_shell)
  // değişmesin diye.
  final MusicVideoService service;

  /// Pro rozetine dokununca [ProUpsellScreen]'i açabilmek için.
  final AuthService authService;
  final SunoApiService apiService;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'AI Video',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Bu bölüm yakında burada olacak.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                ),
                const Expanded(
                  child: Center(
                    child: Text(
                      'Yapım aşamasında',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Sağ üst köşede SADECE Pro rozeti. CreateScreen ve AiMusicScreen
        // ile BİREBİR aynı padding (20,16,20,0) ve Align(topRight).
        SafeArea(
          bottom: false,
          child: Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: ProBadge(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    fullscreenDialog: true,
                    builder: (_) => ProUpsellScreen(
                      authService: authService,
                      apiService: apiService,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}