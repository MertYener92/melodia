import 'package:flutter/material.dart';
import 'package:melodia/l10n/generated/app_localizations.dart';
import '../services/auth_service.dart';
import '../services/locale_controller.dart';
import '../services/player_controller.dart';
import '../services/song_library.dart';
import '../services/suno_api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_songs_state.dart';
import '../widgets/profile_completion_card.dart';
import '../widgets/song_list_item.dart';
import 'profile_completion_flow_screen.dart';
import 'settings_screen.dart';

/// Profil ekranı: en üstte mor-pembe tonlarından siyaha akan bir başlık
/// alanı (sağ üstte Ayarlar ikonu, avatar + isim + ID, "Edit Profile"
/// butonu), altında "Complete Your Profile" ve kullanıcının şarkıları.
///
/// Hesap bilgileri, abonelik/ödeme, yardım ve hakkında satırları bu
/// ekrandan KALDIRILDI -- hepsi Ayarlar ekranında (bkz. settings_screen.dart).
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.library,
    required this.service,
    required this.authService,
    required this.localeController,
    required this.onLoggedOut,
    required this.player,
    required this.onNavigateToCreate,
  });

  final SongLibrary library;
  final SunoApiService service;
  final AuthService authService;
  final LocaleController localeController;
  final PlayerController player;

  /// Songs bölümü boşken buton HomeShell'e "0. sekmeye (CreateScreen)
  /// geç" der (bkz. home_shell.dart _goToTab).
  final VoidCallback onNavigateToCreate;

  /// Çıkış yapıldığında ya da hesap silindiğinde çağrılır (main.dart'a
  /// kadar bubbling yaparak login ekranına dönmeyi sağlar).
  final VoidCallback onLoggedOut;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    widget.library.refreshQuota();
  }

  String get _displayName {
    // Kullanıcı bir görünen ad belirlediyse onu kullan; e-postadan
    // türetme SADECE bu alan boşken devreye giren bir fallback.
    final override = widget.library.displayNameOverride;
    if (override != null && override.trim().isNotEmpty) return override.trim();

    final email = widget.authService.email;
    if (email == null || email.isEmpty) return 'Kullanıcı';
    final localPart = email.split('@').first;
    final cleaned = localPart.replaceAll(RegExp(r'[._]+'), ' ').trim();
    if (cleaned.isEmpty) return 'Kullanıcı';
    return cleaned
        .split(' ')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  /// Kullanıcı ID'si: Cognito 'sub' UUID'sinin tire'siz ilk 10 karakteri.
  String? get _userHandle {
    final id = widget.authService.userId;
    if (id == null || id.isEmpty) return null;
    final compact = id.replaceAll('-', '');
    return '@${compact.length > 10 ? compact.substring(0, 10) : compact}';
  }

  void _openProfileCompletion() {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => ProfileCompletionFlowScreen(
              library: widget.library,
              service: widget.service,
              initialStep: widget.library.profileStep,
            ),
          ),
        )
        .then((_) => setState(() {}));
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SettingsScreen(
          service: widget.service,
          authService: widget.authService,
          localeController: widget.localeController,
          library: widget.library,
          onAccountDeleted: widget.onLoggedOut,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ListenableBuilder(
      listenable: Listenable.merge([widget.library, widget.player]),
      builder: (context, _) {
        final avatarUrl = widget.library.avatarUrl;
        final handle = _userHandle;
        final completedSongs =
            widget.library.songs.where((s) => s.pendingId == null).toList();

        // Gradyan durum çubuğunun altına da uzansın diye ekran SafeArea
        // İÇİNDE DEĞİL; üst boşluğu burada elle ekliyoruz.
        return ColoredBox(
          color: AppColors.background,
          child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              padding: EdgeInsets.fromLTRB(
                16,
                MediaQuery.of(context).padding.top + 8,
                16,
                22,
              ),
              // Marka moru/pembesi KORUNDU ama doygunluğu ve parlaklığı
              // düşürüldü (önceki açık lila göz yoruyordu): pembeye çalan
              // koyu mürdüm -> koyu mor -> siyah. Renk, "Profili Düzenle"
              // butonunun hemen altında tamamen sönüyor.
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF6E4668),
                    Color(0xFF4A3059),
                    Color(0xFF221A33),
                    AppColors.background,
                  ],
                  stops: [0.0, 0.34, 0.68, 1.0],
                ),
              ),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: _openSettings,
                      child: Container(
                        width: 40,
                        height: 40,
                        // Gradyan koyulaştığı için siyah yerine düşük
                        // opaklıkta beyaz -- karanlık zeminde okunur kalıyor.
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.14),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.settings_outlined,
                          color: Colors.white,
                          size: 21,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 26),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: _openProfileCompletion,
                        child: Container(
                          width: 76,
                          height: 76,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.surfaceElevated,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.55),
                              width: 2,
                            ),
                          ),
                          child: ClipOval(
                            child: avatarUrl != null
                                ? Image.network(
                                    avatarUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => const Icon(
                                      Icons.person_rounded,
                                      color: Colors.white,
                                      size: 38,
                                    ),
                                  )
                                : const Icon(
                                    Icons.person_rounded,
                                    color: Colors.white,
                                    size: 38,
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: AppFonts.display,
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (handle != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                handle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  GestureDetector(
                    onTap: _openProfileCompletion,
                    child: Container(
                      height: 46,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(23),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.edit_rounded, color: Colors.white, size: 17),
                          const SizedBox(width: 8),
                          Text(
                            l10n.profileEditProfile,
                            style: const TextStyle(
                              fontFamily: AppFonts.rounded,
                              fontFamilyFallback: AppFonts.roundedFallback,
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              // Alt sekme çubuğu (extendBody) içeriğin üstüne binmesin.
              padding: EdgeInsets.fromLTRB(
                16,
                18,
                16,
                24 + MediaQuery.of(context).padding.bottom,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profil tamamlanınca (profileCompleted) kart bir daha
                  // görünmez -- backend adım 4'te bunu otomatik true yazar.
                  if (!widget.library.profileCompleted) ...[
                    ProfileCompletionCard(
                      step: widget.library.profileStep,
                      onTap: _openProfileCompletion,
                    ),
                    const SizedBox(height: 28),
                  ],
                  Text(
                    l10n.profileSongs,
                    style: const TextStyle(
                      fontFamily: AppFonts.display,
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Devam eden/başarısız üretimler (pendingId != null)
                  // burada gösterilmez, onlar Şarkılarım sekmesinde.
                  if (completedSongs.isEmpty)
                    EmptySongsState(onCreatePressed: widget.onNavigateToCreate)
                  else
                    for (var i = 0; i < completedSongs.length; i++) ...[
                      if (i > 0) const Divider(height: 1, color: AppColors.border),
                      SongListItem(
                        librarySong: completedSongs[i],
                        isPlaying: widget.player.current?.song.id ==
                                completedSongs[i].song.id &&
                            widget.player.isPlaying,
                        onTap: () => widget.player.playSong(completedSongs[i]),
                      ),
                    ],
                ],
              ),
            ),
          ],
          ),
        );
      },
    );
  }
}
