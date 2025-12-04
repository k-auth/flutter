/// K-Auth: 한국 앱을 위한 소셜 로그인 SDK
///
/// 카카오, 네이버, 구글, 애플을 하나의 API로 구현하세요.
///
/// ## 기본 사용법
///
/// ```dart
/// // 초기화
/// final kAuth = KAuth(
///   config: KAuthConfig(
///     kakao: KakaoConfig(appKey: 'YOUR_KAKAO_APP_KEY'),
///     google: GoogleConfig(),
///   ),
/// );
/// kAuth.initialize();
///
/// // 로그인 (함수형 스타일)
/// final result = await kAuth.signIn(AuthProvider.kakao);
/// result.fold(
///   onSuccess: (user) => print('환영합니다, ${user.displayName}!'),
///   onFailure: (error) => print('로그인 실패: $error'),
/// );
///
/// // 로그아웃 (현재 로그인된 Provider로 자동)
/// await kAuth.signOut();
/// ```
///
/// ## 인증 상태 감지
///
/// ```dart
/// kAuth.authStateChanges.listen((user) {
///   if (user != null) {
///     print('로그인됨: ${user.displayName}');
///   } else {
///     print('로그아웃됨');
///   }
/// });
/// ```
///
/// ## 결과 처리 패턴
///
/// ```dart
/// // 체이닝
/// result
///   .onSuccess((user) => saveUser(user))
///   .onFailure((code, msg) => showError(msg));
///
/// // 성공/취소/실패 구분
/// result.when(
///   success: (user) => goToHome(),
///   cancelled: () => showToast('취소됨'),
///   failure: (code, msg) => showError(msg),
/// );
///
/// // 값 추출
/// final name = result.mapUserOr((u) => u.displayName, 'Guest');
/// ```
library;

// Models
export 'models/auth_result.dart';
export 'models/auth_config.dart';
export 'models/k_auth_user.dart';

// Errors
export 'errors/k_auth_error.dart';

// Utils
export 'utils/logger.dart';
export 'utils/diagnostic.dart';

// Widgets
export 'widgets/login_buttons.dart';

// Main
import 'dart:async';
import 'models/auth_config.dart';
import 'models/auth_result.dart';
import 'models/k_auth_user.dart';
import 'errors/k_auth_error.dart';
import 'utils/logger.dart';
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
  AuthResult? _lastResult;

  /// 인증 상태 변화 스트림 컨트롤러
  final _authStateController = StreamController<KAuthUser?>.broadcast();

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

  /// 현재 로그인된 사용자
  KAuthUser? get currentUser => _lastResult?.user;

  /// 로그인 여부
  bool get isSignedIn => _lastResult?.success == true && _lastResult?.user != null;

  /// 마지막 로그인 결과
  AuthResult? get lastResult => _lastResult;

  /// 현재 로그인된 Provider
  AuthProvider? get currentProvider =>
      isSignedIn ? _lastResult?.provider : null;

  /// 인증 상태 변화 스트림
  ///
  /// 로그인/로그아웃 시 사용자 정보가 변경됩니다.
  ///
  /// ```dart
  /// kAuth.authStateChanges.listen((user) {
  ///   if (user != null) {
  ///     print('로그인됨: ${user.displayName}');
  ///   } else {
  ///     print('로그아웃됨');
  ///   }
  /// });
  /// ```
  Stream<KAuthUser?> get authStateChanges => _authStateController.stream;

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
  ///
  /// ```dart
  /// final kAuth = KAuth(config: config);
  /// kAuth.initialize();
  /// ```
  void initialize() {
    if (_initialized) {
      KAuthLogger.debug('이미 초기화되어 있습니다');
      return;
    }

    KAuthLogger.info('K-Auth 초기화 시작', data: {
      'providers': config.configuredProviders,
      'validateOnInitialize': validateOnInitialize,
    });

    // 설정 검증
    if (validateOnInitialize) {
      final errors = config.validate();
      if (errors.isNotEmpty) {
        KAuthLogger.error(
          '설정 검증 실패',
          data: {'errors': errors.map((e) => e.code).toList()},
        );
        throw errors.first;
      }
    }

    if (config.kakao != null) {
      _kakaoProvider = KakaoProvider(config.kakao!);
      _kakaoProvider!.initialize();
      KAuthLogger.debug('카카오 Provider 초기화 완료', provider: 'kakao');
    }

    if (config.naver != null) {
      _naverProvider = NaverProvider(config.naver!);
      KAuthLogger.debug('네이버 Provider 초기화 완료', provider: 'naver');
    }

    if (config.google != null) {
      _googleProvider = GoogleProvider(config.google!);
      KAuthLogger.debug('구글 Provider 초기화 완료', provider: 'google');
    }

    if (config.apple != null) {
      _appleProvider = AppleProvider(config.apple!);
      KAuthLogger.debug('애플 Provider 초기화 완료', provider: 'apple');
    }

    _initialized = true;
    KAuthLogger.info('K-Auth 초기화 완료');
  }

  /// 소셜 로그인 실행
  ///
  /// [provider]에 따라 해당 소셜 로그인을 실행합니다.
  ///
  /// ## 반환값
  ///
  /// [AuthResult]를 반환합니다:
  /// - 성공 시: `result.success == true`, `result.user` 사용 가능
  /// - 실패 시: `result.success == false`, `result.errorMessage` 확인
  ///
  /// ## 사용 예시
  ///
  /// ```dart
  /// final result = await kAuth.signIn(AuthProvider.kakao);
  ///
  /// // 함수형 스타일
  /// result.fold(
  ///   onSuccess: (user) => print('환영합니다, ${user.displayName}!'),
  ///   onFailure: (error) => print('실패: $error'),
  /// );
  ///
  /// // 체이닝 스타일
  /// result
  ///   .onSuccess((user) => saveUser(user))
  ///   .onFailure((code, msg) => showError(msg));
  /// ```
  Future<AuthResult> signIn(AuthProvider provider) async {
    _ensureInitialized();

    KAuthLogger.info(
      '로그인 시작',
      provider: provider.name,
    );

    final stopwatch = Stopwatch()..start();

    final result = switch (provider) {
      AuthProvider.kakao => await _signInWithKakao(),
      AuthProvider.naver => await _signInWithNaver(),
      AuthProvider.google => await _signInWithGoogle(),
      AuthProvider.apple => await _signInWithApple(),
    };

    stopwatch.stop();

    if (result.success) {
      _lastResult = result;
      _authStateController.add(result.user);

      KAuthLogger.info(
        '로그인 성공',
        provider: provider.name,
        data: {
          'userId': result.user?.id,
          'hasEmail': result.user?.email != null,
          'duration': '${stopwatch.elapsedMilliseconds}ms',
        },
      );
    } else {
      KAuthLogger.warning(
        '로그인 실패',
        provider: provider.name,
        data: {
          'errorCode': result.errorCode,
          'errorMessage': result.errorMessage,
          'duration': '${stopwatch.elapsedMilliseconds}ms',
        },
      );
    }

    return result;
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
  ///
  /// [provider]를 생략하면 현재 로그인된 Provider로 로그아웃합니다.
  ///
  /// ```dart
  /// // 현재 로그인된 Provider로 로그아웃
  /// await kAuth.signOut();
  ///
  /// // 특정 Provider로 로그아웃
  /// await kAuth.signOut(AuthProvider.kakao);
  /// ```
  Future<void> signOut([AuthProvider? provider]) async {
    _ensureInitialized();

    // provider가 없으면 현재 로그인된 provider 사용
    final targetProvider = provider ?? currentProvider;
    if (targetProvider == null) {
      KAuthLogger.debug('로그아웃 스킵: 로그인된 상태가 아님');
      return;
    }

    KAuthLogger.info('로그아웃 시작', provider: targetProvider.name);

    switch (targetProvider) {
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

    if (_lastResult?.provider == targetProvider) {
      _lastResult = null;
      _authStateController.add(null);
    }

    KAuthLogger.info('로그아웃 완료', provider: targetProvider.name);
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

    _lastResult = null;
    _authStateController.add(null);
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

  /// 리소스 해제
  ///
  /// KAuth 인스턴스를 더 이상 사용하지 않을 때 호출하세요.
  /// StatefulWidget의 dispose()에서 호출하는 것을 권장합니다.
  ///
  /// ```dart
  /// @override
  /// void dispose() {
  ///   kAuth.dispose();
  ///   super.dispose();
  /// }
  /// ```
  void dispose() {
    _authStateController.close();
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
