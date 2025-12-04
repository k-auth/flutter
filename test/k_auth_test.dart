import 'package:flutter_test/flutter_test.dart';
import 'package:k_auth/k_auth.dart';

void main() {
  group('AuthResult', () {
    test('성공 결과를 생성한다', () {
      final user = KAuthUser(
        id: '12345',
        email: 'test@example.com',
        name: '홍길동',
        provider: 'kakao',
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
      final user = KAuthUser(id: '1', provider: 'kakao');

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
      final user = KAuthUser(id: '1', provider: 'kakao');

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
        provider: 'google',
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
      final user = KAuthUser(id: '1', name: '홍길동', provider: 'kakao');
      final result = AuthResult.success(
        provider: AuthProvider.kakao,
        user: user,
      );

      final message = result.fold(
        onSuccess: (u) => '환영합니다, ${u.name}!',
        onFailure: (e) => '실패: $e',
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
        onFailure: (e) => '에러: $e',
      );

      expect(message, '에러: 로그인 실패');
    });

    test('when이 성공/취소/실패를 구분한다', () {
      final user = KAuthUser(id: '1', provider: 'kakao');

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
          failure: (_, __) => 'failure',
        ),
        'success',
      );

      expect(
        cancelledResult.when(
          success: (_) => 'success',
          cancelled: () => 'cancelled',
          failure: (_, __) => 'failure',
        ),
        'cancelled',
      );

      expect(
        failureResult.when(
          success: (_) => 'success',
          cancelled: () => 'cancelled',
          failure: (_, __) => 'failure',
        ),
        'failure',
      );
    });

    test('onSuccess가 체이닝을 지원한다', () {
      final user = KAuthUser(id: '1', name: '홍길동', provider: 'kakao');
      final result = AuthResult.success(
        provider: AuthProvider.kakao,
        user: user,
      );

      String? capturedName;
      String? capturedError;

      result
          .onSuccess((u) => capturedName = u.name)
          .onFailure((_, msg) => capturedError = msg);

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
          .onFailure((_, msg) => capturedError = msg);

      expect(capturedName, isNull);
      expect(capturedError, '실패');
    });

    test('mapUser가 성공 시 변환된 값을 반환한다', () {
      final user = KAuthUser(id: '1', name: '홍길동', provider: 'kakao');
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

      expect(errors.any((e) => e.code == ErrorCodes.noProviderConfigured), true);
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
        provider: 'kakao',
      );

      expect(user.id, '12345');
      expect(user.name, '홍길동');
      expect(user.email, 'test@example.com');
      expect(user.provider, 'kakao');
    });

    test('displayName이 올바르게 동작한다', () {
      final withName = KAuthUser(id: '1', name: '홍길동', provider: 'kakao');
      final withEmail = KAuthUser(
          id: '2', email: 'test@example.com', provider: 'kakao');
      final withNeither = KAuthUser(id: '3', provider: 'kakao');

      expect(withName.displayName, '홍길동');
      expect(withEmail.displayName, 'test');
      expect(withNeither.displayName, isNull);
    });

    test('age가 올바르게 계산된다', () {
      final currentYear = DateTime.now().year;
      final user = KAuthUser(
        id: '1',
        birthyear: '2000',
        provider: 'kakao',
      );

      expect(user.age, currentYear - 2000);
    });

    test('JSON 직렬화가 동작한다', () {
      final user = KAuthUser(
        id: '12345',
        name: '홍길동',
        email: 'test@example.com',
        provider: 'kakao',
      );

      final json = user.toJson();
      final restored = KAuthUser.fromJson(json);

      expect(restored.id, '12345');
      expect(restored.name, '홍길동');
      expect(restored.email, 'test@example.com');
    });
  });
}
