import 'package:flutter_test/flutter_test.dart';
import 'package:k_auth/k_auth.dart';

import '../helpers/test_utils.dart';

void main() {
  group('에러 복구 통합 테스트', () {
    late MockAuthProvider mockKakao;
    late KAuth kAuth;

    setUp(() {
      mockKakao = MockAuthProvider(AuthProvider.kakao);
      kAuth = TestKAuthFactory.withMockProviders(
        providers: {AuthProvider.kakao: mockKakao},
      );
    });

    tearDown(() {
      kAuth.dispose();
    });

    group('에러 분류', () {
      test('네트워크 에러는 canRetry가 true', () async {
        mockKakao.signInResult = AuthResult.failure(
          provider: AuthProvider.kakao,
          errorCode: ErrorCodes.networkError,
          errorMessage: '네트워크 오류',
        );

        final result = await kAuth.signIn(AuthProvider.kakao);

        expect(result.success, false);
        expect(result.failure.canRetry, true);
        expect(result.failure.severity, ErrorSeverity.retryable);
      });

      test('타임아웃 에러는 canRetry가 true', () async {
        mockKakao.signInResult = AuthResult.failure(
          provider: AuthProvider.kakao,
          errorCode: ErrorCodes.timeout,
          errorMessage: '타임아웃',
        );

        final result = await kAuth.signIn(AuthProvider.kakao);

        expect(result.failure.canRetry, true);
        expect(result.failure.isTemporary, true);
      });

      test('취소 에러는 shouldIgnore가 true', () async {
        mockKakao.signInResult = AuthResult.failure(
          provider: AuthProvider.kakao,
          errorCode: ErrorCodes.userCancelled,
          errorMessage: '취소됨',
        );

        final result = await kAuth.signIn(AuthProvider.kakao);

        expect(result.failure.shouldIgnore, true);
        expect(result.failure.severity, ErrorSeverity.ignorable);
      });

      test('토큰 만료 에러는 requiresReauth가 true', () async {
        mockKakao.signInResult = AuthResult.failure(
          provider: AuthProvider.kakao,
          errorCode: ErrorCodes.tokenExpired,
          errorMessage: '토큰 만료',
        );

        final result = await kAuth.signIn(AuthProvider.kakao);

        expect(result.failure.requiresReauth, true);
        expect(result.failure.severity, ErrorSeverity.authRequired);
      });

      test('설정 에러는 isConfigError가 true', () async {
        mockKakao.signInResult = AuthResult.failure(
          provider: AuthProvider.kakao,
          errorCode: ErrorCodes.invalidConfig,
          errorMessage: '설정 오류',
        );

        final result = await kAuth.signIn(AuthProvider.kakao);

        expect(result.failure.isConfigError, true);
        expect(result.failure.isPermanent, true);
        expect(result.failure.severity, ErrorSeverity.fixRequired);
      });
    });

    group('에러 후 복구', () {
      test('실패 후 재시도 성공', () async {
        // 첫 번째 시도: 실패
        mockKakao.signInResult = AuthResult.failure(
          provider: AuthProvider.kakao,
          errorCode: ErrorCodes.networkError,
          errorMessage: '네트워크 오류',
        );

        var result = await kAuth.signIn(AuthProvider.kakao);
        expect(result.success, false);
        expect(kAuth.isSignedIn, false);

        // 두 번째 시도: 성공
        mockKakao.signInResult = AuthResult.success(
          provider: AuthProvider.kakao,
          user: KAuthUser(id: 'test', provider: AuthProvider.kakao),
        );

        result = await kAuth.signIn(AuthProvider.kakao);
        expect(result.success, true);
        expect(kAuth.isSignedIn, true);
      });

      test('연속 실패 후 성공', () async {
        // 3번 실패
        for (var i = 0; i < 3; i++) {
          mockKakao.signInResult = AuthResult.failure(
            provider: AuthProvider.kakao,
            errorCode: ErrorCodes.networkError,
            errorMessage: '네트워크 오류 #$i',
          );
          final result = await kAuth.signIn(AuthProvider.kakao);
          expect(result.success, false);
        }

        // 4번째 성공
        mockKakao.signInResult = AuthResult.success(
          provider: AuthProvider.kakao,
          user: KAuthUser(id: 'test', provider: AuthProvider.kakao),
        );
        final result = await kAuth.signIn(AuthProvider.kakao);
        expect(result.success, true);
      });
    });

    group('when 패턴 처리', () {
      test('success/cancelled/failure 분기', () async {
        var successCalled = false;
        var cancelledCalled = false;
        var failureCalled = false;

        // 성공 케이스
        mockKakao.signInResult = AuthResult.success(
          provider: AuthProvider.kakao,
          user: KAuthUser(id: 'test', provider: AuthProvider.kakao),
        );
        (await kAuth.signIn(AuthProvider.kakao)).when(
          success: (_) => successCalled = true,
          cancelled: () => cancelledCalled = true,
          failure: (_) => failureCalled = true,
        );
        expect(successCalled, true);

        // 취소 케이스
        successCalled = false;
        mockKakao.signInResult = AuthResult.failure(
          provider: AuthProvider.kakao,
          errorCode: ErrorCodes.userCancelled,
          errorMessage: '취소',
        );
        (await kAuth.signIn(AuthProvider.kakao)).when(
          success: (_) => successCalled = true,
          cancelled: () => cancelledCalled = true,
          failure: (_) => failureCalled = true,
        );
        expect(cancelledCalled, true);

        // 실패 케이스
        cancelledCalled = false;
        mockKakao.signInResult = AuthResult.failure(
          provider: AuthProvider.kakao,
          errorCode: ErrorCodes.loginFailed,
          errorMessage: '실패',
        );
        (await kAuth.signIn(AuthProvider.kakao)).when(
          success: (_) => successCalled = true,
          cancelled: () => cancelledCalled = true,
          failure: (_) => failureCalled = true,
        );
        expect(failureCalled, true);
      });
    });
  });
}
