import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// "AI Video" sekmesi: kullanıcının yüz fotoğrafından şarkı söyleyen bir
/// video klip oluşturacağı özelliğin yer tutucusu. Gerçek entegrasyon
/// (lip-sync/talking-avatar servisi) ayrı bir adımda eklenecek.
class VideoClipScreen extends StatelessWidget {
  const VideoClipScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGlow),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 84,
                  height: 84,
                  decoration: const BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.movie_creation_rounded,
                    color: Colors.white,
                    size: 38,
                  ),
                ),
                const SizedBox(height: 22),
                const Text(
                  'AI Video çok yakında',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                const Text(
                  'Fotoğrafını yükle, şarkını söyleyen bir video klip '
                  'oluştur. Bu özellik üzerinde çalışıyoruz.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}