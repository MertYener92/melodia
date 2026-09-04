import 'dart:convert';
import 'package:http/http.dart' as http;

/// AWS Cognito ile kayıt/giriş işlemlerini yöneten servis.
/// Ağır bir SDK (amplify_flutter) yerine doğrudan Cognito'nun
/// HTTP API'sini kullanır - daha az bağımlılık, daha kolay bakım.
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

  String get _endpoint =>
      'https://cognito-idp.$region.amazonaws.com/';

  String? _idToken;
  String? _refreshToken;

  String? get idToken => _idToken;
  bool get isLoggedIn => _idToken != null;

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

  /// Giriş yapar, başarılıysa idToken'ı hafızada tutar.
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
  }

  void signOut() {
    _idToken = null;
    _refreshToken = null;
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