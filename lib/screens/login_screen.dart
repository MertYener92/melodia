import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:melodia/l10n/generated/app_localizations.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/looping_video_background.dart';

enum _Mode { signIn, signUp, confirm }

/// Login ekranı.
///
/// DEĞİŞTİ: Artık tam ekran, sessiz ve döngüde oynayan bir video arka
/// plan var (assets/videos/login-bg.mp4) + metinlerin okunabilmesi için
/// üstüne koyu bir gölge (gradient scrim). Form (e-posta/şifre/Apple ile
/// giriş/kayıt) işlevsel olarak birebir aynı — sadece bu yeni arka planın
/// üzerine, alt yarıda konumlandı. Apple ile giriş butonu zaten vardı,
/// sadece burada tekrar (ve çevirili) düzenlendi.
class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.authService,
    required this.onLoggedIn,
  });

  final AuthService authService;
  final VoidCallback onLoggedIn;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  _Mode _mode = _Mode.signIn;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _codeController = TextEditingController();

  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _signInWithApple() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      await widget.authService.signInWithApple(
        credential.identityToken!,
        credential.email,
      );
      widget.onLoggedIn();
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      setState(() => _error = l10n.loginAppleSignInFailedWithDetail(e.toString()));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      switch (_mode) {
        case _Mode.signIn:
          await widget.authService.signIn(
            _emailController.text.trim(),
            _passwordController.text,
          );
          widget.onLoggedIn();
        case _Mode.signUp:
          await widget.authService.signUp(
            _emailController.text.trim(),
            _passwordController.text,
          );
          setState(() => _mode = _Mode.confirm);
        case _Mode.confirm:
          await widget.authService.confirmSignUp(
            _emailController.text.trim(),
            _codeController.text.trim(),
          );
          // Doğrulama sonrası otomatik giriş dene
          await widget.authService.signIn(
            _emailController.text.trim(),
            _passwordController.text,
          );
          widget.onLoggedIn();
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // 1. Tam ekran, sessiz, döngüde oynayan video arka plan.
          const Positioned.fill(
            child: LoopingVideoBackground(assetPath: 'assets/videos/login-bg.mp4'),
          ),
          // 2. Video -> okunabilirlik için koyu gölge (scrim). Üst kısım
          // daha açık (video görünsün), alt yarı (form alanı) neredeyse
          // tamamen opak -- metinler/inputlar her koşulda net okunsun.
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.0, 0.38, 0.62, 1.0],
                  colors: [
                    Color(0x55000000),
                    Color(0x991A1030),
                    Color(0xE60A0A12),
                    Color(0xFF0A0A12),
                  ],
                ),
              ),
            ),
          ),
          // 3. İçerik: başlık (üst yarı, video üzerinde) + form (alt yarı).
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 48),
                  // Kısa, ilham verici başlık -- video'nun görünür kaldığı
                  // üst bölgede, referans tasarımdaki gibi.
                  Text(
                    l10n.loginHeadline,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w700,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 180),
                  ShaderMask(
                    shaderCallback: (bounds) =>
                        AppColors.primaryGradient.createShader(bounds),
                    child: const Text(
                      'Melodia Studio',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _titleFor(l10n, _mode),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 32),
                  if (_mode != _Mode.confirm) ...[
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: l10n.loginEmailLabel,
                        prefixIcon: const Icon(Icons.email_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: l10n.loginPasswordLabel,
                        prefixIcon: const Icon(Icons.lock_outline),
                      ),
                    ),
                  ] else ...[
                    Text(
                      l10n.loginConfirmCodeSentTo(_emailController.text),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _codeController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 24, letterSpacing: 8),
                      decoration: InputDecoration(
                        labelText: l10n.loginVerificationCodeLabel,
                      ),
                    ),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  ],
                  const SizedBox(height: 24),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: _loading ? null : _submit,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: _loading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    _buttonLabelFor(l10n, _mode),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_mode != _Mode.confirm &&
                      !kIsWeb &&
                      defaultTargetPlatform == TargetPlatform.iOS) ...[
                    Row(
                      children: [
                        const Expanded(
                          child: Divider(color: AppColors.border),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            l10n.loginOr,
                            style: const TextStyle(color: AppColors.textMuted),
                          ),
                        ),
                        const Expanded(
                          child: Divider(color: AppColors.border),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 50,
                      child: SignInWithAppleButton(
                        onPressed: _loading ? () {} : _signInWithApple,
                        style: SignInWithAppleButtonStyle.white,
                        borderRadius: BorderRadius.circular(16),
                        text: l10n.loginSignInWithApple,
                      ),
                    ),
                  ],
                  if (_mode != _Mode.confirm)
                    TextButton(
                      onPressed: _loading
                          ? null
                          : () => setState(() {
                                _error = null;
                                _mode = _mode == _Mode.signIn
                                    ? _Mode.signUp
                                    : _Mode.signIn;
                              }),
                      child: Text(
                        _mode == _Mode.signIn
                            ? l10n.loginNoAccount
                            : l10n.loginHaveAccount,
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _titleFor(AppLocalizations l10n, _Mode mode) {
    switch (mode) {
      case _Mode.signIn:
        return l10n.loginTitleSignIn;
      case _Mode.signUp:
        return l10n.loginTitleSignUp;
      case _Mode.confirm:
        return l10n.loginTitleConfirm;
    }
  }

  String _buttonLabelFor(AppLocalizations l10n, _Mode mode) {
    switch (mode) {
      case _Mode.signIn:
        return l10n.loginButtonSignIn;
      case _Mode.signUp:
        return l10n.loginButtonSignUp;
      case _Mode.confirm:
        return l10n.loginButtonConfirm;
    }
  }
}