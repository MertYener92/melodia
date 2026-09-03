import 'package:flutter/material.dart';
import 'services/suno_api_service.dart';
import 'screens/home_shell.dart';
import 'theme/app_theme.dart';

/// API key'i doğrudan koda YAZMAYIN.
/// Çalıştırırken şu şekilde verin:
///
/// flutter run --dart-define=SUNO_API_KEY=senin_api_keyin
///
/// API key almak için: https://sunoapi.org/api-key
const String sunoApiKey = String.fromEnvironment('SUNO_API_KEY');

void main() {
  runApp(const MelodiaApp());
}

class MelodiaApp extends StatelessWidget {
  const MelodiaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Melodia Studio',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      // Uygulamanın her ekranında, boş bir alana dokunulduğunda
      // klavyeyi otomatik olarak kapatır. Tek tek her ekrana
      // GestureDetector eklemek yerine merkezi bir çözüm.
      builder: (context, child) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            final currentFocus = FocusScope.of(context);
            if (!currentFocus.hasPrimaryFocus &&
                currentFocus.focusedChild != null) {
              FocusManager.instance.primaryFocus?.unfocus();
            }
          },
          child: child,
        );
      },
      home: sunoApiKey.isEmpty
          ? const _MissingApiKeyScreen()
          : HomeShell(service: SunoApiService(apiKey: sunoApiKey)),
    );
  }
}

class _MissingApiKeyScreen extends StatelessWidget {
  const _MissingApiKeyScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.key_off, size: 48, color: AppColors.pink),
              SizedBox(height: 16),
              Text(
                'API key bulunamadı.\n\n'
                'Uygulamayı şu komutla çalıştırın:\n'
                'flutter run --dart-define=SUNO_API_KEY=senin_keyin',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textPrimary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}