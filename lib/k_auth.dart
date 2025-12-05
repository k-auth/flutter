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
export 'utils/session_storage.dart';

// Widgets
export 'widgets/login_buttons.dart';

// Main
import 'dart:async';
import 'models/auth_config.dart';
import 'models/auth_result.dart';
import 'models/k_auth_user.dart';
import 'errors/k_auth_error.dart';
import 'utils/logger.dart';
import 'utils/session_storage.dart';
import 'providers/kakao_provider.dart';
import 'providers/naver_provider.dart';
import 'providers/google_provider.dart';
import 'providers/apple_provider.dart';

/// 인증 토큰 정보
///
/// 백엔드 연동 콜백에서 사용됩니다.
class AuthTokens {
  /// 액세스 토큰
  final String? accessToken;

  /// 리프레시 토큰
  final String? refreshToken;

  /// ID 토큰 (OIDC, 구글/애플)
  final String? idToken;

  /// 토큰 만료 시간
  final DateTime? expiresAt;

  const AuthTokens({
    this.accessToken,
    this.refreshToken,
    this.idToken,
    this.expiresAt,
  });
}

/// 로그인 콜백 타입
///
/// 소셜 로그인 성공 후 호출됩니다.
/// 백엔드 서버에 토큰을 전송하고 JWT 등을 받아올 수 있습니다.
///
/// ```dart
/// onSignIn: (provider, tokens, user) async {
///   final jwt = await myApi.socialLogin(
///     provider: provider.name,
///     accessToken: tokens.accessToken,
///   );
///   return jwt;  // serverToken에 저장됨
/// }
/// ```
typedef OnSignInCallback = Future<String?> Function(
  AuthProvider provider,
  AuthTokens tokens,
  KAuthUser user,
);

/// 로그아웃 콜백 타입
///
/// 로그아웃 시 호출됩니다.
/// 백엔드 서버의 JWT 무효화 등에 사용할 수 있습니다.
///
/// ```dart
/// onSignOut: (provider) async {
///   await myApi.logout();
/// }
/// ```
typedef OnSignOutCallback = Future<void> Function(AuthProvider provider);

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
///
/// ## 백엔드 연동
///
/// ```dart
/// final kAuth = KAuth(
///   config: config,
///   onSignIn: (provider, tokens, user) async {
///     // 백엔드에 토큰 전송
///     final jwt = await myApi.socialLogin(
///       provider: provider.name,
///       accessToken: tokens.accessToken,
///     );
///     return jwt;  // serverToken으로 저장됨
///   },
///   onSignOut: (provider) async {
///     // 백엔드 JWT 무효화
///     await myApi.logout();
///   },
/// );
/// ```
///
/// ## 자동 로그인 (세션 복원)
///
/// ```dart
/// // SecureStorage 구현
/// class SecureSessionStorage implements KAuthSessionStorage {
///   final storage = FlutterSecureStorage();
///   Future<void> save(String key, String value) => storage.write(key: key, value: value);
///   Future<String?> read(String key) => storage.read(key: key);
///   Future<void> delete(String key) => storage.delete(key: key);
///   Future<void> clear() => storage.deleteAll();
/// }
///
/// // KAuth에 storage 설정
/// final kAuth = KAuth(
///   config: config,
///   storage: SecureSessionStorage(),
/// );
///
/// // 초기화 시 자동 복원
/// await kAuth.initialize(autoRestore: true);
///
/// if (kAuth.isSignedIn) {
///   // 이전 세션 복원됨!
///   print('자동 로그인: ${kAuth.currentUser?.displayName}');
/// }
/// ```
class KAuth {
  /// 설정
  final KAuthConfig config;

  /// 설정 검증 여부
  final bool validateOnInitialize;

  /// 로그인 콜백
  ///
  /// 소셜 로그인 성공 후 호출됩니다.
  /// 반환값은 [serverToken]에 저장됩니다.
  final OnSignInCallback? onSignIn;

  /// 로그아웃 콜백
  ///
  /// 로그아웃 시 호출됩니다.
  /// 백엔드 서버의 JWT 무효화 등에 사용할 수 있습니다.
  final OnSignOutCallback? onSignOut;

  /// 세션 저장소
  ///
  /// 자동 로그인을 위해 세션을 저장/복원합니다.
  final KAuthSessionStorage? storage;

  /// 세션 저장 키
  static const String _sessionKey = 'k_auth_session';

  KakaoProvider? _kakaoProvider;
  NaverProvider? _naverProvider;
  GoogleProvider? _googleProvider;
  AppleProvider? _appleProvider;

  bool _initialized = false;
  AuthResult? _lastResult;
  String? _serverToken;

  /// 인증 상태 변화 스트림 컨트롤러
  final _authStateController = StreamController<KAuthUser?>.broadcast();

  /// KAuth 인스턴스 생성
  ///
  /// [config]: Provider별 설정
  /// [validateOnInitialize]: initialize() 시 설정 검증 여부 (기본: true)
  /// [onSignIn]: 로그인 성공 콜백 (선택)
  /// [onSignOut]: 로그아웃 콜백 (선택)
  /// [storage]: 세션 저장소 (자동 로그인용, 선택)
  KAuth({
    required this.config,
    this.validateOnInitialize = true,
    this.onSignIn,
    this.onSignOut,
    this.storage,
  });

  /// 초기화 여부
  bool get isInitialized => _initialized;

  /// 현재 로그인된 사용자
  KAuthUser? get currentUser => _lastResult?.user;

  /// 로그인 여부
  bool get isSignedIn =>
      _lastResult?.success == true && _lastResult?.user != null;

  /// 마지막 로그인 결과
  AuthResult? get lastResult => _lastResult;

  /// 현재 로그인된 Provider
  AuthProvider? get currentProvider =>
      isSignedIn ? _lastResult?.provider : null;

  /// 서버 토큰 (백엔드에서 받은 JWT 등)
  ///
  /// [onAuthenticated] 콜백의 반환값이 저장됩니다.
  String? get serverToken => _serverToken;

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
  /// [autoRestore]가 true이면 저장된 세션을 자동으로 복원합니다.
  /// [storage]가 설정되어 있어야 동작합니다.
  ///
  /// ```dart
  /// final kAuth = KAuth(config: config, storage: myStorage);
  /// await kAuth.initialize(autoRestore: true);
  ///
  /// if (kAuth.isSignedIn) {
  ///   print('자동 로그인 성공!');
  /// }
  /// ```
  Future<void> initialize({bool autoRestore = false}) async {
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

    // 자동 로그인 (세션 복원)
    if (autoRestore && storage != null) {
      await _restoreSession();
    }
  }

  /// 세션 저장
  ///
  /// 로그인 성공 후 세션을 저장합니다.
  /// [storage]가 설정되어 있을 때만 동작합니다.
  Future<void> _saveSession(AuthResult result) async {
    if (storage == null || !result.success || result.user == null) return;

    try {
      final session = KAuthSession.fromAuthResult(
        result,
        serverToken: _serverToken,
      );
      await storage!.save(_sessionKey, session.encode());
      KAuthLogger.debug(
        '세션 저장 완료',
        provider: result.provider.name,
      );
    } catch (e) {
      KAuthLogger.error('세션 저장 실패', error: e);
    }
  }

  /// 세션 복원
  ///
  /// 저장된 세션을 복원합니다.
  /// 만료된 세션은 자동으로 삭제됩니다.
  Future<bool> _restoreSession() async {
    if (storage == null) return false;

    try {
      final encoded = await storage!.read(_sessionKey);
      if (encoded == null) {
        KAuthLogger.debug('저장된 세션 없음');
        return false;
      }

      final session = KAuthSession.decode(encoded);

      // 만료된 세션 처리
      if (session.isExpired) {
        KAuthLogger.debug('세션 만료됨, 삭제');
        await storage!.delete(_sessionKey);
        return false;
      }

      // 세션 복원
      _lastResult = AuthResult.success(
        provider: session.provider,
        user: session.user,
        accessToken: session.accessToken,
        refreshToken: session.refreshToken,
        idToken: session.idToken,
        expiresAt: session.expiresAt,
      );
      _serverToken = session.serverToken;
      _authStateController.add(session.user);

      KAuthLogger.info(
        '세션 복원 완료',
        provider: session.provider.name,
        data: {'userId': session.user.id},
      );

      return true;
    } catch (e) {
      KAuthLogger.error('세션 복원 실패', error: e);
      // 손상된 세션 삭제
      await storage!.delete(_sessionKey);
      return false;
    }
  }

  /// 세션 삭제
  ///
  /// 저장된 세션을 삭제합니다.
  /// 로그아웃 시 자동으로 호출됩니다.
  Future<void> clearSession() async {
    if (storage == null) return;

    try {
      await storage!.delete(_sessionKey);
      KAuthLogger.debug('세션 삭제 완료');
    } catch (e) {
      KAuthLogger.error('세션 삭제 실패', error: e);
    }
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

    if (result.success && result.user != null) {
      _lastResult = result;
      _authStateController.add(result.user);

      // 로그인 콜백 호출
      if (onSignIn != null) {
        try {
          final tokens = AuthTokens(
            accessToken: result.accessToken,
            refreshToken: result.refreshToken,
            idToken: result.idToken,
            expiresAt: result.expiresAt,
          );

          _serverToken = await onSignIn!(provider, tokens, result.user!);

          KAuthLogger.debug(
            '로그인 콜백 완료',
            provider: provider.name,
            data: {'hasServerToken': _serverToken != null},
          );
        } catch (e) {
          KAuthLogger.error(
            '로그인 콜백 실패',
            provider: provider.name,
            error: e,
          );
        }
      }

      // 세션 저장
      await _saveSession(result);

      KAuthLogger.info(
        '로그인 성공',
        provider: provider.name,
        data: {
          'userId': result.user?.id,
          'hasEmail': result.user?.email != null,
          'duration': '${stopwatch.elapsedMilliseconds}ms',
        },
      );
    } else if (!result.success) {
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
      // 로그아웃 콜백 호출
      if (onSignOut != null) {
        try {
          await onSignOut!(targetProvider);
          KAuthLogger.debug('로그아웃 콜백 완료', provider: targetProvider.name);
        } catch (e) {
          KAuthLogger.error('로그아웃 콜백 실패',
              provider: targetProvider.name, error: e);
        }
      }

      _lastResult = null;
      _serverToken = null;
      _authStateController.add(null);

      // 세션 삭제
      await clearSession();
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
    _serverToken = null;
    _authStateController.add(null);

    // 세션 삭제
    await clearSession();
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

  /// 토큰 갱신
  ///
  /// 현재 로그인된 Provider의 토큰을 갱신합니다.
  /// [provider]를 지정하면 해당 Provider의 토큰을 갱신합니다.
  ///
  /// ⚠️ Apple은 토큰 갱신을 지원하지 않습니다.
  ///
  /// ```dart
  /// // 현재 로그인된 Provider로 갱신
  /// final result = await kAuth.refreshToken();
  ///
  /// // 특정 Provider로 갱신
  /// final result = await kAuth.refreshToken(AuthProvider.kakao);
  ///
  /// result.fold(
  ///   onSuccess: (user) => print('토큰 갱신 성공'),
  ///   onFailure: (error) => print('토큰 갱신 실패: $error'),
  /// );
  /// ```
  Future<AuthResult> refreshToken([AuthProvider? provider]) async {
    _ensureInitialized();

    final targetProvider = provider ?? currentProvider;
    if (targetProvider == null) {
      final error = KAuthError.fromCode(ErrorCodes.providerNotConfigured);
      return AuthResult.failure(
        provider: AuthProvider.kakao, // 기본값
        errorMessage: error.message,
        errorCode: error.code,
        errorHint: '로그인된 상태가 아닙니다.',
      );
    }

    // Apple은 토큰 갱신 미지원
    if (!targetProvider.supportsTokenRefresh) {
      final error = KAuthError.fromCode(
        ErrorCodes.providerNotSupported,
        details: {'provider': targetProvider.name},
      );
      return AuthResult.failure(
        provider: targetProvider,
        errorMessage: '${targetProvider.displayName}은(는) 토큰 갱신을 지원하지 않습니다.',
        errorCode: error.code,
        errorHint: '다시 로그인해주세요.',
      );
    }

    KAuthLogger.info('토큰 갱신 시작', provider: targetProvider.name);

    final result = switch (targetProvider) {
      AuthProvider.kakao => await _kakaoProvider!.refreshToken(),
      AuthProvider.naver => await _naverProvider!.refreshToken(),
      AuthProvider.google => await _googleProvider!.refreshToken(),
      AuthProvider.apple => AuthResult.failure(
          provider: AuthProvider.apple,
          errorMessage: 'Apple은 토큰 갱신을 지원하지 않습니다.',
          errorCode: ErrorCodes.providerNotSupported,
        ),
    };

    if (result.success && result.user != null) {
      _lastResult = result;
      _authStateController.add(result.user);

      // 세션 저장
      await _saveSession(result);

      KAuthLogger.info('토큰 갱신 성공', provider: targetProvider.name);
    } else {
      KAuthLogger.warning(
        '토큰 갱신 실패',
        provider: targetProvider.name,
        data: {'errorCode': result.errorCode},
      );
    }

    return result;
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
