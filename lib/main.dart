import 'package:flutter/material.dart';
import 'services/auth_service.dart';
import 'services/music_spec_service.dart';
import 'services/suno_api_service.dart';
import 'screens/home_shell.dart';
import 'screens/login_screen.dart';
import 'theme/app_theme.dart';

const String apiUrl = String.fromEnvironment('API_URL');
const String userPoolClientId = String.fromEnvironment('USER_POOL_CLIENT_ID');
const String awsRegion = String.fromEnvironment('AWS_REGION', defaultValue: 'eu-north-1');

// AI Müzik sihirbazının bağlandığı, Suno backend'inden TAMAMEN AYRI,
// Bedrock destekli yeni backend. Varsayılan değer zaten deploy edilen
// endpoint'i işaret eder; farklı bir ortamda değiştirmek istenirse
// --dart-define=MUSIC_SPEC_API_URL=... ile ezilebilir.
const String musicSpecApiUrl = String.fromEnvironment(
  'MUSIC_SPEC_API_URL',
  defaultValue:
      'https://zrwhwl946e.execute-api.eu-north-1.amazonaws.com/music-spec',
);

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
      home: (apiUrl.isEmpty || userPoolClientId.isEmpty)
          ? const _MissingConfigScreen()
          : const _AppRoot(),
    );
  }
}

class _AppRoot extends StatefulWidget {
  const _AppRoot();

  @override
  State<_AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<_AppRoot> {
  late final AuthService _authService = AuthService(
    userPoolClientId: userPoolClientId,
    region: awsRegion,
    backendUrl: apiUrl,
  );
  late final SunoApiService _apiService = SunoApiService(
    baseUrl: apiUrl,
    idTokenProvider: () => _authService.idToken,
  );
  late final MusicSpecService _musicSpecService = MusicSpecService(
    apiUrl: musicSpecApiUrl,
    idTokenProvider: () => _authService.idToken,
  );

  bool _loggedIn = false;

  @override
  Widget build(BuildContext context) {
    if (!_loggedIn) {
      return LoginScreen(
        authService: _authService,
        onLoggedIn: () => setState(() => _loggedIn = true),
      );
    }
    return HomeShell(service: _apiService, musicSpecService: _musicSpecService);
  }
}

class _MissingConfigScreen extends StatelessWidget {
  const _MissingConfigScreen();

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
                'Backend ayarları bulunamadı.\n\n'
                'Uygulamayı şu komutla çalıştırın:\n\n'
                'flutter run '
                '--dart-define=API_URL=... '
                '--dart-define=USER_POOL_CLIENT_ID=... '
                '--dart-define=AWS_REGION=eu-north-1',
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