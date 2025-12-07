import 'package:flutter_test/flutter_test.dart';
import 'package:k_auth/k_auth.dart';

/// 다양한 에러 시나리오를 시뮬레이션하는 Mock Provider
class ErrorSimulatingProvider implements BaseAuthProvider {
  final AuthProvider provider;
  final String? signInErrorCode;
  final String? signOutErrorCode;
  final String? unlinkErrorCode;
  final String? refreshErrorCode;
  final Exception? throwException;

  ErrorSimulatingProvider({
    required this.provider,
    this.signInErrorCode,
    this.signOutErrorCode,
    this.unlinkErrorCode,
    this.refreshErrorCode,
    this.throwException,
  });

  @override
  Future<void> initialize() async {}

  @override
  Future<AuthResult> signIn() async {
    if (throwException != null) {
      throw throwException!;
    }
    if (signInErrorCode != null) {
      final error = KAuthError.fromCode(signInErrorCode!);
      return AuthResult.failure(
        provider: provider,
        errorMessage: error.message,
        errorCode: error.code,
        errorHint: error.hint,
      );
    }
    return AuthResult.success(
      provider: provider,
      user: KAuthUser(id: 'test_id', provider: provider.name),
      accessToken: 'test_token',
    );
  }

  @override
  Future<AuthResult> signOut() async {
    if (signOutErrorCode != null) {
      final error = KAuthError.fromCode(signOutErrorCode!);
      return AuthResult.failure(
        provider: provider,
        errorMessage: error.message,
        errorCode: error.code,
      );
    }
    return AuthResult.success(provider: provider, user: null);
  }

  @override
  Future<AuthResult> unlink() async {
    if (unlinkErrorCode != null) {
      final error = KAuthError.fromCode(unlinkErrorCode!);
      return AuthResult.failure(
        provider: provider,
        errorMessage: error.message,
        errorCode: error.code,
      );
    }
    return AuthResult.success(provider: provider, user: null);
  }

  @override
  Future<AuthResult> refreshToken() async {
    if (refreshErrorCode != null) {
      final error = KAuthError.fromCode(refreshErrorCode!);
      return AuthResult.failure(
        provider: provider,
        errorMessage: error.message,
        errorCode: error.code,
      );
    }
    return AuthResult.success(
      provider: provider,
      user: KAuthUser(id: 'test_id', provider: provider.name),
      accessToken: 'new_token',
    );
  }
}

void main() {
  // ============================================
  // 사용자 취소 에러 테스트
  // ============================================
  group('사용자 취소 에러', () {
    test('로그인 취소 시 USER_CANCELLED 에러 반환', () async {
      final kAuth = KAuth(
        config: KAuthConfig(kakao: KakaoConfig(appKey: 'key')),
      );
      final mockProvider = ErrorSimulatingProvider(
        provider: AuthProvider.kakao,
        signInErrorCode: ErrorCodes.userCancelled,
      );
      kAuth.setProviderForTesting(AuthProvider.kakao, mockProvider);

      final result = await kAuth.signIn(AuthProvider.kakao);

      expect(result.success, false);
      expect(result.errorCode, ErrorCodes.userCancelled);
      expect(result.errorMessage, contains('취소'));

      kAuth.dispose();
    });

    test('when 패턴으로 취소 케이스를 구분할 수 있다', () async {
      final kAuth = KAuth(
        config: KAuthConfig(kakao: KakaoConfig(appKey: 'key')),
      );
      final mockProvider = ErrorSimulatingProvider(
        provider: AuthProvider.kakao,
        signInErrorCode: ErrorCodes.userCancelled,
      );
      kAuth.setProviderForTesting(AuthProvider.kakao, mockProvider);

      final result = await kAuth.signIn(AuthProvider.kakao);

      String? handledCase;
      result.when(
        success: (user) => handledCase = 'success',
        cancelled: () => handledCase = 'cancelled',
        failure: (code, message) => handledCase = 'failure',
      );

      expect(handledCase, 'cancelled');

      kAuth.dispose();
    });
  });

  // ============================================
  // 네트워크 에러 테스트
  // ============================================
  group('네트워크 에러', () {
    test('네트워크 에러 시 NETWORK_ERROR 반환', () async {
      final kAuth = KAuth(
        config: KAuthConfig(kakao: KakaoConfig(appKey: 'key')),
      );
      final mockProvider = ErrorSimulatingProvider(
        provider: AuthProvider.kakao,
        signInErrorCode: ErrorCodes.networkError,
      );
      kAuth.setProviderForTesting(AuthProvider.kakao, mockProvider);

      final result = await kAuth.signIn(AuthProvider.kakao);

      expect(result.success, false);
      expect(result.errorCode, ErrorCodes.networkError);
      expect(result.errorMessage, contains('네트워크'));

      kAuth.dispose();
    });
  });

  // ============================================
  // 토큰 만료 에러 테스트
  // ============================================
  group('토큰 만료 에러', () {
    test('토큰 만료 시 TOKEN_EXPIRED 반환', () async {
      final kAuth = KAuth(
        config: KAuthConfig(kakao: KakaoConfig(appKey: 'key')),
      );
      final mockProvider = ErrorSimulatingProvider(
        provider: AuthProvider.kakao,
        refreshErrorCode: ErrorCodes.tokenExpired,
      );
      kAuth.setProviderForTesting(AuthProvider.kakao, mockProvider);

      // 먼저 로그인
      await kAuth.signIn(AuthProvider.kakao);

      // 토큰 갱신 실패
      final result = await kAuth.refreshToken();

      expect(result.success, false);
      expect(result.errorCode, ErrorCodes.tokenExpired);

      kAuth.dispose();
    });

    test('isExpired가 true면 갱신 필요', () {
      final result = AuthResult.success(
        provider: AuthProvider.kakao,
        user: KAuthUser(id: '123', provider: 'kakao'),
        accessToken: 'token',
        expiresAt: DateTime.now().subtract(const Duration(hours: 1)),
      );

      expect(result.isExpired, true);
    });

    test('isExpiringSoon이 5분 이내면 true', () {
      final result = AuthResult.success(
        provider: AuthProvider.kakao,
        user: KAuthUser(id: '123', provider: 'kakao'),
        accessToken: 'token',
        expiresAt: DateTime.now().add(const Duration(minutes: 3)),
      );

      expect(result.isExpiringSoon(), true);
      expect(result.isExpiringSoon(const Duration(minutes: 2)), false);
    });
  });

  // ============================================
  // Provider 설정 에러 테스트
  // ============================================
  group('Provider 설정 에러', () {
    test('설정되지 않은 Provider 호출 시 PROVIDER_NOT_CONFIGURED 반환', () async {
      final kAuth = KAuth(
        config: KAuthConfig(kakao: KakaoConfig(appKey: 'key')),
      );
      kAuth.setProviderForTesting(
        AuthProvider.kakao,
        ErrorSimulatingProvider(provider: AuthProvider.kakao),
      );

      // 네이버는 설정 안 됨
      final result = await kAuth.signIn(AuthProvider.naver);

      expect(result.success, false);
      expect(result.errorCode, ErrorCodes.providerNotConfigured);

      kAuth.dispose();
    });

    test('초기화 전 호출 시 에러 발생', () async {
      final kAuth = KAuth(
        config: KAuthConfig(kakao: KakaoConfig(appKey: 'key')),
      );

      // initialize() 호출하지 않음

      expect(
        () => kAuth.signIn(AuthProvider.kakao),
        throwsA(isA<KAuthError>()),
      );

      kAuth.dispose();
    });
  });

  // ============================================
  // 로그아웃 에러 테스트
  // ============================================
  group('로그아웃 에러', () {
    test('로그아웃 실패 시 SIGN_OUT_FAILED 반환', () async {
      final kAuth = KAuth(
        config: KAuthConfig(kakao: KakaoConfig(appKey: 'key')),
      );
      final mockProvider = ErrorSimulatingProvider(
        provider: AuthProvider.kakao,
        signOutErrorCode: ErrorCodes.signOutFailed,
      );
      kAuth.setProviderForTesting(AuthProvider.kakao, mockProvider);

      await kAuth.signIn(AuthProvider.kakao);
      final result = await kAuth.signOut();

      expect(result.success, false);
      expect(result.errorCode, ErrorCodes.signOutFailed);

      kAuth.dispose();
    });
  });

  // ============================================
  // 연결 해제 에러 테스트
  // ============================================
  group('연결 해제 에러', () {
    test('연결 해제 실패 시 UNLINK_FAILED 반환', () async {
      final kAuth = KAuth(
        config: KAuthConfig(kakao: KakaoConfig(appKey: 'key')),
      );
      final mockProvider = ErrorSimulatingProvider(
        provider: AuthProvider.kakao,
        unlinkErrorCode: ErrorCodes.unlinkFailed,
      );
      kAuth.setProviderForTesting(AuthProvider.kakao, mockProvider);

      await kAuth.signIn(AuthProvider.kakao);
      final result = await kAuth.unlink(AuthProvider.kakao);

      expect(result.success, false);
      expect(result.errorCode, ErrorCodes.unlinkFailed);

      kAuth.dispose();
    });
  });

  // ============================================
  // Provider별 에러 테스트
  // ============================================
  group('카카오 에러', () {
    test('앱 키 유효하지 않음', () async {
      final kAuth = KAuth(
        config: KAuthConfig(kakao: KakaoConfig(appKey: 'key')),
      );
      final mockProvider = ErrorSimulatingProvider(
        provider: AuthProvider.kakao,
        signInErrorCode: ErrorCodes.kakaoAppKeyInvalid,
      );
      kAuth.setProviderForTesting(AuthProvider.kakao, mockProvider);

      final result = await kAuth.signIn(AuthProvider.kakao);

      expect(result.success, false);
      expect(result.errorCode, ErrorCodes.kakaoAppKeyInvalid);
      expect(result.errorMessage, contains('앱 키'));

      kAuth.dispose();
    });

    test('Redirect URI 오류', () async {
      final kAuth = KAuth(
        config: KAuthConfig(kakao: KakaoConfig(appKey: 'key')),
      );
      final mockProvider = ErrorSimulatingProvider(
        provider: AuthProvider.kakao,
        signInErrorCode: ErrorCodes.kakaoInvalidRedirectUri,
      );
      kAuth.setProviderForTesting(AuthProvider.kakao, mockProvider);

      final result = await kAuth.signIn(AuthProvider.kakao);

      expect(result.success, false);
      expect(result.errorCode, ErrorCodes.kakaoInvalidRedirectUri);

      kAuth.dispose();
    });
  });

  group('네이버 에러', () {
    test('클라이언트 정보 유효하지 않음', () async {
      final kAuth = KAuth(
        config: KAuthConfig(
          naver: NaverConfig(
            clientId: 'id',
            clientSecret: 'secret',
            appName: 'app',
          ),
        ),
      );
      final mockProvider = ErrorSimulatingProvider(
        provider: AuthProvider.naver,
        signInErrorCode: ErrorCodes.naverClientInfoInvalid,
      );
      kAuth.setProviderForTesting(AuthProvider.naver, mockProvider);

      final result = await kAuth.signIn(AuthProvider.naver);

      expect(result.success, false);
      expect(result.errorCode, ErrorCodes.naverClientInfoInvalid);

      kAuth.dispose();
    });
  });

  group('구글 에러', () {
    test('구글 로그인 실패', () async {
      final kAuth = KAuth(
        config: KAuthConfig(google: GoogleConfig()),
      );
      final mockProvider = ErrorSimulatingProvider(
        provider: AuthProvider.google,
        signInErrorCode: ErrorCodes.googleSignInFailed,
      );
      kAuth.setProviderForTesting(AuthProvider.google, mockProvider);

      final result = await kAuth.signIn(AuthProvider.google);

      expect(result.success, false);
      expect(result.errorCode, ErrorCodes.googleSignInFailed);

      kAuth.dispose();
    });
  });

  group('애플 에러', () {
    test('애플 미지원 플랫폼', () async {
      final kAuth = KAuth(
        config: KAuthConfig(apple: AppleConfig()),
      );
      final mockProvider = ErrorSimulatingProvider(
        provider: AuthProvider.apple,
        signInErrorCode: ErrorCodes.appleNotSupported,
      );
      kAuth.setProviderForTesting(AuthProvider.apple, mockProvider);

      final result = await kAuth.signIn(AuthProvider.apple);

      expect(result.success, false);
      expect(result.errorCode, ErrorCodes.appleNotSupported);
      expect(result.errorMessage, contains('지원하지 않습니다'));

      kAuth.dispose();
    });

    test('애플 토큰 갱신 미지원', () async {
      final kAuth = KAuth(
        config: KAuthConfig(apple: AppleConfig()),
      );
      final mockProvider = ErrorSimulatingProvider(
        provider: AuthProvider.apple,
        refreshErrorCode: ErrorCodes.providerNotSupported,
      );
      kAuth.setProviderForTesting(AuthProvider.apple, mockProvider);

      await kAuth.signIn(AuthProvider.apple);
      final result = await kAuth.refreshToken();

      expect(result.success, false);
      expect(result.errorCode, ErrorCodes.providerNotSupported);

      kAuth.dispose();
    });
  });

  // ============================================
  // KAuthError 테스트
  // ============================================
  group('KAuthError', () {
    test('fromCode로 에러 생성', () {
      final error = KAuthError.fromCode(ErrorCodes.loginFailed);

      expect(error.code, ErrorCodes.loginFailed);
      expect(error.message, isNotEmpty);
      expect(error.hint, isNotEmpty);
    });

    test('details와 originalError 포함', () {
      final originalError = Exception('Original error');
      final error = KAuthError.fromCode(
        ErrorCodes.loginFailed,
        details: {'key': 'value'},
        originalError: originalError,
      );

      expect(error.details, {'key': 'value'});
      expect(error.originalError, originalError);
    });

    test('toJson 변환', () {
      final error = KAuthError.fromCode(
        ErrorCodes.loginFailed,
        details: {'key': 'value'},
      );

      final json = error.toJson();

      expect(json['code'], ErrorCodes.loginFailed);
      expect(json['message'], isNotEmpty);
      expect(json['details'], {'key': 'value'});
    });

    test('toString 형식', () {
      final error = KAuthError.fromCode(ErrorCodes.loginFailed);

      expect(error.toString(), contains('KAuthError'));
      expect(error.toString(), contains(ErrorCodes.loginFailed));
    });

    test('toUserMessage 반환', () {
      final error = KAuthError.fromCode(ErrorCodes.loginFailed);

      expect(error.toUserMessage(), error.message);
    });
  });

  // ============================================
  // AuthResult 에러 핸들링 테스트
  // ============================================
  group('AuthResult 에러 핸들링', () {
    test('fold로 에러 처리', () {
      final result = AuthResult.failure(
        provider: AuthProvider.kakao,
        errorMessage: '로그인 실패',
        errorCode: ErrorCodes.loginFailed,
      );

      String? errorMessage;
      result.fold(
        onSuccess: (user) {},
        onFailure: (error) => errorMessage = error,
      );

      expect(errorMessage, '로그인 실패');
    });

    test('onFailure 체이닝', () {
      final result = AuthResult.failure(
        provider: AuthProvider.kakao,
        errorMessage: '로그인 실패',
        errorCode: ErrorCodes.loginFailed,
      );

      String? capturedCode;
      String? capturedMessage;
      result.onFailure((code, message) {
        capturedCode = code;
        capturedMessage = message;
      });

      expect(capturedCode, ErrorCodes.loginFailed);
      expect(capturedMessage, '로그인 실패');
    });

    test('onSuccess는 실패 시 호출되지 않음', () {
      final result = AuthResult.failure(
        provider: AuthProvider.kakao,
        errorMessage: '로그인 실패',
        errorCode: ErrorCodes.loginFailed,
      );

      bool called = false;
      result.onSuccess((user) => called = true);

      expect(called, false);
    });

    test('errorHint 접근', () {
      final result = AuthResult.failure(
        provider: AuthProvider.kakao,
        errorMessage: '로그인 실패',
        errorCode: ErrorCodes.loginFailed,
        errorHint: '네트워크를 확인하세요',
      );

      expect(result.errorHint, '네트워크를 확인하세요');
    });
  });

  // ============================================
  // Config 검증 에러 테스트
  // ============================================
  group('Config 검증 에러', () {
    test('KakaoConfig 빈 appKey', () {
      final config = KakaoConfig(appKey: '');
      final errors = config.validate();

      expect(errors, isNotEmpty);
      expect(errors.first.code, ErrorCodes.missingAppKey);
    });

    test('NaverConfig 빈 clientId', () {
      final config = NaverConfig(
        clientId: '',
        clientSecret: 'secret',
        appName: 'app',
      );
      final errors = config.validate();

      expect(errors, isNotEmpty);
      expect(errors.first.code, ErrorCodes.missingClientId);
    });

    test('NaverConfig 빈 clientSecret', () {
      final config = NaverConfig(
        clientId: 'id',
        clientSecret: '',
        appName: 'app',
      );
      final errors = config.validate();

      expect(errors, isNotEmpty);
      expect(errors.first.code, ErrorCodes.missingClientSecret);
    });

    test('NaverConfig 빈 appName은 검증 통과 (optional)', () {
      // appName은 필수가 아닐 수 있음
      final config = NaverConfig(
        clientId: 'id',
        clientSecret: 'secret',
        appName: '',
      );
      final errors = config.validate();

      // 빈 appName은 에러가 아님 (SDK에서 처리)
      expect(errors.isEmpty, true);
    });

    test('KAuthConfig에 Provider가 없으면 에러', () {
      final config = KAuthConfig();
      final errors = config.validate();

      expect(errors, isNotEmpty);
      expect(errors.first.code, ErrorCodes.noProviderConfigured);
    });
  });
}
