import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';

enum _Mode { signIn, signUp, confirm }

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
      setState(() => _error = 'Apple ile giriş başarısız: $e');
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
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGlow),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
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
                    _titleFor(_mode),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 32),
                  if (_mode != _Mode.confirm) ...[
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'E-posta',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Şifre (en az 8 karakter)',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                    ),
                  ] else ...[
                    Text(
                      '${_emailController.text} adresine gönderilen 6 haneli kodu girin.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _codeController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 24, letterSpacing: 8),
                      decoration: const InputDecoration(
                        labelText: 'Doğrulama kodu',
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
                                    _buttonLabelFor(_mode),
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
                  if (_mode != _Mode.confirm && Platform.isIOS) ...[
                    Row(
                      children: [
                        const Expanded(
                          child: Divider(color: AppColors.border),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'veya',
                            style: TextStyle(color: AppColors.textMuted),
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
                            ? 'Hesabın yok mu? Kayıt ol'
                            : 'Zaten hesabın var mı? Giriş yap',
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _titleFor(_Mode mode) {
    switch (mode) {
      case _Mode.signIn:
        return 'Devam etmek için giriş yap';
      case _Mode.signUp:
        return 'Yeni bir hesap oluştur';
      case _Mode.confirm:
        return 'E-postanı doğrula';
    }
  }

  String _buttonLabelFor(_Mode mode) {
    switch (mode) {
      case _Mode.signIn:
        return 'Giriş yap';
      case _Mode.signUp:
        return 'Kayıt ol';
      case _Mode.confirm:
        return 'Doğrula';
    }
  }
}