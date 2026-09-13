import 'package:flutter/material.dart';
import 'package:melodia/l10n/generated/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'services/auth_service.dart';
import 'services/locale_controller.dart';
import 'services/music_spec_service.dart';
import 'services/music_video_service.dart';
import 'services/suno_api_service.dart';
import 'screens/home_shell.dart';
import 'screens/login_screen.dart';
import 'screens/splash_video_screen.dart';
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

final localeController = LocaleController();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await localeController.load();
  runApp(const MelodiaApp());
}

class MelodiaApp extends StatelessWidget {
  const MelodiaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: localeController,
      builder: (context, _) {
        return MaterialApp(
          title: 'Melodia Studio',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.dark,
          themeMode: ThemeMode.dark,
          locale: localeController.locale,
          supportedLocales: LocaleController.supportedLocalesList,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
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
              : const _RootSwitcher(),
        );
      },
    );
  }
}

/// Uygulama açılışında splash videosunu, altında ZATEN mount edilmiş
/// (dolayısıyla oturum kontrolünü ARKA PLANDA paralel yürüten) [_AppRoot]
/// ile birlikte gösterir. Splash bitince yumuşak bir crossfade ile
/// [_AppRoot]'a geçilir -- bu sayede splash'in 4 saniyesi boyunca zaten
/// süregelen oturum kontrolü genelde tamamlanmış olur, splash kalkar
/// kalkmaz doğru ekran (Login/HomeShell) hazır durumda görünür.
class _RootSwitcher extends StatefulWidget {
  const _RootSwitcher();

  @override
  State<_RootSwitcher> createState() => _RootSwitcherState();
}

class _RootSwitcherState extends State<_RootSwitcher> {
  double _splashOpacity = 1;
  bool _splashMounted = true;

  void _finishSplash() {
    // DİKKAT: opacity'yi 0'a indirip widget'ı HEMEN ağaçtan kaldırmıyoruz --
    // aksi halde AnimatedOpacity'nin animasyona başlaması için hiç zaman
    // kalmaz, geçiş "yumuşak" değil ANİ görünür. Önce fade-out'un
    // (400ms) bitmesini bekliyoruz, SONRA widget'ı tamamen kaldırıyoruz.
    setState(() => _splashOpacity = 0);
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) setState(() => _splashMounted = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const _AppRoot(),
        if (_splashMounted)
          AnimatedOpacity(
            opacity: _splashOpacity,
            duration: const Duration(milliseconds: 400),
            child: SplashVideoScreen(onFinished: _finishSplash),
          ),
      ],
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
      authService: _authService,
      localeController: localeController,
      onLoggedOut: () => setState(() => _loggedIn = false),
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