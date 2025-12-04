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

    test('age가 birthyear가 없으면 null이다', () {
      final user = KAuthUser(id: '1', provider: 'kakao');
      expect(user.age, isNull);
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
      expect(user.provider, 'kakao');
      expect(user.name, '카카오유저');
      expect(user.email, 'test@kakao.com');
      expect(user.image, 'https://kakao.com/profile.jpg');
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
      expect(user.provider, 'kakao');
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
      expect(user.provider, 'naver');
      expect(user.name, '네이버유저');
      expect(user.email, 'test@naver.com');
      expect(user.image, 'https://naver.com/profile.jpg');
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
      expect(user.provider, 'google');
      expect(user.name, '구글유저');
      expect(user.email, 'test@gmail.com');
      expect(user.image, 'https://google.com/profile.jpg');
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
      expect(user.provider, 'apple');
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
        provider: 'kakao',
      );

      final copied = user.copyWith(name: '새이름');

      expect(copied.id, '1');
      expect(copied.name, '새이름');
      expect(copied.email, 'original@test.com');
      expect(copied.provider, 'kakao');
    });

    test('equality가 id와 provider로 판단된다', () {
      final user1 = KAuthUser(id: '123', name: '유저1', provider: 'kakao');
      final user2 = KAuthUser(id: '123', name: '유저2', provider: 'kakao');
      final user3 = KAuthUser(id: '123', name: '유저1', provider: 'naver');

      expect(user1 == user2, true);
      expect(user1 == user3, false);
    });

    test('hashCode가 id와 provider 기반이다', () {
      final user1 = KAuthUser(id: '123', provider: 'kakao');
      final user2 = KAuthUser(id: '123', provider: 'kakao');

      expect(user1.hashCode, user2.hashCode);
    });

    test('toString이 올바른 형식을 반환한다', () {
      final user = KAuthUser(
        id: '123',
        name: '홍길동',
        email: 'test@test.com',
        provider: 'kakao',
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

      KAuthLogger.info('로그인', provider: 'kakao');

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
        provider: 'kakao',
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
}
