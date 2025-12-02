/// K-Auth: 한국형 소셜 로그인 Flutter 라이브러리
///
/// 카카오, 네이버, 구글, 애플 OAuth를 Flutter에서 쉽게 구현할 수 있습니다.
///
/// ```dart
/// // 초기화
/// final kAuth = KAuth(
///   config: KAuthConfig(
///     kakao: KakaoConfig(appKey: 'YOUR_KAKAO_APP_KEY'),
///     naver: NaverConfig(
///       clientId: 'YOUR_NAVER_CLIENT_ID',
///       clientSecret: 'YOUR_NAVER_CLIENT_SECRET',
///       appName: 'Your App Name',
///     ),
///   ),
/// );
///
/// // 로그인
/// final result = await kAuth.signIn(AuthProvider.kakao);
/// if (result.success) {
///   print('로그인 성공: ${result.name}');
/// }
/// ```
library k_auth;

// Models
export 'models/auth_result.dart';
export 'models/auth_config.dart';

// Errors
export 'errors/k_auth_error.dart';

// Widgets
export 'widgets/login_buttons.dart';

// Main
import 'models/auth_config.dart';
import 'models/auth_result.dart';
import 'errors/k_auth_error.dart';
import 'providers/kakao_provider.dart';
import 'providers/naver_provider.dart';
import 'providers/google_provider.dart';
import 'providers/apple_provider.dart';

/// K-Auth 메인 클래스
///
/// 모든 소셜 로그인을 통합 관리합니다.
class KAuth {
  final KAuthConfig config;

  KakaoProvider? _kakaoProvider;
  NaverProvider? _naverProvider;
  GoogleProvider? _googleProvider;
  AppleProvider? _appleProvider;

  bool _initialized = false;

  KAuth({required this.config});

  /// KAuth 초기화
  ///
  /// 앱 시작 시 main() 또는 initState()에서 호출해야 합니다.
  void initialize() {
    if (_initialized) return;

    if (config.kakao != null) {
      _kakaoProvider = KakaoProvider(config.kakao!);
      _kakaoProvider!.initialize();
    }

    if (config.naver != null) {
      _naverProvider = NaverProvider(config.naver!);
    }

    if (config.google != null) {
      _googleProvider = GoogleProvider(config.google!);
    }

    if (config.apple != null) {
      _appleProvider = AppleProvider(config.apple!);
    }

    _initialized = true;
  }

  /// 소셜 로그인 실행
  ///
  /// [provider]에 따라 해당 소셜 로그인을 실행합니다.
  Future<AuthResult> signIn(AuthProvider provider) async {
    _ensureInitialized();

    switch (provider) {
      case AuthProvider.kakao:
        return _signInWithKakao();
      case AuthProvider.naver:
        return _signInWithNaver();
      case AuthProvider.google:
        return _signInWithGoogle();
      case AuthProvider.apple:
        return _signInWithApple();
    }
  }

  /// 카카오 로그인
  Future<AuthResult> signInWithKakao() async {
    _ensureInitialized();
    return _signInWithKakao();
  }

  /// 네이버 로그인
  Future<AuthResult> signInWithNaver() async {
    _ensureInitialized();
    return _signInWithNaver();
  }

  /// 구글 로그인
  Future<AuthResult> signInWithGoogle() async {
    _ensureInitialized();
    return _signInWithGoogle();
  }

  /// 애플 로그인
  Future<AuthResult> signInWithApple() async {
    _ensureInitialized();
    return _signInWithApple();
  }

  /// 로그아웃
  ///
  /// [provider]에 따라 해당 소셜 로그아웃을 실행합니다.
  Future<void> signOut(AuthProvider provider) async {
    _ensureInitialized();

    switch (provider) {
      case AuthProvider.kakao:
        await _kakaoProvider?.signOut();
        break;
      case AuthProvider.naver:
        await _naverProvider?.signOut();
        break;
      case AuthProvider.google:
        await _googleProvider?.signOut();
        break;
      case AuthProvider.apple:
        await _appleProvider?.signOut();
        break;
    }
  }

  /// 연결 해제 (탈퇴)
  ///
  /// [provider]에 따라 해당 소셜 연결을 해제합니다.
  Future<void> unlink(AuthProvider provider) async {
    _ensureInitialized();

    switch (provider) {
      case AuthProvider.kakao:
        await _kakaoProvider?.unlink();
        break;
      case AuthProvider.naver:
        await _naverProvider?.unlink();
        break;
      case AuthProvider.google:
        await _googleProvider?.unlink();
        break;
      case AuthProvider.apple:
        // 애플은 별도의 unlink API 없음
        break;
    }
  }

  // Private methods

  void _ensureInitialized() {
    if (!_initialized) {
      throw KAuthError(
        code: ErrorCodes.configNotFound,
        message: 'KAuth가 초기화되지 않았습니다. initialize()를 먼저 호출해주세요.',
      );
    }
  }

  Future<AuthResult> _signInWithKakao() async {
    if (_kakaoProvider == null) {
      return AuthResult.failure(
        provider: AuthProvider.kakao,
        errorMessage: ErrorMessages.getMessage(ErrorCodes.providerNotConfigured),
        errorCode: ErrorCodes.providerNotConfigured,
      );
    }
    return _kakaoProvider!.signIn();
  }

  Future<AuthResult> _signInWithNaver() async {
    if (_naverProvider == null) {
      return AuthResult.failure(
        provider: AuthProvider.naver,
        errorMessage: ErrorMessages.getMessage(ErrorCodes.providerNotConfigured),
        errorCode: ErrorCodes.providerNotConfigured,
      );
    }
    return _naverProvider!.signIn();
  }

  Future<AuthResult> _signInWithGoogle() async {
    if (_googleProvider == null) {
      return AuthResult.failure(
        provider: AuthProvider.google,
        errorMessage: ErrorMessages.getMessage(ErrorCodes.providerNotConfigured),
        errorCode: ErrorCodes.providerNotConfigured,
      );
    }
    return _googleProvider!.signIn();
  }

  Future<AuthResult> _signInWithApple() async {
    if (_appleProvider == null) {
      return AuthResult.failure(
        provider: AuthProvider.apple,
        errorMessage: ErrorMessages.getMessage(ErrorCodes.providerNotConfigured),
        errorCode: ErrorCodes.providerNotConfigured,
      );
    }
    return _appleProvider!.signIn();
  }
}
