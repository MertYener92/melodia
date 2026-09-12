import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

/// AWS Cognito ile kayıt/giriş işlemlerini yöneten servis.
/// Ağır bir SDK (amplify_flutter) yerine doğrudan Cognito'nun
/// HTTP API'sini kullanır - daha az bağımlılık, daha kolay bakım.
///
/// Oturum kalıcılığı: refresh token, cihazın güvenli depolamasında
/// (iOS Keychain / Android Keystore) saklanır. Uygulama her açıldığında
/// [tryRestoreSession] çağrılarak, kullanıcıya tekrar e-posta/şifre
/// sormadan sessizce yeni bir idToken alınmaya çalışılır.
class AuthService {
  AuthService({
    required this.userPoolClientId,
    required this.region,
    required this.backendUrl,
  });

  final String userPoolClientId;
  final String region;

  /// Apple ile giriş, backend'deki /auth/apple endpoint'inden geçer.
  final String backendUrl;

  static const _storage = FlutterSecureStorage();
  static const _refreshTokenKey = 'melodia_refresh_token';

  String get _endpoint => 'https://cognito-idp.$region.amazonaws.com/';

  String? _idToken;
  String? _refreshToken;

  String? get idToken => _idToken;
  bool get isLoggedIn => _idToken != null;

  /// idToken içindeki 'sub' (Cognito kullanıcı ID'si — sabit bir UUID)
  /// claim'ini çözer. Apple satın alma isteklerinde appAccountToken
  /// olarak gönderilir; backend (verifySubscription.js) gelen makbuzun
  /// bu ID ile eşleştiğini doğrular.
  String? get userId {
    final token = _idToken;
    if (token == null) return null;
    final parts = token.split('.');
    if (parts.length != 3) return null;
    try {
      final normalized = base64Url.normalize(parts[1]);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final map = jsonDecode(decoded) as Map<String, dynamic>;
      return map['sub']?.toString();
    } catch (_) {
      return null;
    }
  }

  /// Yeni kullanıcı kaydı oluşturur (email doğrulama kodu gönderilir).
  Future<void> signUp(String email, String password) async {
    final response = await http.post(
      Uri.parse(_endpoint),
      headers: {
        'Content-Type': 'application/x-amz-json-1.1',
        'X-Amz-Target': 'AWSCognitoIdentityProviderService.SignUp',
      },
      body: jsonEncode({
        'ClientId': userPoolClientId,
        'Username': email,
        'Password': password,
        'UserAttributes': [
          {'Name': 'email', 'Value': email},
        ],
      }),
    );
    _throwIfError(response);
  }

  /// Kullanıcının e-postasına gelen 6 haneli doğrulama kodunu onaylar.
  Future<void> confirmSignUp(String email, String code) async {
    final response = await http.post(
      Uri.parse(_endpoint),
      headers: {
        'Content-Type': 'application/x-amz-json-1.1',
        'X-Amz-Target':
            'AWSCognitoIdentityProviderService.ConfirmSignUp',
      },
      body: jsonEncode({
        'ClientId': userPoolClientId,
        'Username': email,
        'ConfirmationCode': code,
      }),
    );
    _throwIfError(response);
  }

  /// Giriş yapar, başarılıysa idToken'ı hafızada, refreshToken'ı
  /// cihazın güvenli depolamasında (kalıcı) tutar.
  Future<void> signIn(String email, String password) async {
    final response = await http.post(
      Uri.parse(_endpoint),
      headers: {
        'Content-Type': 'application/x-amz-json-1.1',
        'X-Amz-Target':
            'AWSCognitoIdentityProviderService.InitiateAuth',
      },
      body: jsonEncode({
        'AuthFlow': 'USER_PASSWORD_AUTH',
        'ClientId': userPoolClientId,
        'AuthParameters': {
          'USERNAME': email,
          'PASSWORD': password,
        },
      }),
    );
    _throwIfError(response);

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final result = body['AuthenticationResult'] as Map<String, dynamic>;
    _idToken = result['IdToken'] as String;
    _refreshToken = result['RefreshToken'] as String?;
    await _persistRefreshToken(_refreshToken);
  }

  /// Uygulama her açıldığında çağrılır. Cihazda kayıtlı bir refresh
  /// token varsa onunla sessizce yeni bir idToken almayı dener.
  /// Başarılıysa true döner (kullanıcıya login ekranı gösterilmez).
  Future<bool> tryRestoreSession() async {
    final refreshToken = await _storage.read(key: _refreshTokenKey);
    if (refreshToken == null) return false;

    try {
      final response = await http.post(
        Uri.parse(_endpoint),
        headers: {
          'Content-Type': 'application/x-amz-json-1.1',
          'X-Amz-Target':
              'AWSCognitoIdentityProviderService.InitiateAuth',
        },
        body: jsonEncode({
          'AuthFlow': 'REFRESH_TOKEN_AUTH',
          'ClientId': userPoolClientId,
          'AuthParameters': {'REFRESH_TOKEN': refreshToken},
        }),
      );

      if (response.statusCode != 200) {
        // Refresh token süresi dolmuş/geçersiz olabilir, temizle.
        await _storage.delete(key: _refreshTokenKey);
        return false;
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final result = body['AuthenticationResult'] as Map<String, dynamic>;
      _idToken = result['IdToken'] as String;
      // Cognito, REFRESH_TOKEN_AUTH akışında genelde yeni bir refresh
      // token döndürmez; mevcut olanı kullanmaya devam ediyoruz.
      _refreshToken = refreshToken;
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> signOut() async {
    _idToken = null;
    _refreshToken = null;
    await _storage.delete(key: _refreshTokenKey);
  }

  /// Apple'dan gelen native identityToken'ı backend'e gönderir,
  /// backend Apple token'ını doğrulayıp Cognito oturumu döndürür.
  Future<void> signInWithApple(String identityToken, String? email) async {
    final response = await http.post(
      Uri.parse('$backendUrl/auth/apple'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'identityToken': identityToken,
        if (email != null) 'email': email,
      }),
    );

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      throw AuthException(
        body['error']?.toString() ?? 'Apple ile giriş başarısız oldu.',
      );
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    _idToken = body['idToken'] as String;
    _refreshToken = body['refreshToken'] as String?;
    await _persistRefreshToken(_refreshToken);
  }

  Future<void> _persistRefreshToken(String? token) async {
    if (token == null) return;
    await _storage.write(key: _refreshTokenKey, value: token);
  }

  void _throwIfError(http.Response response) {
    if (response.statusCode != 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      throw AuthException(
        _friendlyMessage(body['__type']?.toString(), body['message']?.toString()),
      );
    }
  }

  String _friendlyMessage(String? type, String? raw) {
    switch (type) {
      case 'UsernameExistsException':
        return 'Bu e-posta ile zaten bir hesap var.';
      case 'NotAuthorizedException':
        return 'E-posta veya şifre hatalı.';
      case 'UserNotConfirmedException':
        return 'Hesabınız henüz doğrulanmamış. E-postanıza gelen kodu girin.';
      case 'CodeMismatchException':
        return 'Doğrulama kodu hatalı.';
      case 'InvalidPasswordException':
        return 'Şifre en az 8 karakter olmalı.';
      default:
        return raw ?? 'Bilinmeyen bir hata oluştu.';
    }
  }
}

class AuthException implements Exception {
  AuthException(this.message);
  final String message;
  @override
  String toString() => message;
}