import 'package:flutter_test/flutter_test.dart';
import 'package:k_auth/k_auth.dart';

void main() {
  group('AuthResult', () {
    test('성공 결과를 생성한다', () {
      final result = AuthResult.success(
        provider: AuthProvider.kakao,
        userId: '12345',
        email: 'test@example.com',
        name: '홍길동',
      );

      expect(result.success, true);
      expect(result.provider, AuthProvider.kakao);
      expect(result.userId, '12345');
      expect(result.email, 'test@example.com');
      expect(result.name, '홍길동');
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
      expect(result.userId, isNull);
    });

    test('toString이 올바른 형식을 반환한다', () {
      final result = AuthResult.success(
        provider: AuthProvider.google,
        userId: '12345',
        email: 'test@example.com',
      );

      expect(
        result.toString(),
        'AuthResult(success: true, provider: AuthProvider.google, userId: 12345, email: test@example.com)',
      );
    });
  });

  group('KakaoConfig', () {
    test('기본 scope를 포함한다', () {
      final config = KakaoConfig(appKey: 'test_key');

      expect(config.allScopes, contains('profile_nickname'));
      expect(config.allScopes, contains('profile_image'));
      expect(config.allScopes, contains('account_email'));
    });

    test('collectPhone이 true이면 phone_number scope를 추가한다', () {
      final config = KakaoConfig(
        appKey: 'test_key',
        collectPhone: true,
      );

      expect(config.allScopes, contains('phone_number'));
    });

    test('collectPhone이 false이면 phone_number scope를 포함하지 않는다', () {
      final config = KakaoConfig(
        appKey: 'test_key',
        collectPhone: false,
      );

      expect(config.allScopes, isNot(contains('phone_number')));
    });

    test('추가 scope를 포함한다', () {
      final config = KakaoConfig(
        appKey: 'test_key',
        scopes: ['friends', 'talk_message'],
      );

      expect(config.allScopes, contains('friends'));
      expect(config.allScopes, contains('talk_message'));
    });

    test('중복 scope를 제거한다', () {
      final config = KakaoConfig(
        appKey: 'test_key',
        scopes: ['profile_nickname', 'friends'],
      );

      final nicknameCount = config.allScopes
          .where((s) => s == 'profile_nickname')
          .length;
      expect(nicknameCount, 1);
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
  });

  group('GoogleConfig', () {
    test('선택적 설정값을 저장한다', () {
      final config = GoogleConfig(
        iosClientId: 'ios_client_id',
        serverClientId: 'server_client_id',
        scopes: ['calendar'],
      );

      expect(config.iosClientId, 'ios_client_id');
      expect(config.serverClientId, 'server_client_id');
      expect(config.scopes, contains('calendar'));
    });

    test('설정값 없이 생성할 수 있다', () {
      final config = GoogleConfig();

      expect(config.iosClientId, isNull);
      expect(config.serverClientId, isNull);
      expect(config.scopes, isNull);
    });
  });

  group('AppleConfig', () {
    test('기본 설정으로 생성할 수 있다', () {
      final config = AppleConfig();

      expect(config.scopes, isNull);
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
  });

  group('ErrorMessages', () {
    test('에러 코드에 대한 한글 메시지를 반환한다', () {
      expect(
        ErrorMessages.getMessage(ErrorCodes.userCancelled),
        '사용자가 로그인을 취소했습니다.',
      );
      expect(
        ErrorMessages.getMessage(ErrorCodes.loginFailed),
        '로그인에 실패했습니다.',
      );
      expect(
        ErrorMessages.getMessage(ErrorCodes.networkError),
        '네트워크 오류가 발생했습니다.',
      );
      expect(
        ErrorMessages.getMessage(ErrorCodes.providerNotConfigured),
        '해당 Provider가 설정되지 않았습니다.',
      );
    });

    test('알 수 없는 에러 코드에 대해 기본 메시지를 반환한다', () {
      expect(
        ErrorMessages.getMessage('UNKNOWN_ERROR'),
        '알 수 없는 에러가 발생했습니다.',
      );
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

    test('초기화 전 signInWithKakao 호출 시 에러를 발생시킨다', () {
      final kAuth = KAuth(
        config: KAuthConfig(
          kakao: KakaoConfig(appKey: 'test_key'),
        ),
      );

      expect(
        () => kAuth.signInWithKakao(),
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
  });

  group('AuthProvider', () {
    test('모든 Provider enum 값이 존재한다', () {
      expect(AuthProvider.values, contains(AuthProvider.kakao));
      expect(AuthProvider.values, contains(AuthProvider.naver));
      expect(AuthProvider.values, contains(AuthProvider.google));
      expect(AuthProvider.values, contains(AuthProvider.apple));
      expect(AuthProvider.values.length, 4);
    });
  });
}
