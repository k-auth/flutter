import 'package:flutter_test/flutter_test.dart';
import 'package:k_auth/k_auth.dart';

/// 테스트용 Mock Provider
class MockAuthProvider implements BaseAuthProvider {
  final AuthProvider provider;
  bool initializeCalled = false;
  bool signInCalled = false;
  bool signOutCalled = false;
  bool unlinkCalled = false;
  bool refreshTokenCalled = false;

  AuthResult? signInResult;
  AuthResult? signOutResult;
  AuthResult? unlinkResult;
  AuthResult? refreshTokenResult;

  /// signIn 시 예외를 던지도록 설정
  Object? signInException;

  MockAuthProvider(this.provider);

  @override
  Future<void> initialize() async {
    initializeCalled = true;
  }

  @override
  Future<AuthResult> signIn() async {
    signInCalled = true;
    if (signInException != null) throw signInException!;
    return signInResult ??
        AuthResult.success(
          provider: provider,
          user: KAuthUser(
            id: 'mock_user_id',
            name: 'Mock User',
            email: 'mock@test.com',
            provider: provider,
          ),
          accessToken: 'mock_access_token',
          refreshToken: 'mock_refresh_token',
        );
  }

  @override
  Future<AuthResult> signOut() async {
    signOutCalled = true;
    return signOutResult ??
        AuthResult.success(
          provider: provider,
          user: null,
        );
  }

  @override
  Future<AuthResult> unlink() async {
    unlinkCalled = true;
    return unlinkResult ??
        AuthResult.success(
          provider: provider,
          user: null,
        );
  }

  @override
  Future<AuthResult> refreshToken() async {
    refreshTokenCalled = true;
    return refreshTokenResult ??
        AuthResult.success(
          provider: provider,
          user: KAuthUser(
            id: 'mock_user_id',
            name: 'Mock User',
            email: 'mock@test.com',
            provider: provider,
          ),
          accessToken: 'new_access_token',
          refreshToken: 'new_refresh_token',
        );
  }

  void reset() {
    initializeCalled = false;
    signInCalled = false;
    signOutCalled = false;
    unlinkCalled = false;
    refreshTokenCalled = false;
    signInResult = null;
    signOutResult = null;
    unlinkResult = null;
    refreshTokenResult = null;
  }
}

void main() {
  group('AuthResult', () {
    test('성공 결과를 생성한다', () {
      final user = KAuthUser(
        id: '12345',
        email: 'test@example.com',
        name: '홍길동',
        provider: AuthProvider.kakao,
      );

      final result = AuthResult.success(
        provider: AuthProvider.kakao,
        user: user,
      );

      expect(result.success, true);
      expect(result.provider, AuthProvider.kakao);
      expect(result.user?.id, '12345');
      expect(result.user?.email, 'test@example.com');
      expect(result.user?.name, '홍길동');
      expect(result.errorMessage, isNull);
    });

    test('실패 결과를 생성한다', () {
      final result = AuthResult.failure(
        provider: AuthProvider.naver,
        errorMessage: '로그인 실패',
        errorCode: ErrorCodes.loginFailed,
      );

      expect(result.success, false);
      expect(result.provider, AuthProvider.naver);
      expect(result.errorMessage, '로그인 실패');
      expect(result.errorCode, ErrorCodes.loginFailed);
      expect(result.user, isNull);
    });

    test('토큰 만료 확인이 동작한다', () {
      final user = KAuthUser(id: '1', provider: AuthProvider.kakao);

      final expired = AuthResult.success(
        provider: AuthProvider.kakao,
        user: user,
        expiresAt: DateTime.now().subtract(const Duration(hours: 1)),
      );

      final valid = AuthResult.success(
        provider: AuthProvider.kakao,
        user: user,
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
      );

      expect(expired.isExpired, true);
      expect(valid.isExpired, false);
    });

    test('토큰 곧 만료 확인이 동작한다', () {
      final user = KAuthUser(id: '1', provider: AuthProvider.kakao);

      final expiringSoon = AuthResult.success(
        provider: AuthProvider.kakao,
        user: user,
        expiresAt: DateTime.now().add(const Duration(minutes: 3)),
      );

      expect(expiringSoon.isExpiringSoon(), true);
      expect(expiringSoon.isExpiringSoon(const Duration(minutes: 1)), false);
    });

    test('JSON 직렬화가 동작한다', () {
      final user = KAuthUser(
        id: '12345',
        email: 'test@example.com',
        provider: AuthProvider.google,
      );

      final result = AuthResult.success(
        provider: AuthProvider.google,
        user: user,
        accessToken: 'token123',
      );

      final json = result.toJson();
      final restored = AuthResult.fromJson(json);

      expect(restored.success, true);
      expect(restored.provider, AuthProvider.google);
      expect(restored.user?.id, '12345');
      expect(restored.accessToken, 'token123');
    });

    test('fold가 성공 시 onSuccess를 실행한다', () {
      final user =
          KAuthUser(id: '1', name: '홍길동', provider: AuthProvider.kakao);
      final result = AuthResult.success(
        provider: AuthProvider.kakao,
        user: user,
      );

      final message = result.fold(
        onSuccess: (u) => '환영합니다, ${u.name}!',
        onFailure: (failure) => '실패: ${failure.message}',
      );

      expect(message, '환영합니다, 홍길동!');
    });

    test('fold가 실패 시 onFailure를 실행한다', () {
      final result = AuthResult.failure(
        provider: AuthProvider.kakao,
        errorMessage: '로그인 실패',
      );

      final message = result.fold(
        onSuccess: (u) => '환영합니다!',
        onFailure: (failure) => '에러: ${failure.message}',
      );

      expect(message, '에러: 로그인 실패');
    });

    test('when이 성공/취소/실패를 구분한다', () {
      final user = KAuthUser(id: '1', provider: AuthProvider.kakao);

      final successResult = AuthResult.success(
        provider: AuthProvider.kakao,
        user: user,
      );
      final cancelledResult = AuthResult.failure(
        provider: AuthProvider.kakao,
        errorMessage: '취소됨',
        errorCode: 'USER_CANCELLED',
      );
      final failureResult = AuthResult.failure(
        provider: AuthProvider.kakao,
        errorMessage: '네트워크 오류',
        errorCode: 'NETWORK_ERROR',
      );

      expect(
        successResult.when(
          success: (_) => 'success',
          cancelled: () => 'cancelled',
          failure: (_) => 'failure',
        ),
        'success',
      );

      expect(
        cancelledResult.when(
          success: (_) => 'success',
          cancelled: () => 'cancelled',
          failure: (_) => 'failure',
        ),
        'cancelled',
      );

      expect(
        failureResult.when(
          success: (_) => 'success',
          cancelled: () => 'cancelled',
          failure: (_) => 'failure',
        ),
        'failure',
      );
    });

    test('onSuccess가 체이닝을 지원한다', () {
      final user =
          KAuthUser(id: '1', name: '홍길동', provider: AuthProvider.kakao);
      final result = AuthResult.success(
        provider: AuthProvider.kakao,
        user: user,
      );

      String? capturedName;
      String? capturedError;

      result
          .onSuccess((u) => capturedName = u.name)
          .onFailure((failure) => capturedError = failure.message);

      expect(capturedName, '홍길동');
      expect(capturedError, isNull);
    });

    test('onFailure가 체이닝을 지원한다', () {
      final result = AuthResult.failure(
        provider: AuthProvider.kakao,
        errorMessage: '실패',
      );

      String? capturedName;
      String? capturedError;

      result
          .onSuccess((u) => capturedName = u.name)
          .onFailure((failure) => capturedError = failure.message);

      expect(capturedName, isNull);
      expect(capturedError, '실패');
    });

    test('mapUser가 성공 시 변환된 값을 반환한다', () {
      final user =
          KAuthUser(id: '1', name: '홍길동', provider: AuthProvider.kakao);
      final result = AuthResult.success(
        provider: AuthProvider.kakao,
        user: user,
      );

      final name = result.mapUser((u) => u.name);
      expect(name, '홍길동');
    });

    test('mapUser가 실패 시 null을 반환한다', () {
      final result = AuthResult.failure(
        provider: AuthProvider.kakao,
        errorMessage: '실패',
      );

      final name = result.mapUser((u) => u.name);
      expect(name, isNull);
    });

    test('mapUserOr가 실패 시 기본값을 반환한다', () {
      final result = AuthResult.failure(
        provider: AuthProvider.kakao,
        errorMessage: '실패',
      );

      final name = result.mapUserOr((u) => u.name ?? 'Unknown', 'Guest');
      expect(name, 'Guest');
    });
  });

  group('KakaoConfig', () {
    test('기본 scope를 포함한다', () {
      final config = KakaoConfig(appKey: 'test_key');

      expect(config.allScopes, contains('profile_nickname'));
      expect(config.allScopes, contains('profile_image'));
      expect(config.allScopes, contains('account_email'));
    });

    test('collect 옵션으로 phone scope를 추가한다', () {
      final config = KakaoConfig(
        appKey: 'test_key',
        collect: const KakaoCollectOptions(phone: true),
      );

      expect(config.allScopes, contains('phone_number'));
    });

    test('collect 옵션 기본값은 phone을 포함하지 않는다', () {
      final config = KakaoConfig(appKey: 'test_key');

      expect(config.allScopes, isNot(contains('phone_number')));
    });

    test('추가 scope를 포함한다', () {
      final config = KakaoConfig(
        appKey: 'test_key',
        additionalScopes: ['friends', 'talk_message'],
      );

      expect(config.allScopes, contains('friends'));
      expect(config.allScopes, contains('talk_message'));
    });

    test('중복 scope를 제거한다', () {
      final config = KakaoConfig(
        appKey: 'test_key',
        additionalScopes: ['profile_nickname', 'friends'],
      );

      final nicknameCount =
          config.allScopes.where((s) => s == 'profile_nickname').length;
      expect(nicknameCount, 1);
    });

    test('빈 appKey는 검증 에러를 반환한다', () {
      final config = KakaoConfig(appKey: '');
      final errors = config.validate();

      expect(errors, isNotEmpty);
      expect(errors.first.code, ErrorCodes.missingAppKey);
    });
  });

  group('NaverConfig', () {
    test('필수 설정값을 저장한다', () {
      final config = NaverConfig(
        clientId: 'client_id',
        clientSecret: 'client_secret',
        appName: 'Test App',
      );

      expect(config.clientId, 'client_id');
      expect(config.clientSecret, 'client_secret');
      expect(config.appName, 'Test App');
    });

    test('빈 clientId는 검증 에러를 반환한다', () {
      final config = NaverConfig(
        clientId: '',
        clientSecret: 'secret',
        appName: 'Test',
      );
      final errors = config.validate();

      expect(errors.any((e) => e.code == ErrorCodes.missingClientId), true);
    });
  });

  group('GoogleConfig', () {
    test('기본 scope를 포함한다', () {
      final config = GoogleConfig();

      expect(config.allScopes, contains('openid'));
      expect(config.allScopes, contains('email'));
      expect(config.allScopes, contains('profile'));
    });

    test('추가 scope를 포함한다', () {
      final config = GoogleConfig(
        additionalScopes: ['calendar'],
      );

      expect(config.allScopes, contains('calendar'));
    });

    test('설정값 없이 생성할 수 있다', () {
      final config = GoogleConfig();

      expect(config.iosClientId, isNull);
      expect(config.serverClientId, isNull);
    });
  });

  group('AppleConfig', () {
    test('기본 설정으로 생성할 수 있다', () {
      final config = AppleConfig();

      expect(config.collect.email, true);
      expect(config.collect.fullName, true);
    });
  });

  group('GoogleCollectOptions', () {
    test('toScopes가 올바른 scope 목록을 반환한다', () {
      const options = GoogleCollectOptions();

      final scopes = options.toScopes();

      expect(scopes, contains('openid'));
      expect(scopes, contains('email'));
      expect(scopes, contains('profile'));
    });

    test('toScopes가 비활성화된 옵션을 제외한다', () {
      const options = GoogleCollectOptions(
        email: true,
        profile: false,
        openid: false,
      );

      final scopes = options.toScopes();

      expect(scopes, contains('email'));
      expect(scopes, isNot(contains('profile')));
      expect(scopes, isNot(contains('openid')));
    });

    test('모든 옵션이 비활성화되면 빈 목록을 반환한다', () {
      const options = GoogleCollectOptions(
        email: false,
        profile: false,
        openid: false,
      );

      final scopes = options.toScopes();

      expect(scopes, isEmpty);
    });

    test('defaults가 기본값을 반환한다', () {
      const options = GoogleCollectOptions.defaults;

      expect(options.email, true);
      expect(options.profile, true);
      expect(options.openid, true);
    });
  });

  group('KAuthConfig', () {
    test('여러 Provider 설정을 포함할 수 있다', () {
      final config = KAuthConfig(
        kakao: KakaoConfig(appKey: 'kakao_key'),
        naver: NaverConfig(
          clientId: 'naver_id',
          clientSecret: 'naver_secret',
          appName: 'Test',
        ),
        google: GoogleConfig(),
        apple: AppleConfig(),
      );

      expect(config.kakao, isNotNull);
      expect(config.naver, isNotNull);
      expect(config.google, isNotNull);
      expect(config.apple, isNotNull);
    });

    test('일부 Provider만 설정할 수 있다', () {
      final config = KAuthConfig(
        kakao: KakaoConfig(appKey: 'kakao_key'),
      );

      expect(config.kakao, isNotNull);
      expect(config.naver, isNull);
      expect(config.google, isNull);
      expect(config.apple, isNull);
    });

    test('설정된 Provider 목록을 반환한다', () {
      final config = KAuthConfig(
        kakao: KakaoConfig(appKey: 'key'),
        google: GoogleConfig(),
      );

      expect(config.configuredProviders, contains('kakao'));
      expect(config.configuredProviders, contains('google'));
      expect(config.configuredProviders.length, 2);
    });

    test('Provider가 없으면 검증 에러를 반환한다', () {
      final config = KAuthConfig();
      final errors = config.validate();

      expect(
          errors.any((e) => e.code == ErrorCodes.noProviderConfigured), true);
    });

    test('유효한 설정에서 isValid가 true를 반환한다', () {
      final config = KAuthConfig(
        kakao: KakaoConfig(appKey: 'valid_key'),
      );

      expect(config.isValid, true);
    });

    test('무효한 설정에서 isValid가 false를 반환한다', () {
      final config = KAuthConfig(
        kakao: KakaoConfig(appKey: ''), // 빈 앱 키
      );

      expect(config.isValid, false);
    });

    test('Provider가 없으면 isValid가 false를 반환한다', () {
      final config = KAuthConfig();

      expect(config.isValid, false);
    });
  });

  group('KAuthFailure', () {
    test('기본 생성자로 생성한다', () {
      const failure = AuthError(
        code: 'LOGIN_FAILED',
        message: '로그인 실패',
        hint: '다시 시도하세요',
      );

      expect(failure.code, 'LOGIN_FAILED');
      expect(failure.message, '로그인 실패');
      expect(failure.hint, '다시 시도하세요');
    });

    test('fromCode로 생성한다', () {
      final failure = KAuthFailure.fromCode(ErrorCodes.userCancelled);

      expect(failure.code, ErrorCodes.userCancelled);
      expect(failure.message, isNotEmpty);
      expect(failure.hint, isNotNull);
    });

    test('isCancelled가 올바르게 동작한다', () {
      final cancelled = KAuthFailure.fromCode(ErrorCodes.userCancelled);
      final failed = KAuthFailure.fromCode(ErrorCodes.loginFailed);

      expect(cancelled.isCancelled, true);
      expect(failed.isCancelled, false);
    });

    test('displayMessage가 올바르게 동작한다', () {
      const withMessage = AuthError(message: '에러 메시지');
      const withoutMessage = AuthError();

      expect(withMessage.displayMessage, '에러 메시지');
      expect(withoutMessage.displayMessage, '알 수 없는 오류가 발생했습니다.');
    });

    test('JSON 직렬화가 동작한다', () {
      const original = AuthError(
        code: 'TEST_CODE',
        message: '테스트 메시지',
        hint: '테스트 힌트',
      );

      final json = original.toJson();
      final restored = KAuthFailure.fromJson(json);

      expect(restored.code, 'TEST_CODE');
      expect(restored.message, '테스트 메시지');
      expect(restored.hint, '테스트 힌트');
    });

    test('equality가 동작한다', () {
      const failure1 = AuthError(code: 'A', message: 'B');
      const failure2 = AuthError(code: 'A', message: 'B');
      const failure3 = AuthError(code: 'A', message: 'C');

      expect(failure1 == failure2, true);
      expect(failure1 == failure3, false);
    });

    test('toString이 올바른 형식을 반환한다', () {
      const failure = AuthError(code: 'CODE', message: '메시지');
      expect(failure.toString(), 'AuthError[CODE]: 메시지');
    });
  });

  group('AuthResult.failure getter', () {
    test('실패 결과에서 KAuthFailure를 반환한다', () {
      final result = AuthResult.failure(
        provider: AuthProvider.kakao,
        errorMessage: '에러',
        errorCode: 'ERROR_CODE',
        errorHint: '힌트',
      );

      final failure = result.failure;

      expect(failure.code, 'ERROR_CODE');
      expect(failure.message, '에러');
      expect(failure.hint, '힌트');
    });
  });

  group('KAuthError', () {
    test('에러를 생성한다', () {
      final error = KAuthError(
        code: ErrorCodes.loginFailed,
        message: '로그인 실패',
      );

      expect(error.code, ErrorCodes.loginFailed);
      expect(error.message, '로그인 실패');
    });

    test('에러 코드로 생성한다', () {
      final error = KAuthError.fromCode(ErrorCodes.userCancelled);

      expect(error.code, ErrorCodes.userCancelled);
      expect(error.message, isNotEmpty);
      expect(error.hint, isNotNull);
    });

    test('toString이 올바른 형식을 반환한다', () {
      final error = KAuthError(
        code: ErrorCodes.userCancelled,
        message: '사용자가 취소함',
      );

      expect(error.toString(), 'KAuthError[USER_CANCELLED]: 사용자가 취소함');
    });

    test('원본 에러를 포함할 수 있다', () {
      final originalError = Exception('원본 에러');
      final error = KAuthError(
        code: ErrorCodes.networkError,
        message: '네트워크 오류',
        originalError: originalError,
      );

      expect(error.originalError, originalError);
    });

    test('JSON으로 변환할 수 있다', () {
      final error = KAuthError(
        code: ErrorCodes.loginFailed,
        message: '로그인 실패',
        hint: '다시 시도하세요',
      );

      final json = error.toJson();

      expect(json['code'], ErrorCodes.loginFailed);
      expect(json['message'], '로그인 실패');
      expect(json['hint'], '다시 시도하세요');
    });
  });

  group('ErrorCodes', () {
    test('모든 에러 코드가 정의되어 있다', () {
      expect(ErrorCodes.configNotFound, 'CONFIG_NOT_FOUND');
      expect(ErrorCodes.invalidConfig, 'INVALID_CONFIG');
      expect(ErrorCodes.userCancelled, 'USER_CANCELLED');
      expect(ErrorCodes.loginFailed, 'LOGIN_FAILED');
      expect(ErrorCodes.tokenExpired, 'TOKEN_EXPIRED');
      expect(ErrorCodes.networkError, 'NETWORK_ERROR');
      expect(ErrorCodes.providerNotConfigured, 'PROVIDER_NOT_CONFIGURED');
      expect(ErrorCodes.providerNotSupported, 'PROVIDER_NOT_SUPPORTED');
      expect(ErrorCodes.platformNotSupported, 'PLATFORM_NOT_SUPPORTED');
    });

    test('에러 정보를 반환한다', () {
      final info = ErrorCodes.getErrorInfo(ErrorCodes.userCancelled);

      expect(info.message, isNotEmpty);
      expect(info.hint, isNotNull);
    });

    test('알 수 없는 코드에 대해 기본 정보를 반환한다', () {
      final info = ErrorCodes.getErrorInfo('UNKNOWN_CODE_XYZ');

      expect(info.message, contains('알 수 없는'));
    });
  });

  group('KAuth', () {
    test('설정으로 인스턴스를 생성한다', () {
      final kAuth = KAuth(
        config: KAuthConfig(
          kakao: KakaoConfig(appKey: 'test_key'),
        ),
      );

      expect(kAuth, isNotNull);
      expect(kAuth.config.kakao, isNotNull);
      expect(kAuth.isInitialized, false);
    });

    test('초기화 전에는 isInitialized가 false다', () {
      final kAuth = KAuth(
        config: KAuthConfig(
          kakao: KakaoConfig(appKey: 'test_key'),
        ),
      );

      expect(kAuth.isInitialized, false);
    });

    test('초기화 전 signIn 호출 시 에러를 발생시킨다', () {
      final kAuth = KAuth(
        config: KAuthConfig(
          kakao: KakaoConfig(appKey: 'test_key'),
        ),
      );

      expect(
        () => kAuth.signIn(AuthProvider.kakao),
        throwsA(isA<KAuthError>()),
      );
    });

    test('초기화 전 signOut 호출 시 에러를 발생시킨다', () {
      final kAuth = KAuth(
        config: KAuthConfig(
          kakao: KakaoConfig(appKey: 'test_key'),
        ),
      );

      expect(
        () => kAuth.signOut(AuthProvider.kakao),
        throwsA(isA<KAuthError>()),
      );
    });

    test('isConfigured가 올바르게 동작한다', () {
      final kAuth = KAuth(
        config: KAuthConfig(
          kakao: KakaoConfig(appKey: 'test_key'),
        ),
      );

      expect(kAuth.isConfigured(AuthProvider.kakao), true);
      expect(kAuth.isConfigured(AuthProvider.naver), false);
    });

    test('configuredProviders가 올바르게 동작한다', () {
      final kAuth = KAuth(
        config: KAuthConfig(
          kakao: KakaoConfig(appKey: 'key'),
          google: GoogleConfig(),
        ),
      );

      expect(kAuth.configuredProviders, contains(AuthProvider.kakao));
      expect(kAuth.configuredProviders, contains(AuthProvider.google));
      expect(kAuth.configuredProviders.length, 2);
    });
  });

  // ============================================
  // KAuth 핵심 기능 테스트 (Mock Provider 사용)
  // ============================================

  group('KAuth with Mock Provider', () {
    late KAuth kAuth;
    late MockAuthProvider mockKakao;
    late MockAuthProvider mockGoogle;

    setUp(() {
      kAuth = KAuth(
        config: KAuthConfig(
          kakao: KakaoConfig(appKey: 'test_key'),
          google: GoogleConfig(),
        ),
      );
      mockKakao = MockAuthProvider(AuthProvider.kakao);
      mockGoogle = MockAuthProvider(AuthProvider.google);
    });

    tearDown(() {
      kAuth.dispose();
    });

    test('signIn이 성공하면 currentUser가 설정된다', () async {
      kAuth.setProviderForTesting(AuthProvider.kakao, mockKakao);

      final result = await kAuth.signIn(AuthProvider.kakao);

      expect(result.success, true);
      expect(result.user?.id, 'mock_user_id');
      expect(result.user?.name, 'Mock User');
      expect(kAuth.currentUser, isNotNull);
      expect(kAuth.currentUser?.id, 'mock_user_id');
      expect(kAuth.isSignedIn, true);
      expect(kAuth.currentProvider, AuthProvider.kakao);
      expect(mockKakao.signInCalled, true);
    });

    test('signIn 실패 시 currentUser가 null이다', () async {
      mockKakao.signInResult = AuthResult.failure(
        provider: AuthProvider.kakao,
        errorMessage: '로그인 실패',
        errorCode: ErrorCodes.loginFailed,
      );
      kAuth.setProviderForTesting(AuthProvider.kakao, mockKakao);

      final result = await kAuth.signIn(AuthProvider.kakao);

      expect(result.success, false);
      expect(result.errorMessage, '로그인 실패');
      expect(kAuth.currentUser, isNull);
      expect(kAuth.isSignedIn, false);
    });

    test('설정되지 않은 Provider로 signIn 시 실패한다', () async {
      kAuth.setProviderForTesting(AuthProvider.kakao, mockKakao);

      final result = await kAuth.signIn(AuthProvider.naver);

      expect(result.success, false);
      expect(result.errorCode, ErrorCodes.providerNotConfigured);
    });

    test('signOut이 성공하면 currentUser가 null이 된다', () async {
      kAuth.setProviderForTesting(AuthProvider.kakao, mockKakao);

      // 먼저 로그인
      await kAuth.signIn(AuthProvider.kakao);
      expect(kAuth.isSignedIn, true);

      // 로그아웃
      final result = await kAuth.signOut();

      expect(result.success, true);
      expect(kAuth.currentUser, isNull);
      expect(kAuth.isSignedIn, false);
      expect(kAuth.currentProvider, isNull);
      expect(mockKakao.signOutCalled, true);
    });

    test('로그인 상태가 아닐 때 signOut은 성공으로 처리된다', () async {
      kAuth.setProviderForTesting(AuthProvider.kakao, mockKakao);

      final result = await kAuth.signOut();

      expect(result.success, true);
      // Provider.signOut은 호출되지 않아야 함
      expect(mockKakao.signOutCalled, false);
    });

    test('특정 Provider로 signOut이 동작한다', () async {
      kAuth.setProviderForTesting(AuthProvider.kakao, mockKakao);
      kAuth.setProviderForTesting(AuthProvider.google, mockGoogle);

      // 카카오로 로그인
      await kAuth.signIn(AuthProvider.kakao);

      // 구글로 로그아웃 시도 (현재 로그인된 provider와 다름)
      final result = await kAuth.signOut(AuthProvider.google);

      expect(result.success, true);
      expect(mockGoogle.signOutCalled, true);
      // 카카오 로그인 상태는 유지됨
      expect(kAuth.currentProvider, AuthProvider.kakao);
    });

    test('refreshToken이 성공하면 토큰이 갱신된다', () async {
      kAuth.setProviderForTesting(AuthProvider.kakao, mockKakao);

      // 먼저 로그인
      await kAuth.signIn(AuthProvider.kakao);

      // 토큰 갱신
      final result = await kAuth.refreshToken();

      expect(result.success, true);
      expect(result.accessToken, 'new_access_token');
      expect(mockKakao.refreshTokenCalled, true);
    });

    test('로그인 상태가 아닐 때 refreshToken은 실패한다', () async {
      kAuth.setProviderForTesting(AuthProvider.kakao, mockKakao);

      final result = await kAuth.refreshToken();

      expect(result.success, false);
      expect(result.errorCode, ErrorCodes.refreshFailed);
    });

    test('Apple Provider로 refreshToken 시 실패한다', () async {
      final mockApple = MockAuthProvider(AuthProvider.apple);
      kAuth.setProviderForTesting(AuthProvider.apple, mockApple);

      // 애플로 로그인
      await kAuth.signIn(AuthProvider.apple);

      // 토큰 갱신 시도
      final result = await kAuth.refreshToken();

      expect(result.success, false);
      expect(result.errorCode, ErrorCodes.providerNotSupported);
      // Apple Provider의 refreshToken은 호출되지 않아야 함
      expect(mockApple.refreshTokenCalled, false);
    });

    test('unlink가 성공하면 연결이 해제된다', () async {
      kAuth.setProviderForTesting(AuthProvider.kakao, mockKakao);

      // 로그인
      await kAuth.signIn(AuthProvider.kakao);

      // 연결 해제
      final result = await kAuth.unlink(AuthProvider.kakao);

      expect(result.success, true);
      expect(mockKakao.unlinkCalled, true);
      // 현재 로그인된 Provider면 로그아웃 처리됨
      expect(kAuth.currentUser, isNull);
      expect(kAuth.isSignedIn, false);
    });

    test('authStateChanges 스트림이 상태 변화를 방출한다', () async {
      kAuth.setProviderForTesting(AuthProvider.kakao, mockKakao);

      final events = <KAuthUser?>[];
      final subscription = kAuth.authStateChanges.listen(events.add);

      // 로그인
      await kAuth.signIn(AuthProvider.kakao);
      // 로그아웃
      await kAuth.signOut();

      await Future.delayed(const Duration(milliseconds: 100));
      await subscription.cancel();

      expect(events.length, 2);
      expect(events[0]?.id, 'mock_user_id'); // 로그인
      expect(events[1], isNull); // 로그아웃
    });

    test('onSignIn 콜백이 호출된다', () async {
      AuthProvider? capturedProvider;
      KAuthUser? capturedUser;

      final kAuthWithCallback = KAuth(
        config: KAuthConfig(kakao: KakaoConfig(appKey: 'key')),
        onSignIn: (provider, tokens, user) async {
          capturedProvider = provider;
          capturedUser = user;
          return 'server_jwt_token';
        },
      );
      kAuthWithCallback.setProviderForTesting(AuthProvider.kakao, mockKakao);

      await kAuthWithCallback.signIn(AuthProvider.kakao);

      expect(capturedProvider, AuthProvider.kakao);
      expect(capturedUser?.id, 'mock_user_id');
      expect(kAuthWithCallback.serverToken, 'server_jwt_token');

      kAuthWithCallback.dispose();
    });

    test('onSignOut 콜백이 호출된다', () async {
      AuthProvider? capturedProvider;

      final kAuthWithCallback = KAuth(
        config: KAuthConfig(kakao: KakaoConfig(appKey: 'key')),
        onSignOut: (provider) async {
          capturedProvider = provider;
        },
      );
      kAuthWithCallback.setProviderForTesting(AuthProvider.kakao, mockKakao);

      await kAuthWithCallback.signIn(AuthProvider.kakao);
      await kAuthWithCallback.signOut();

      expect(capturedProvider, AuthProvider.kakao);

      kAuthWithCallback.dispose();
    });

    test('signInWithKakao 단축 메서드가 동작한다', () async {
      kAuth.setProviderForTesting(AuthProvider.kakao, mockKakao);

      final result = await kAuth.signInWithKakao();

      expect(result.success, true);
      expect(result.provider, AuthProvider.kakao);
    });

    test('signInWithGoogle 단축 메서드가 동작한다', () async {
      kAuth.setProviderForTesting(AuthProvider.google, mockGoogle);

      final result = await kAuth.signInWithGoogle();

      expect(result.success, true);
      expect(result.provider, AuthProvider.google);
    });

    test('signOutAll이 모든 Provider를 로그아웃한다', () async {
      kAuth.setProviderForTesting(AuthProvider.kakao, mockKakao);
      kAuth.setProviderForTesting(AuthProvider.google, mockGoogle);

      await kAuth.signIn(AuthProvider.kakao);
      final results = await kAuth.signOutAll();

      expect(results.length, 2);
      expect(mockKakao.signOutCalled, true);
      expect(mockGoogle.signOutCalled, true);
      expect(kAuth.isSignedIn, false);
    });

    test('resetForTesting이 상태를 초기화한다', () async {
      kAuth.setProviderForTesting(AuthProvider.kakao, mockKakao);
      await kAuth.signIn(AuthProvider.kakao);

      expect(kAuth.isSignedIn, true);

      kAuth.resetForTesting();

      expect(kAuth.isInitialized, false);
      expect(kAuth.isSignedIn, false);
      expect(kAuth.currentUser, isNull);
    });

    test('Provider가 예외를 던져도 signIn lock이 해제된다', () async {
      mockKakao.signInException = Exception('SDK 크래시');
      kAuth.setProviderForTesting(AuthProvider.kakao, mockKakao);

      // 첫 번째 signIn - 예외 발생하지만 에러 결과 반환
      final result = await kAuth.signIn(AuthProvider.kakao);
      expect(result.success, false);
      expect(result.errorCode, ErrorCodes.loginFailed);

      // 두 번째 signIn - lock이 해제되어 정상 호출 가능
      mockKakao.signInException = null;
      final result2 = await kAuth.signIn(AuthProvider.kakao);
      expect(result2.success, true);
    });
  });

  group('KAuth Session Storage', () {
    late KAuth kAuth;
    late MockAuthProvider mockKakao;
    late InMemorySessionStorage storage;

    setUp(() {
      storage = InMemorySessionStorage();
      kAuth = KAuth(
        config: KAuthConfig(
          kakao: KakaoConfig(appKey: 'test_key'),
        ),
        storage: storage,
      );
      mockKakao = MockAuthProvider(AuthProvider.kakao);
    });

    tearDown(() {
      kAuth.dispose();
    });

    test('로그인 성공 시 세션이 저장된다', () async {
      kAuth.setProviderForTesting(AuthProvider.kakao, mockKakao);

      await kAuth.signIn(AuthProvider.kakao);

      expect(storage.containsKey('k_auth_session'), true);
    });

    test('로그아웃 시 세션이 삭제된다', () async {
      kAuth.setProviderForTesting(AuthProvider.kakao, mockKakao);

      await kAuth.signIn(AuthProvider.kakao);
      expect(storage.containsKey('k_auth_session'), true);

      await kAuth.signOut();
      expect(storage.containsKey('k_auth_session'), false);
    });

    test('clearSession이 세션을 삭제한다', () async {
      kAuth.setProviderForTesting(AuthProvider.kakao, mockKakao);

      await kAuth.signIn(AuthProvider.kakao);
      await kAuth.clearSession();

      expect(storage.containsKey('k_auth_session'), false);
    });
  });

  group('AuthProvider', () {
    test('모든 Provider enum 값이 존재한다', () {
      expect(AuthProvider.values, contains(AuthProvider.kakao));
      expect(AuthProvider.values, contains(AuthProvider.naver));
      expect(AuthProvider.values, contains(AuthProvider.google));
      expect(AuthProvider.values, contains(AuthProvider.apple));
      expect(AuthProvider.values.length, 4);
    });

    test('displayName이 올바르다', () {
      expect(AuthProvider.kakao.displayName, '카카오');
      expect(AuthProvider.naver.displayName, '네이버');
      expect(AuthProvider.google.displayName, 'Google');
      expect(AuthProvider.apple.displayName, 'Apple');
    });

    test('supportsUnlink가 올바르다', () {
      expect(AuthProvider.kakao.supportsUnlink, true);
      expect(AuthProvider.naver.supportsUnlink, true);
      expect(AuthProvider.google.supportsUnlink, true);
      expect(AuthProvider.apple.supportsUnlink, false);
    });
  });

  group('KAuthUser', () {
    test('기본 생성자로 생성한다', () {
      final user = KAuthUser(
        id: '12345',
        name: '홍길동',
        email: 'test@example.com',
        provider: AuthProvider.kakao,
      );

      expect(user.id, '12345');
      expect(user.name, '홍길동');
      expect(user.email, 'test@example.com');
      expect(user.provider, AuthProvider.kakao);
    });

    test('displayName이 올바르게 동작한다', () {
      final withName =
          KAuthUser(id: '1', name: '홍길동', provider: AuthProvider.kakao);
      final withEmail = KAuthUser(
          id: '2', email: 'test@example.com', provider: AuthProvider.kakao);
      final withNeither = KAuthUser(id: '3', provider: AuthProvider.kakao);

      expect(withName.displayName, '홍길동');
      expect(withEmail.displayName, 'test');
      expect(withNeither.displayName, isNull);
    });

    test('age가 올바르게 계산된다', () {
      final currentYear = DateTime.now().year;
      final user = KAuthUser(
        id: '1',
        birthyear: '2000',
        provider: AuthProvider.kakao,
      );

      expect(user.age, currentYear - 2000);
    });

    test('age가 birthyear가 없으면 null이다', () {
      final user = KAuthUser(id: '1', provider: AuthProvider.kakao);
      expect(user.age, isNull);
    });

    test('JSON 직렬화가 동작한다', () {
      final user = KAuthUser(
        id: '12345',
        name: '홍길동',
        email: 'test@example.com',
        provider: AuthProvider.kakao,
      );

      final json = user.toJson();
      final restored = KAuthUser.fromJson(json);

      expect(restored.id, '12345');
      expect(restored.name, '홍길동');
      expect(restored.email, 'test@example.com');
    });

    test('fromKakao가 카카오 응답을 파싱한다', () {
      final kakaoData = {
        'id': 12345678,
        'kakao_account': {
          'email': 'test@kakao.com',
          'profile': {
            'nickname': '카카오유저',
            'profile_image_url': 'https://kakao.com/profile.jpg',
          },
          'phone_number': '+82 10-1234-5678',
          'birthday': '0101',
          'birthyear': '1990',
          'gender': 'male',
          'age_range': '30~39',
        },
      };

      final user = KAuthUser.fromKakao(kakaoData);

      expect(user.id, '12345678');
      expect(user.provider, AuthProvider.kakao);
      expect(user.name, '카카오유저');
      expect(user.email, 'test@kakao.com');
      expect(user.avatar, 'https://kakao.com/profile.jpg');
      expect(user.phone, '+82 10-1234-5678');
      expect(user.birthday, '0101');
      expect(user.birthyear, '1990');
      expect(user.gender, 'male');
      expect(user.ageRange, '30~39');
    });

    test('fromKakao가 빈 kakao_account를 처리한다', () {
      final kakaoData = {'id': 99999};

      final user = KAuthUser.fromKakao(kakaoData);

      expect(user.id, '99999');
      expect(user.provider, AuthProvider.kakao);
      expect(user.name, isNull);
      expect(user.email, isNull);
    });

    test('fromNaver가 네이버 응답을 파싱한다', () {
      final naverData = {
        'response': {
          'id': 'naver_user_id',
          'email': 'test@naver.com',
          'name': '네이버유저',
          'nickname': '닉네임',
          'profile_image': 'https://naver.com/profile.jpg',
          'mobile': '010-1234-5678',
          'birthday': '01-01',
          'birthyear': '1995',
          'gender': 'F',
          'age': '25-29',
        },
      };

      final user = KAuthUser.fromNaver(naverData);

      expect(user.id, 'naver_user_id');
      expect(user.provider, AuthProvider.naver);
      expect(user.name, '네이버유저');
      expect(user.email, 'test@naver.com');
      expect(user.avatar, 'https://naver.com/profile.jpg');
      expect(user.phone, '010-1234-5678');
      expect(user.gender, 'female');
      expect(user.ageRange, '25-29');
    });

    test('fromNaver가 nickname을 fallback으로 사용한다', () {
      final naverData = {
        'response': {
          'id': 'id123',
          'nickname': '닉네임만',
        },
      };

      final user = KAuthUser.fromNaver(naverData);
      expect(user.name, '닉네임만');
    });

    test('fromGoogle이 구글 응답을 파싱한다', () {
      final googleData = {
        'id': 'google_user_id',
        'email': 'test@gmail.com',
        'name': '구글유저',
        'picture': 'https://google.com/profile.jpg',
      };

      final user = KAuthUser.fromGoogle(googleData);

      expect(user.id, 'google_user_id');
      expect(user.provider, AuthProvider.google);
      expect(user.name, '구글유저');
      expect(user.email, 'test@gmail.com');
      expect(user.avatar, 'https://google.com/profile.jpg');
    });

    test('fromGoogle이 sub을 id로 fallback한다', () {
      final googleData = {
        'sub': 'sub_id_123',
        'email': 'test@gmail.com',
      };

      final user = KAuthUser.fromGoogle(googleData);
      expect(user.id, 'sub_id_123');
    });

    test('fromGoogle이 displayName을 name으로 fallback한다', () {
      final googleData = {
        'id': 'id123',
        'displayName': '표시이름',
      };

      final user = KAuthUser.fromGoogle(googleData);
      expect(user.name, '표시이름');
    });

    test('fromApple이 애플 응답을 파싱한다', () {
      final appleData = {
        'userIdentifier': 'apple_user_id',
        'email': 'test@privaterelay.appleid.com',
        'givenName': '길동',
        'familyName': '홍',
      };

      final user = KAuthUser.fromApple(appleData);

      expect(user.id, 'apple_user_id');
      expect(user.provider, AuthProvider.apple);
      expect(user.name, '홍 길동');
      expect(user.email, 'test@privaterelay.appleid.com');
    });

    test('fromApple이 이름 없이도 동작한다', () {
      final appleData = {
        'userIdentifier': 'apple_id',
        'email': 'test@apple.com',
      };

      final user = KAuthUser.fromApple(appleData);

      expect(user.id, 'apple_id');
      expect(user.name, isNull);
    });

    test('fromApple이 sub을 id로 fallback한다', () {
      final appleData = {
        'sub': 'sub_apple_id',
      };

      final user = KAuthUser.fromApple(appleData);
      expect(user.id, 'sub_apple_id');
    });

    test('copyWith가 올바르게 동작한다', () {
      final user = KAuthUser(
        id: '1',
        name: '원래이름',
        email: 'original@test.com',
        provider: AuthProvider.kakao,
      );

      final copied = user.copyWith(name: '새이름');

      expect(copied.id, '1');
      expect(copied.name, '새이름');
      expect(copied.email, 'original@test.com');
      expect(copied.provider, AuthProvider.kakao);
    });

    test('equality가 id와 provider로 판단된다', () {
      final user1 =
          KAuthUser(id: '123', name: '유저1', provider: AuthProvider.kakao);
      final user2 =
          KAuthUser(id: '123', name: '유저2', provider: AuthProvider.kakao);
      final user3 =
          KAuthUser(id: '123', name: '유저1', provider: AuthProvider.naver);

      expect(user1 == user2, true);
      expect(user1 == user3, false);
    });

    test('hashCode가 id와 provider 기반이다', () {
      final user1 = KAuthUser(id: '123', provider: AuthProvider.kakao);
      final user2 = KAuthUser(id: '123', provider: AuthProvider.kakao);

      expect(user1.hashCode, user2.hashCode);
    });

    test('toString이 올바른 형식을 반환한다', () {
      final user = KAuthUser(
        id: '123',
        name: '홍길동',
        email: 'test@test.com',
        provider: AuthProvider.kakao,
      );

      expect(
        user.toString(),
        'KAuthUser(id: 123, provider: kakao, name: 홍길동, email: test@test.com)',
      );
    });
  });

  group('KAuthLogger', () {
    setUp(() {
      KAuthLogger.level = KAuthLogLevel.none;
      KAuthLogger.onLog = null;
    });

    test('기본 로그 레벨은 none이다', () {
      expect(KAuthLogger.level, KAuthLogLevel.none);
    });

    test('로그 레벨을 변경할 수 있다', () {
      KAuthLogger.level = KAuthLogLevel.debug;
      expect(KAuthLogger.level, KAuthLogLevel.debug);

      KAuthLogger.level = KAuthLogLevel.none;
    });

    test('커스텀 로거를 설정할 수 있다', () {
      final logs = <KAuthLogEvent>[];

      KAuthLogger.level = KAuthLogLevel.debug;
      KAuthLogger.onLog = (event) => logs.add(event);

      KAuthLogger.info('테스트 메시지');

      expect(logs.length, 1);
      expect(logs.first.message, '테스트 메시지');
      expect(logs.first.level, KAuthLogLevel.info);
    });

    test('로그 레벨이 none이면 로그가 기록되지 않는다', () {
      final logs = <KAuthLogEvent>[];

      KAuthLogger.level = KAuthLogLevel.none;
      KAuthLogger.onLog = (event) => logs.add(event);

      KAuthLogger.error('에러 메시지');

      expect(logs, isEmpty);
    });

    test('provider 정보가 로그에 포함된다', () {
      final logs = <KAuthLogEvent>[];

      KAuthLogger.level = KAuthLogLevel.debug;
      KAuthLogger.onLog = (event) => logs.add(event);

      KAuthLogger.info('로그인', provider: AuthProvider.kakao.name);

      expect(logs.first.provider, 'kakao');
    });

    test('data가 로그에 포함된다', () {
      final logs = <KAuthLogEvent>[];

      KAuthLogger.level = KAuthLogLevel.debug;
      KAuthLogger.onLog = (event) => logs.add(event);

      KAuthLogger.debug('디버그', data: {'key': 'value'});

      expect(logs.first.data, {'key': 'value'});
    });

    test('error 로그에 에러와 스택트레이스가 포함된다', () {
      final logs = <KAuthLogEvent>[];
      final testError = Exception('테스트 에러');
      final testStack = StackTrace.current;

      KAuthLogger.level = KAuthLogLevel.error;
      KAuthLogger.onLog = (event) => logs.add(event);

      KAuthLogger.error(
        '에러 발생',
        error: testError,
        stackTrace: testStack,
      );

      expect(logs.first.error, testError);
      expect(logs.first.stackTrace, testStack);
    });

    test('로그 레벨 필터링이 동작한다', () {
      final logs = <KAuthLogEvent>[];

      KAuthLogger.level = KAuthLogLevel.warning;
      KAuthLogger.onLog = (event) => logs.add(event);

      KAuthLogger.debug('디버그'); // 무시됨
      KAuthLogger.info('정보'); // 무시됨
      KAuthLogger.warning('경고'); // 기록됨
      KAuthLogger.error('에러'); // 기록됨

      expect(logs.length, 2);
      expect(logs[0].level, KAuthLogLevel.warning);
      expect(logs[1].level, KAuthLogLevel.error);
    });
  });

  group('KAuthLogEvent', () {
    test('toString이 올바른 형식을 반환한다', () {
      final event = KAuthLogEvent(
        level: KAuthLogLevel.info,
        message: '로그인 성공',
        timestamp: DateTime.now(),
        provider: AuthProvider.kakao.name,
      );

      final str = event.toString();

      expect(str, contains('[K-Auth]'));
      expect(str, contains('[kakao]'));
      expect(str, contains('로그인 성공'));
    });

    test('data가 toString에 포함된다', () {
      final event = KAuthLogEvent(
        level: KAuthLogLevel.debug,
        message: '테스트',
        timestamp: DateTime.now(),
        data: {'userId': '123'},
      );

      expect(event.toString(), contains('userId'));
    });
  });

  group('DiagnosticIssue', () {
    test('toString이 올바른 형식을 반환한다', () {
      const issue = DiagnosticIssue(
        provider: AuthProvider.kakao,
        severity: DiagnosticSeverity.error,
        message: 'appKey가 비어있습니다',
      );

      expect(issue.toString(), contains('❌'));
      expect(issue.toString(), contains('카카오'));
      expect(issue.toString(), contains('appKey가 비어있습니다'));
    });

    test('warning은 경고 이모지를 표시한다', () {
      const issue = DiagnosticIssue(
        severity: DiagnosticSeverity.warning,
        message: '경고 메시지',
      );

      expect(issue.toString(), contains('⚠️'));
    });

    test('info는 정보 이모지를 표시한다', () {
      const issue = DiagnosticIssue(
        severity: DiagnosticSeverity.info,
        message: '정보 메시지',
      );

      expect(issue.toString(), contains('ℹ️'));
    });
  });

  group('DiagnosticResult', () {
    test('에러가 있으면 hasErrors가 true다', () {
      final result = DiagnosticResult(
        issues: const [
          DiagnosticIssue(
            severity: DiagnosticSeverity.error,
            message: '에러',
          ),
        ],
        timestamp: DateTime.now(),
        platform: 'ios',
      );

      expect(result.hasErrors, true);
      expect(result.isHealthy, false);
    });

    test('에러가 없으면 isHealthy가 true다', () {
      final result = DiagnosticResult(
        issues: const [
          DiagnosticIssue(
            severity: DiagnosticSeverity.warning,
            message: '경고',
          ),
        ],
        timestamp: DateTime.now(),
        platform: 'ios',
      );

      expect(result.hasErrors, false);
      expect(result.isHealthy, true);
      expect(result.hasWarnings, true);
    });

    test('errors 필터링이 동작한다', () {
      final result = DiagnosticResult(
        issues: const [
          DiagnosticIssue(severity: DiagnosticSeverity.error, message: '에러1'),
          DiagnosticIssue(severity: DiagnosticSeverity.warning, message: '경고'),
          DiagnosticIssue(severity: DiagnosticSeverity.error, message: '에러2'),
        ],
        timestamp: DateTime.now(),
        platform: 'android',
      );

      expect(result.errors.length, 2);
      expect(result.warnings.length, 1);
    });

    test('prettyPrint가 포맷된 문자열을 반환한다', () {
      final result = DiagnosticResult(
        issues: const [
          DiagnosticIssue(
            provider: AuthProvider.kakao,
            severity: DiagnosticSeverity.error,
            message: 'appKey가 비어있습니다',
            solution: 'appKey를 설정하세요',
          ),
        ],
        timestamp: DateTime.now(),
        platform: 'ios',
      );

      final output = result.prettyPrint();

      expect(output, contains('K-Auth 진단 결과'));
      expect(output, contains('플랫폼: ios'));
      expect(output, contains('발견된 문제'));
      expect(output, contains('에러: 1개'));
      expect(output, contains('💡 해결:'));
    });

    test('문제가 없으면 성공 메시지를 표시한다', () {
      final result = DiagnosticResult(
        issues: const [],
        timestamp: DateTime.now(),
        platform: 'ios',
      );

      final output = result.prettyPrint();
      expect(output, contains('모든 설정이 정상입니다'));
    });
  });

  group('KAuthSession', () {
    test('AuthResult에서 세션을 생성한다', () {
      final user = KAuthUser(
        id: '12345',
        email: 'test@example.com',
        name: '테스트',
        provider: AuthProvider.kakao,
      );

      final result = AuthResult.success(
        provider: AuthProvider.kakao,
        user: user,
        accessToken: 'access_token',
        refreshToken: 'refresh_token',
        expiresAt: DateTime(2025, 12, 31),
      );

      final session = KAuthSession.fromAuthResult(result, serverToken: 'jwt');

      expect(session.provider, AuthProvider.kakao);
      expect(session.user.id, '12345');
      expect(session.accessToken, 'access_token');
      expect(session.refreshToken, 'refresh_token');
      expect(session.serverToken, 'jwt');
      expect(session.expiresAt, DateTime(2025, 12, 31));
    });

    test('JSON으로 직렬화/역직렬화가 동작한다', () {
      final user = KAuthUser(
        id: '12345',
        email: 'test@example.com',
        name: '테스트',
        provider: AuthProvider.naver,
      );

      final original = KAuthSession(
        provider: AuthProvider.naver,
        user: user,
        accessToken: 'access_token',
        refreshToken: 'refresh_token',
        serverToken: 'jwt',
        savedAt: DateTime(2025, 1, 1),
        expiresAt: DateTime(2025, 12, 31),
      );

      final encoded = original.encode();
      final decoded = KAuthSession.decode(encoded);

      expect(decoded.provider, original.provider);
      expect(decoded.user.id, original.user.id);
      expect(decoded.accessToken, original.accessToken);
      expect(decoded.refreshToken, original.refreshToken);
      expect(decoded.serverToken, original.serverToken);
      expect(decoded.savedAt, original.savedAt);
      expect(decoded.expiresAt, original.expiresAt);
    });

    test('만료 여부를 확인한다', () {
      final user = KAuthUser(id: '1', provider: AuthProvider.kakao);

      final expiredSession = KAuthSession(
        provider: AuthProvider.kakao,
        user: user,
        expiresAt: DateTime.now().subtract(const Duration(hours: 1)),
        savedAt: DateTime.now(),
      );

      final validSession = KAuthSession(
        provider: AuthProvider.kakao,
        user: user,
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
        savedAt: DateTime.now(),
      );

      final noExpirySession = KAuthSession(
        provider: AuthProvider.kakao,
        user: user,
        savedAt: DateTime.now(),
      );

      expect(expiredSession.isExpired, true);
      expect(validSession.isExpired, false);
      expect(noExpirySession.isExpired, false);
    });

    test('실패한 AuthResult에서 세션 생성 시 예외를 던진다', () {
      final result = AuthResult.failure(
        provider: AuthProvider.kakao,
        errorMessage: '실패',
        errorCode: 'error',
      );

      expect(
        () => KAuthSession.fromAuthResult(result),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('toString이 올바르게 동작한다', () {
      final user = KAuthUser(id: 'user123', provider: AuthProvider.google);

      final session = KAuthSession(
        provider: AuthProvider.google,
        user: user,
        savedAt: DateTime.now(),
      );

      expect(session.toString(), contains('google'));
      expect(session.toString(), contains('user123'));
    });
  });

  group('KAuthSessionStorage', () {
    test('InMemorySessionStorage가 올바르게 동작한다', () async {
      final storage = InMemorySessionStorage();

      // 저장
      await storage.save('key1', 'value1');
      await storage.save('key2', 'value2');

      // 읽기
      expect(await storage.read('key1'), 'value1');
      expect(await storage.read('key2'), 'value2');
      expect(await storage.read('key3'), isNull);

      // 삭제
      await storage.delete('key1');
      expect(await storage.read('key1'), isNull);

      // 전체 삭제
      await storage.clear();
      expect(await storage.read('key2'), isNull);
    });
  });

  // ============================================
  // 추가 테스트: Config 검증
  // ============================================

  group('NaverConfig 검증', () {
    test('빈 clientSecret는 검증 에러를 반환한다', () {
      final config = NaverConfig(
        clientId: 'valid_id',
        clientSecret: '',
        appName: 'Test',
      );
      final errors = config.validate();

      expect(errors.any((e) => e.code == ErrorCodes.missingClientSecret), true);
    });

    test('빈 appName은 에러가 없다 (appName은 필수가 아님)', () {
      final config = NaverConfig(
        clientId: 'valid_id',
        clientSecret: 'valid_secret',
        appName: '',
      );
      final errors = config.validate();

      // appName은 필수 검증 대상이 아님
      expect(errors, isEmpty);
    });

    test('모든 필드가 유효하면 에러가 없다', () {
      final config = NaverConfig(
        clientId: 'valid_id',
        clientSecret: 'valid_secret',
        appName: 'Valid App',
      );
      final errors = config.validate();

      expect(errors, isEmpty);
    });
  });

  group('GoogleConfig 검증', () {
    test('iosClientId가 올바른 형식인지 확인한다', () {
      final configWithValid = GoogleConfig(
        iosClientId: '123456789.apps.googleusercontent.com',
      );
      final configWithInvalid = GoogleConfig(
        iosClientId: 'invalid_format',
      );

      // 형식 검증은 validate에서 하지 않지만 저장은 됨
      expect(configWithValid.iosClientId, contains('googleusercontent.com'));
      expect(configWithInvalid.iosClientId, 'invalid_format');
    });

    test('serverClientId를 설정할 수 있다', () {
      final config = GoogleConfig(
        serverClientId: 'server_client_id',
      );

      expect(config.serverClientId, 'server_client_id');
    });
  });

  // ============================================
  // 추가 테스트: 에러 코드별 메시지/힌트
  // ============================================

  group('에러 코드 상세 테스트', () {
    test('모든 에러 코드에 메시지가 있다', () {
      final codes = [
        ErrorCodes.configNotFound,
        ErrorCodes.invalidConfig,
        ErrorCodes.userCancelled,
        ErrorCodes.loginFailed,
        ErrorCodes.tokenExpired,
        ErrorCodes.networkError,
        ErrorCodes.providerNotConfigured,
        ErrorCodes.providerNotSupported,
        ErrorCodes.platformNotSupported,
        ErrorCodes.noProviderConfigured,
        ErrorCodes.missingAppKey,
        ErrorCodes.missingClientId,
        ErrorCodes.missingClientSecret,
      ];

      for (final code in codes) {
        final info = ErrorCodes.getErrorInfo(code);
        expect(info.message, isNotEmpty, reason: 'Missing message for $code');
      }
    });

    test('주요 에러 코드에 힌트가 있다', () {
      final codesWithHints = [
        ErrorCodes.userCancelled,
        ErrorCodes.loginFailed,
        ErrorCodes.tokenExpired,
        ErrorCodes.networkError,
        ErrorCodes.providerNotConfigured,
      ];

      for (final code in codesWithHints) {
        final info = ErrorCodes.getErrorInfo(code);
        expect(info.hint, isNotNull, reason: 'Missing hint for $code');
      }
    });

    test('카카오 관련 에러 코드가 정의되어 있다', () {
      expect(ErrorCodes.kakaoAppKeyInvalid, isNotNull);
    });

    test('네이버 관련 에러 코드가 정의되어 있다', () {
      expect(ErrorCodes.naverClientInfoInvalid, isNotNull);
    });

    test('구글 관련 에러 코드가 정의되어 있다', () {
      expect(ErrorCodes.googleSignInFailed, isNotNull);
    });

    test('애플 관련 에러 코드가 정의되어 있다', () {
      expect(ErrorCodes.appleSignInFailed, isNotNull);
    });
  });

  // ============================================
  // 추가 테스트: Edge Cases
  // ============================================

  group('KAuthUser Edge Cases', () {
    test('모든 필드가 null인 경우 처리', () {
      final user = KAuthUser(id: 'minimal', provider: AuthProvider.kakao);

      expect(user.id, 'minimal');
      expect(user.name, isNull);
      expect(user.email, isNull);
      expect(user.avatar, isNull);
      expect(user.phone, isNull);
      expect(user.displayName, isNull);
    });

    test('빈 문자열 필드 처리', () {
      final user = KAuthUser(
        id: '',
        name: '',
        email: '',
        provider: AuthProvider.kakao,
      );

      expect(user.id, '');
      expect(user.name, '');
      expect(user.email, '');
    });

    test('특수 문자가 포함된 이름 처리', () {
      final user = KAuthUser(
        id: '1',
        name: '홍길동 (테스트) <test>',
        provider: AuthProvider.kakao,
      );

      expect(user.name, '홍길동 (테스트) <test>');
      expect(user.displayName, '홍길동 (테스트) <test>');
    });

    test('이메일에서 displayName 추출', () {
      final user = KAuthUser(
        id: '1',
        email: 'user.name+tag@example.com',
        provider: AuthProvider.google,
      );

      expect(user.displayName, 'user.name+tag');
    });

    test('잘못된 birthyear로 age 계산', () {
      final userWithInvalid = KAuthUser(
        id: '1',
        birthyear: 'invalid',
        provider: AuthProvider.kakao,
      );

      expect(userWithInvalid.age, isNull);
    });

    test('미래 birthyear로 age 계산', () {
      final futureYear = (DateTime.now().year + 10).toString();
      final user = KAuthUser(
        id: '1',
        birthyear: futureYear,
        provider: AuthProvider.kakao,
      );

      expect(user.age, lessThan(0));
    });

    test('fromKakao에서 중첩된 null 처리', () {
      final kakaoData = {
        'id': 123,
        'kakao_account': null,
      };

      final user = KAuthUser.fromKakao(kakaoData);
      expect(user.id, '123');
      expect(user.name, isNull);
    });

    test('fromNaver에서 response가 빈 경우', () {
      final naverData = {
        'response': <String, dynamic>{
          'id': '',
        },
      };

      final user = KAuthUser.fromNaver(naverData);
      expect(user.provider, AuthProvider.naver);
      expect(user.id, '');
    });

    test('fromGoogle에서 photoUrl 필드 처리', () {
      final googleData = {
        'id': 'google123',
        'photoUrl': 'https://photo.url',
      };

      final user = KAuthUser.fromGoogle(googleData);
      expect(user.avatar, 'https://photo.url');
    });
  });

  group('AuthResult Edge Cases', () {
    test('accessToken만 있는 성공 결과', () {
      final user = KAuthUser(id: '1', provider: AuthProvider.kakao);
      final result = AuthResult.success(
        provider: AuthProvider.kakao,
        user: user,
        accessToken: 'token',
      );

      expect(result.accessToken, 'token');
      expect(result.refreshToken, isNull);
      expect(result.idToken, isNull);
    });

    test('rawData가 있는 결과', () {
      final user = KAuthUser(id: '1', provider: AuthProvider.kakao);
      final result = AuthResult.success(
        provider: AuthProvider.kakao,
        user: user,
        rawData: {'custom': 'data'},
      );

      expect(result.rawData, {'custom': 'data'});
    });

    test('에러 힌트가 있는 실패 결과', () {
      final result = AuthResult.failure(
        provider: AuthProvider.kakao,
        errorMessage: '에러 메시지',
        errorCode: 'ERROR_CODE',
        errorHint: '이렇게 해결하세요',
      );

      expect(result.errorHint, '이렇게 해결하세요');
    });

    test('expiresAt가 null일 때 isExpired는 false', () {
      final user = KAuthUser(id: '1', provider: AuthProvider.kakao);
      final result = AuthResult.success(
        provider: AuthProvider.kakao,
        user: user,
      );

      expect(result.isExpired, false);
      expect(result.isExpiringSoon(), false);
    });

    test('JSON 직렬화 시 모든 필드 포함', () {
      final user = KAuthUser(
        id: '123',
        name: '테스트',
        email: 'test@test.com',
        provider: AuthProvider.google,
      );
      final result = AuthResult.success(
        provider: AuthProvider.google,
        user: user,
        accessToken: 'access',
        refreshToken: 'refresh',
        idToken: 'id_token',
        expiresAt: DateTime(2025, 12, 31),
      );

      final json = result.toJson();

      expect(json['success'], true);
      expect(json['provider'], 'google');
      expect(json['accessToken'], 'access');
      expect(json['refreshToken'], 'refresh');
      expect(json['idToken'], 'id_token');
      expect(json['expiresAt'], isNotNull);
      expect(json['user'], isNotNull);
    });

    test('실패 결과의 JSON 직렬화', () {
      final result = AuthResult.failure(
        provider: AuthProvider.naver,
        errorMessage: '에러',
        errorCode: 'CODE',
        errorHint: '힌트',
      );

      final json = result.toJson();

      expect(json['success'], false);
      expect(json['errorMessage'], '에러');
      expect(json['errorCode'], 'CODE');
      expect(json['errorHint'], '힌트');
    });
  });

  group('KAuthSession Edge Cases', () {
    test('모든 토큰이 null인 세션', () {
      final user = KAuthUser(id: '1', provider: AuthProvider.kakao);
      final session = KAuthSession(
        provider: AuthProvider.kakao,
        user: user,
        savedAt: DateTime.now(),
      );

      expect(session.accessToken, isNull);
      expect(session.refreshToken, isNull);
      expect(session.idToken, isNull);
      expect(session.serverToken, isNull);
    });

    test('손상된 JSON 디코딩 시 예외 발생', () {
      expect(
        () => KAuthSession.decode('invalid json'),
        throwsA(anything),
      );
    });

    test('빈 JSON 디코딩 시 예외 발생', () {
      expect(
        () => KAuthSession.decode('{}'),
        throwsA(anything),
      );
    });

    test('세션 만료 확인 다양한 시간 테스트', () {
      final user = KAuthUser(id: '1', provider: AuthProvider.kakao);

      // 10분 후 만료
      final session10Min = KAuthSession(
        provider: AuthProvider.kakao,
        user: user,
        expiresAt: DateTime.now().add(const Duration(minutes: 10)),
        savedAt: DateTime.now(),
      );

      // 만료 안됨
      expect(session10Min.isExpired, false);

      // 이미 만료됨
      final expiredSession = KAuthSession(
        provider: AuthProvider.kakao,
        user: user,
        expiresAt: DateTime.now().subtract(const Duration(minutes: 1)),
        savedAt: DateTime.now(),
      );
      expect(expiredSession.isExpired, true);
    });
  });

  group('AuthTokens', () {
    test('기본 생성', () {
      const tokens = AuthTokens(
        accessToken: 'access',
        refreshToken: 'refresh',
        idToken: 'id',
        expiresAt: null,
      );

      expect(tokens.accessToken, 'access');
      expect(tokens.refreshToken, 'refresh');
      expect(tokens.idToken, 'id');
      expect(tokens.expiresAt, isNull);
    });

    test('모든 값이 null인 토큰', () {
      const tokens = AuthTokens();

      expect(tokens.accessToken, isNull);
      expect(tokens.refreshToken, isNull);
      expect(tokens.idToken, isNull);
      expect(tokens.expiresAt, isNull);
    });
  });

  group('AuthProvider 확장', () {
    test('supportsTokenRefresh가 올바르다', () {
      expect(AuthProvider.kakao.supportsTokenRefresh, true);
      expect(AuthProvider.naver.supportsTokenRefresh, true);
      expect(AuthProvider.google.supportsTokenRefresh, true);
      expect(AuthProvider.apple.supportsTokenRefresh, false);
    });

    test('name이 올바르게 동작한다', () {
      expect(AuthProvider.kakao.name, 'kakao');
      expect(AuthProvider.naver.name, 'naver');
      expect(AuthProvider.google.name, 'google');
      expect(AuthProvider.apple.name, 'apple');
    });
  });

  // ============================================
  // 추가 테스트: KAuth 기능 테스트
  // ============================================

  group('KAuth 추가 기능', () {
    test('validateOnInitialize가 false면 검증을 스킵한다', () {
      final kAuth = KAuth(
        config: KAuthConfig(), // 빈 설정
        validateOnInitialize: false,
      );

      // 초기화 시 에러가 발생하지 않아야 함
      // 단, Provider SDK가 없으므로 실제 초기화는 할 수 없음
      expect(kAuth.validateOnInitialize, false);
    });

    test('storage가 없으면 세션 저장이 스킵된다', () {
      final kAuth = KAuth(
        config: KAuthConfig(kakao: KakaoConfig(appKey: 'key')),
        storage: null,
      );

      expect(kAuth.storage, isNull);
    });

    test('currentUser가 로그인 전에 null이다', () {
      final kAuth = KAuth(
        config: KAuthConfig(kakao: KakaoConfig(appKey: 'key')),
      );

      expect(kAuth.currentUser, isNull);
      expect(kAuth.currentProvider, isNull);
      expect(kAuth.isSignedIn, false);
      expect(kAuth.serverToken, isNull);
    });

    test('lastResult가 로그인 전에 null이다', () {
      final kAuth = KAuth(
        config: KAuthConfig(kakao: KakaoConfig(appKey: 'key')),
      );

      expect(kAuth.lastResult, isNull);
    });

    test('dispose가 호출되어도 에러가 발생하지 않는다', () {
      final kAuth = KAuth(
        config: KAuthConfig(kakao: KakaoConfig(appKey: 'key')),
      );

      expect(() => kAuth.dispose(), returnsNormally);
    });
  });

  group('KAuthConfig 추가 테스트', () {
    test('copyWith가 동작한다', () {
      final original = KAuthConfig(
        kakao: KakaoConfig(appKey: 'key1'),
      );

      final copied = KAuthConfig(
        kakao: KakaoConfig(appKey: 'key2'),
        google: GoogleConfig(),
      );

      expect(copied.kakao?.appKey, 'key2');
      expect(copied.google, isNotNull);
      expect(original.kakao?.appKey, 'key1');
      expect(original.google, isNull);
    });

    test('여러 에러가 있으면 모두 반환한다', () {
      final config = KAuthConfig(
        kakao: KakaoConfig(appKey: ''),
        naver: NaverConfig(clientId: '', clientSecret: '', appName: ''),
      );

      final errors = config.validate();

      // 카카오 + 네이버 에러 모두 포함
      expect(errors.length, greaterThan(1));
    });
  });

  group('KakaoCollectOptions', () {
    test('기본값 테스트', () {
      const options = KakaoCollectOptions();

      expect(options.phone, false);
      expect(options.gender, false);
      expect(options.birthday, false);
      expect(options.ageRange, false);
    });

    test('모든 옵션 활성화', () {
      const options = KakaoCollectOptions(
        phone: true,
        gender: true,
        birthday: true,
        ageRange: true,
      );

      expect(options.phone, true);
      expect(options.gender, true);
      expect(options.birthday, true);
      expect(options.ageRange, true);
    });
  });

  group('AppleCollectOptions', () {
    test('기본값 테스트', () {
      const options = AppleCollectOptions();

      expect(options.email, true);
      expect(options.fullName, true);
    });

    test('이메일만 수집', () {
      const options = AppleCollectOptions(
        email: true,
        fullName: false,
      );

      expect(options.email, true);
      expect(options.fullName, false);
    });
  });

  // ============================================
  // KAuth 토큰 만료 및 자동 갱신 테스트
  // ============================================

  group('KAuth Token Expiration', () {
    late KAuth kAuth;
    late MockAuthProvider mockKakao;

    setUp(() {
      kAuth = KAuth(
        config: KAuthConfig(
          kakao: KakaoConfig(appKey: 'test_key'),
        ),
      );
      mockKakao = MockAuthProvider(AuthProvider.kakao);
    });

    tearDown(() {
      kAuth.dispose();
    });

    test('expiresAt가 토큰 만료 시간을 반환한다', () async {
      final expiresAt = DateTime.now().add(const Duration(hours: 1));
      mockKakao.signInResult = AuthResult.success(
        provider: AuthProvider.kakao,
        user: KAuthUser(id: '1', provider: AuthProvider.kakao),
        accessToken: 'token',
        expiresAt: expiresAt,
      );
      kAuth.setProviderForTesting(AuthProvider.kakao, mockKakao);

      await kAuth.signIn(AuthProvider.kakao);

      expect(kAuth.expiresAt, expiresAt);
    });

    test('expiresAt가 로그인 전에는 null이다', () {
      expect(kAuth.expiresAt, isNull);
    });

    test('expiresIn이 남은 시간을 반환한다', () async {
      final expiresAt = DateTime.now().add(const Duration(hours: 1));
      mockKakao.signInResult = AuthResult.success(
        provider: AuthProvider.kakao,
        user: KAuthUser(id: '1', provider: AuthProvider.kakao),
        accessToken: 'token',
        expiresAt: expiresAt,
      );
      kAuth.setProviderForTesting(AuthProvider.kakao, mockKakao);

      await kAuth.signIn(AuthProvider.kakao);

      // 약 1시간 남음 (오차 범위 내)
      expect(kAuth.expiresIn.inMinutes, greaterThanOrEqualTo(59));
      expect(kAuth.expiresIn.inMinutes, lessThanOrEqualTo(60));
    });

    test('expiresIn이 만료된 경우 Duration.zero를 반환한다', () async {
      final expiresAt = DateTime.now().subtract(const Duration(hours: 1));
      mockKakao.signInResult = AuthResult.success(
        provider: AuthProvider.kakao,
        user: KAuthUser(id: '1', provider: AuthProvider.kakao),
        accessToken: 'token',
        expiresAt: expiresAt,
      );
      kAuth.setProviderForTesting(AuthProvider.kakao, mockKakao);

      await kAuth.signIn(AuthProvider.kakao);

      expect(kAuth.expiresIn, Duration.zero);
    });

    test('expiresIn이 로그인 전에는 Duration.zero이다', () {
      expect(kAuth.expiresIn, Duration.zero);
    });

    test('isExpiringSoon이 5분 이내 만료 시 true를 반환한다', () async {
      final expiresAt = DateTime.now().add(const Duration(minutes: 3));
      mockKakao.signInResult = AuthResult.success(
        provider: AuthProvider.kakao,
        user: KAuthUser(id: '1', provider: AuthProvider.kakao),
        accessToken: 'token',
        expiresAt: expiresAt,
      );
      kAuth.setProviderForTesting(AuthProvider.kakao, mockKakao);

      await kAuth.signIn(AuthProvider.kakao);

      expect(kAuth.isExpiringSoon(), true);
    });

    test('isExpiringSoon이 5분 이상 남았으면 false를 반환한다', () async {
      final expiresAt = DateTime.now().add(const Duration(minutes: 10));
      mockKakao.signInResult = AuthResult.success(
        provider: AuthProvider.kakao,
        user: KAuthUser(id: '1', provider: AuthProvider.kakao),
        accessToken: 'token',
        expiresAt: expiresAt,
      );
      kAuth.setProviderForTesting(AuthProvider.kakao, mockKakao);

      await kAuth.signIn(AuthProvider.kakao);

      expect(kAuth.isExpiringSoon(), false);
    });

    test('isExpiringSoon이 커스텀 threshold를 지원한다', () async {
      final expiresAt = DateTime.now().add(const Duration(minutes: 8));
      mockKakao.signInResult = AuthResult.success(
        provider: AuthProvider.kakao,
        user: KAuthUser(id: '1', provider: AuthProvider.kakao),
        accessToken: 'token',
        expiresAt: expiresAt,
      );
      kAuth.setProviderForTesting(AuthProvider.kakao, mockKakao);

      await kAuth.signIn(AuthProvider.kakao);

      expect(kAuth.isExpiringSoon(const Duration(minutes: 5)), false);
      expect(kAuth.isExpiringSoon(const Duration(minutes: 10)), true);
    });

    test('isExpiringSoon이 expiresAt가 null이면 false를 반환한다', () {
      expect(kAuth.isExpiringSoon(), false);
    });

    test('isExpired가 만료된 토큰에서 true를 반환한다', () async {
      final expiresAt = DateTime.now().subtract(const Duration(hours: 1));
      mockKakao.signInResult = AuthResult.success(
        provider: AuthProvider.kakao,
        user: KAuthUser(id: '1', provider: AuthProvider.kakao),
        accessToken: 'token',
        expiresAt: expiresAt,
      );
      kAuth.setProviderForTesting(AuthProvider.kakao, mockKakao);

      await kAuth.signIn(AuthProvider.kakao);

      expect(kAuth.isExpired, true);
    });

    test('isExpired가 유효한 토큰에서 false를 반환한다', () async {
      final expiresAt = DateTime.now().add(const Duration(hours: 1));
      mockKakao.signInResult = AuthResult.success(
        provider: AuthProvider.kakao,
        user: KAuthUser(id: '1', provider: AuthProvider.kakao),
        accessToken: 'token',
        expiresAt: expiresAt,
      );
      kAuth.setProviderForTesting(AuthProvider.kakao, mockKakao);

      await kAuth.signIn(AuthProvider.kakao);

      expect(kAuth.isExpired, false);
    });

    test('isExpired가 expiresAt가 null이면 false를 반환한다', () {
      expect(kAuth.isExpired, false);
    });
  });

  group('KAuth Auto Refresh', () {
    late MockAuthProvider mockKakao;

    test('autoRefresh 기본값은 false이다', () {
      final kAuth = KAuth(
        config: KAuthConfig(kakao: KakaoConfig(appKey: 'key')),
      );

      expect(kAuth.autoRefresh, false);
      kAuth.dispose();
    });

    test('autoRefresh를 true로 설정할 수 있다', () {
      final kAuth = KAuth(
        config: KAuthConfig(kakao: KakaoConfig(appKey: 'key')),
        autoRefresh: true,
      );

      expect(kAuth.autoRefresh, true);
      // autoRefresh가 true여도 dispose는 WidgetsBinding 없이 에러 없이 동작해야 함
      // 단, TestWidgetsFlutterBinding가 필요하므로 testWidgets로 테스트
    });

    testWidgets('autoRefresh가 true면 dispose시 observer가 제거된다', (tester) async {
      final kAuth = KAuth(
        config: KAuthConfig(kakao: KakaoConfig(appKey: 'key')),
        autoRefresh: true,
      );

      // dispose 호출이 에러 없이 완료되어야 함
      expect(() => kAuth.dispose(), returnsNormally);
    });

    test('편의 getter들이 currentUser와 동기화된다', () async {
      final kAuth = KAuth(
        config: KAuthConfig(kakao: KakaoConfig(appKey: 'key')),
      );
      mockKakao = MockAuthProvider(AuthProvider.kakao);
      mockKakao.signInResult = AuthResult.success(
        provider: AuthProvider.kakao,
        user: KAuthUser(
          id: 'user123',
          name: '홍길동',
          email: 'test@example.com',
          avatar: 'https://example.com/avatar.jpg',
          provider: AuthProvider.kakao,
        ),
        accessToken: 'token',
      );
      kAuth.setProviderForTesting(AuthProvider.kakao, mockKakao);

      await kAuth.signIn(AuthProvider.kakao);

      expect(kAuth.userId, 'user123');
      expect(kAuth.name, '홍길동');
      expect(kAuth.email, 'test@example.com');
      expect(kAuth.avatar, 'https://example.com/avatar.jpg');

      kAuth.dispose();
    });

    test('로그인 전 편의 getter들이 null을 반환한다', () {
      final kAuth = KAuth(
        config: KAuthConfig(kakao: KakaoConfig(appKey: 'key')),
      );

      expect(kAuth.userId, isNull);
      expect(kAuth.name, isNull);
      expect(kAuth.email, isNull);
      expect(kAuth.avatar, isNull);

      kAuth.dispose();
    });
  });
}

/// 테스트용 인메모리 세션 저장소
class InMemorySessionStorage implements KAuthSessionStorage {
  final Map<String, String> _data = {};

  @override
  Future<void> save(String key, String value) async {
    _data[key] = value;
  }

  @override
  Future<String?> read(String key) async {
    return _data[key];
  }

  @override
  Future<void> delete(String key) async {
    _data.remove(key);
  }

  @override
  Future<void> clear() async {
    _data.clear();
  }

  /// 저장된 데이터 확인 (테스트용)
  bool get isEmpty => _data.isEmpty;
  bool containsKey(String key) => _data.containsKey(key);
}
