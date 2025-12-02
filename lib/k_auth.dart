/// K-Auth: 한국형 소셜 로그인 Flutter 라이브러리
///
/// 카카오, 네이버, 구글, 애플 OAuth를 Flutter에서 쉽게 구현할 수 있습니다.
///
/// ```dart
/// // 초기화
/// final kAuth = KAuth(
///   config: KAuthConfig(
///     kakao: KakaoConfig(
///       appKey: 'YOUR_KAKAO_APP_KEY',
///       collect: KakaoCollectOptions(
///         email: true,
///         phone: true,
///       ),
///     ),
///     naver: NaverConfig(
///       clientId: 'YOUR_NAVER_CLIENT_ID',
///       clientSecret: 'YOUR_NAVER_CLIENT_SECRET',
///       appName: 'Your App Name',
///     ),
///   ),
/// );
/// kAuth.initialize();
///
/// // 로그인
/// final result = await kAuth.signIn(AuthProvider.kakao);
/// if (result.success) {
///   final user = result.user!;
///   print('로그인 성공: ${user.name}');
///   print('이메일: ${user.email}');
/// }
/// ```
library;

// Models
export 'models/auth_result.dart';
export 'models/auth_config.dart';
export 'models/k_auth_user.dart';

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
///
/// ## 사용 예시
///
/// ```dart
/// // 1. 인스턴스 생성
/// final kAuth = KAuth(
///   config: KAuthConfig(
///     kakao: KakaoConfig(appKey: 'YOUR_APP_KEY'),
///     google: GoogleConfig(),
///   ),
/// );
///
/// // 2. 초기화 (앱 시작 시 1회)
/// kAuth.initialize();
///
/// // 3. 로그인
/// final result = await kAuth.signIn(AuthProvider.kakao);
///
/// // 4. 결과 처리
/// if (result.success) {
///   print('환영합니다, ${result.user?.displayName}님!');
/// } else {
///   print('로그인 실패: ${result.errorMessage}');
/// }
/// ```
class KAuth {
  /// 설정
  final KAuthConfig config;

  /// 설정 검증 여부
  final bool validateOnInitialize;

  KakaoProvider? _kakaoProvider;
  NaverProvider? _naverProvider;
  GoogleProvider? _googleProvider;
  AppleProvider? _appleProvider;

  bool _initialized = false;

  /// KAuth 인스턴스 생성
  ///
  /// [config]: Provider별 설정
  /// [validateOnInitialize]: initialize() 시 설정 검증 여부 (기본: true)
  KAuth({
    required this.config,
    this.validateOnInitialize = true,
  });

  /// 초기화 여부
  bool get isInitialized => _initialized;

  /// 설정된 Provider 목록
  List<AuthProvider> get configuredProviders {
    final providers = <AuthProvider>[];
    if (config.kakao != null) providers.add(AuthProvider.kakao);
    if (config.naver != null) providers.add(AuthProvider.naver);
    if (config.google != null) providers.add(AuthProvider.google);
    if (config.apple != null) providers.add(AuthProvider.apple);
    return providers;
  }

  /// KAuth 초기화
  ///
  /// 앱 시작 시 main() 또는 initState()에서 호출해야 합니다.
  ///
  /// [validateOnInitialize]가 true이면 설정을 검증하고,
  /// 설정이 유효하지 않으면 [KAuthError]를 던집니다.
  void initialize() {
    if (_initialized) return;

    // 설정 검증
    if (validateOnInitialize) {
      config.validate(throwOnError: true);
    }

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
  ///
  /// 반환값: [AuthResult]
  /// - 성공 시: `result.success == true`, `result.user` 사용 가능
  /// - 실패 시: `result.success == false`, `result.errorMessage` 확인
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
  /// 세션만 종료되며, 앱 연결은 유지됩니다.
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

  /// 모든 Provider 로그아웃
  Future<void> signOutAll() async {
    _ensureInitialized();

    await Future.wait([
      if (_kakaoProvider != null) _kakaoProvider!.signOut(),
      if (_naverProvider != null) _naverProvider!.signOut(),
      if (_googleProvider != null) _googleProvider!.signOut(),
      if (_appleProvider != null) _appleProvider!.signOut(),
    ]);
  }

  /// 연결 해제 (탈퇴)
  ///
  /// [provider]에 따라 해당 소셜 연결을 해제합니다.
  /// 연결 해제 후에는 다시 로그인해야 합니다.
  ///
  /// ⚠️ 주의: Apple은 클라이언트에서 연결 해제를 지원하지 않습니다.
  /// Apple 계정 연결 해제는 서버에서 처리해야 합니다.
  Future<void> unlink(AuthProvider provider) async {
    _ensureInitialized();

    if (!provider.supportsUnlink) {
      throw KAuthError.fromCode(
        ErrorCodes.providerNotSupported,
        details: {
          'provider': provider.name,
          'reason': '${provider.displayName}은(는) 클라이언트에서 연결 해제를 지원하지 않습니다.',
        },
      );
    }

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
        // Apple은 서버사이드에서만 revoke 가능
        break;
    }
  }

  /// Provider가 설정되어 있는지 확인
  bool isConfigured(AuthProvider provider) {
    switch (provider) {
      case AuthProvider.kakao:
        return config.kakao != null;
      case AuthProvider.naver:
        return config.naver != null;
      case AuthProvider.google:
        return config.google != null;
      case AuthProvider.apple:
        return config.apple != null;
    }
  }

  // ============================================
  // Private methods
  // ============================================

  void _ensureInitialized() {
    if (!_initialized) {
      throw KAuthError.fromCode(ErrorCodes.configNotFound);
    }
  }

  Future<AuthResult> _signInWithKakao() async {
    if (_kakaoProvider == null) {
      final error = KAuthError.fromCode(
        ErrorCodes.providerNotConfigured,
        details: {'provider': 'kakao'},
      );
      return AuthResult.failure(
        provider: AuthProvider.kakao,
        errorMessage: error.message,
        errorCode: error.code,
        errorHint: error.hint,
      );
    }
    return _kakaoProvider!.signIn();
  }

  Future<AuthResult> _signInWithNaver() async {
    if (_naverProvider == null) {
      final error = KAuthError.fromCode(
        ErrorCodes.providerNotConfigured,
        details: {'provider': 'naver'},
      );
      return AuthResult.failure(
        provider: AuthProvider.naver,
        errorMessage: error.message,
        errorCode: error.code,
        errorHint: error.hint,
      );
    }
    return _naverProvider!.signIn();
  }

  Future<AuthResult> _signInWithGoogle() async {
    if (_googleProvider == null) {
      final error = KAuthError.fromCode(
        ErrorCodes.providerNotConfigured,
        details: {'provider': 'google'},
      );
      return AuthResult.failure(
        provider: AuthProvider.google,
        errorMessage: error.message,
        errorCode: error.code,
        errorHint: error.hint,
      );
    }
    return _googleProvider!.signIn();
  }

  Future<AuthResult> _signInWithApple() async {
    if (_appleProvider == null) {
      final error = KAuthError.fromCode(
        ErrorCodes.providerNotConfigured,
        details: {'provider': 'apple'},
      );
      return AuthResult.failure(
        provider: AuthProvider.apple,
        errorMessage: error.message,
        errorCode: error.code,
        errorHint: error.hint,
      );
    }
    return _appleProvider!.signIn();
  }
}
