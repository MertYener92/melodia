import 'package:flutter/material.dart';
import 'services/auth_service.dart';
import 'services/music_spec_service.dart';
import 'services/music_video_service.dart';
import 'services/suno_api_service.dart';
import 'screens/home_shell.dart';
import 'screens/login_screen.dart';
import 'theme/app_theme.dart';

const String apiUrl = String.fromEnvironment('API_URL');
const String userPoolClientId = String.fromEnvironment('USER_POOL_CLIENT_ID');
const String awsRegion = String.fromEnvironment('AWS_REGION', defaultValue: 'eu-north-1');

// AI Müzik sihirbazının bağlandığı, Suno backend'inden TAMAMEN AYRI,
// Anthropic destekli backend.
const String musicSpecApiUrl = String.fromEnvironment(
  'MUSIC_SPEC_API_URL',
  defaultValue:
      'https://zrwhwl946e.execute-api.eu-north-1.amazonaws.com/music-spec',
);

// AI Video (Faz 1) sisteminin bağlandığı, tamamen izole yeni backend.
// Deploy ettikten sonra çıkan gerçek "VideoApiUrl" ile burayı güncelle
// (ya da --dart-define=MUSIC_VIDEO_API_URL=... ile ver).
const String musicVideoApiUrl = String.fromEnvironment(
  'MUSIC_VIDEO_API_URL',
  defaultValue: 'https://69e04hkaag.execute-api.eu-north-1.amazonaws.com',
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
  late final MusicVideoService _musicVideoService = MusicVideoService(
    apiUrl: musicVideoApiUrl,
    idTokenProvider: () => _authService.idToken,
  );

  bool _loggedIn = false;
  bool _checkingSession = true;

  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    final restored = await _authService.tryRestoreSession();
    if (!mounted) return;
    setState(() {
      _loggedIn = restored;
      _checkingSession = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingSession) {
      return const _SessionCheckScreen();
    }
    if (!_loggedIn) {
      return LoginScreen(
        authService: _authService,
        onLoggedIn: () => setState(() => _loggedIn = true),
      );
    }
    return HomeShell(
      service: _apiService,
      musicSpecService: _musicSpecService,
      musicVideoService: _musicVideoService,
    );
  }
}

/// Uygulama açılışında, kayıtlı bir oturum olup olmadığı kontrol
/// edilirken gösterilen kısa süreli yükleme ekranı.
class _SessionCheckScreen extends StatelessWidget {
  const _SessionCheckScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGlow),
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.pink),
        ),
      ),
    );
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