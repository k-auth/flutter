import 'package:flutter_test/flutter_test.dart';
import 'package:k_auth/k_auth.dart';

import '../helpers/test_utils.dart';

void main() {
  group('토큰 갱신 통합 테스트', () {
    late MockAuthProvider mockKakao;
    late MockAuthProvider mockApple;
    late KAuth kAuth;

    setUp(() {
      mockKakao = MockAuthProvider.success(AuthProvider.kakao);
      mockApple = MockAuthProvider.success(AuthProvider.apple);
      kAuth = TestKAuthFactory.withMockProviders(
        providers: {
          AuthProvider.kakao: mockKakao,
          AuthProvider.apple: mockApple,
        },
      );
    });

    tearDown(() {
      kAuth.dispose();
    });

    group('수동 토큰 갱신', () {
      test('로그인 상태에서 refreshToken 성공', () async {
        await kAuth.signIn(AuthProvider.kakao);
        expect(kAuth.isSignedIn, true);

        final result = await kAuth.refreshToken();

        expect(result.success, true);
        expect(mockKakao.refreshTokenCalled, true);
      });

      test('미로그인 상태에서 refreshToken 실패', () async {
        final result = await kAuth.refreshToken();

        expect(result.success, false);
        expect(result.errorCode, ErrorCodes.refreshFailed);
      });

      test('Apple Provider는 토큰 갱신 미지원', () async {
        await kAuth.signIn(AuthProvider.apple);

        final result = await kAuth.refreshToken(AuthProvider.apple);

        expect(result.success, false);
        expect(result.errorCode, ErrorCodes.providerNotSupported);
        expect(mockApple.refreshTokenCalled, false);
      });

      test('특정 Provider 지정하여 갱신', () async {
        await kAuth.signIn(AuthProvider.kakao);

        final result = await kAuth.refreshToken(AuthProvider.kakao);

        expect(result.success, true);
        expect(mockKakao.refreshTokenCalled, true);
      });
    });

    group('토큰 만료 확인', () {
      test('isExpired가 만료된 토큰에서 true 반환', () async {
        mockKakao.signInResult = AuthResult.success(
          provider: AuthProvider.kakao,
          user: KAuthUser(id: 'test', provider: AuthProvider.kakao),
          expiresAt: DateTime.now().subtract(Duration(hours: 1)),
        );

        await kAuth.signIn(AuthProvider.kakao);

        expect(kAuth.isExpired, true);
      });

      test('isExpiringSoon이 만료 임박 토큰에서 true 반환', () async {
        mockKakao.signInResult = AuthResult.success(
          provider: AuthProvider.kakao,
          user: KAuthUser(id: 'test', provider: AuthProvider.kakao),
          expiresAt: DateTime.now().add(Duration(minutes: 3)),
        );

        await kAuth.signIn(AuthProvider.kakao);

        expect(kAuth.isExpiringSoon(), true);
        expect(kAuth.isExpiringSoon(Duration(minutes: 1)), false);
      });

      test('expiresIn이 남은 시간 반환', () async {
        final expiresAt = DateTime.now().add(Duration(hours: 1));
        mockKakao.signInResult = AuthResult.success(
          provider: AuthProvider.kakao,
          user: KAuthUser(id: 'test', provider: AuthProvider.kakao),
          expiresAt: expiresAt,
        );

        await kAuth.signIn(AuthProvider.kakao);

        expect(kAuth.expiresIn.inMinutes, greaterThanOrEqualTo(59));
      });
    });

    group('갱신 실패 처리', () {
      test('갱신 실패 시 기존 상태 유지', () async {
        await kAuth.signIn(AuthProvider.kakao);
        expect(kAuth.isSignedIn, true);

        mockKakao.refreshTokenResult = AuthResult.failure(
          provider: AuthProvider.kakao,
          errorCode: ErrorCodes.refreshFailed,
          errorMessage: '갱신 실패',
        );

        final result = await kAuth.refreshToken();

        expect(result.success, false);
        expect(kAuth.isSignedIn, true); // 기존 상태 유지
      });
    });
  });
}
