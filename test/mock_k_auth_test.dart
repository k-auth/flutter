import 'package:flutter_test/flutter_test.dart';
import 'package:k_auth/k_auth.dart';

void main() {
  group('MockKAuth', () {
    late MockKAuth mockKAuth;

    setUp(() {
      mockKAuth = MockKAuth();
    });

    tearDown(() {
      mockKAuth.dispose();
    });

    group('초기 상태', () {
      test('기본값 확인', () {
        expect(mockKAuth.isInitialized, false);
        expect(mockKAuth.isSignedIn, false);
        expect(mockKAuth.currentUser, null);
        expect(mockKAuth.currentProvider, null);
        expect(mockKAuth.serverToken, null);
      });

      test('configuredProviders 기본값은 모든 Provider', () {
        expect(mockKAuth.configuredProviders, [
          AuthProvider.kakao,
          AuthProvider.naver,
          AuthProvider.google,
          AuthProvider.apple,
        ]);
      });
    });

    group('signedIn factory', () {
      test('이미 로그인된 상태로 생성', () {
        final user = KAuthUser(
          id: 'test_123',
          provider: AuthProvider.kakao,
          email: 'test@example.com',
        );

        final mock = MockKAuth.signedIn(user: user, serverToken: 'jwt_token');

        expect(mock.isInitialized, true);
        expect(mock.isSignedIn, true);
        expect(mock.currentUser, user);
        expect(mock.userId, 'test_123');
        expect(mock.email, 'test@example.com');
        expect(mock.serverToken, 'jwt_token');
        expect(mock.currentProvider, AuthProvider.kakao);

        mock.dispose();
      });
    });

    group('signIn', () {
      test('mockUser가 있으면 성공', () async {
        final user = KAuthUser(
          id: 'user_123',
          provider: AuthProvider.kakao,
          name: 'Test User',
          email: 'test@test.com',
        );
        mockKAuth.mockUser = user;

        final result = await mockKAuth.signIn(AuthProvider.kakao);

        expect(result.success, true);
        expect(result.user?.id, 'user_123');
        expect(result.user?.name, 'Test User');
        expect(mockKAuth.isSignedIn, true);
        expect(mockKAuth.currentUser?.id, 'user_123');
      });

      test('mockFailure가 있으면 실패', () async {
        mockKAuth.mockFailure = KAuthFailure(
          code: 'USER_CANCELLED',
          message: '사용자가 로그인을 취소했습니다',
        );

        final result = await mockKAuth.signIn(AuthProvider.naver);

        expect(result.success, false);
        expect(result.errorCode, 'USER_CANCELLED');
        expect(result.errorMessage, '사용자가 로그인을 취소했습니다');
        expect(mockKAuth.isSignedIn, false);
      });

      test('mockUser/mockFailure 없으면 자동 생성된 사용자로 성공', () async {
        final result = await mockKAuth.signIn(AuthProvider.google);

        expect(result.success, true);
        expect(result.user, isNotNull);
        expect(result.user?.provider, AuthProvider.google);
        expect(mockKAuth.isSignedIn, true);
      });

      test('signIn 후 authStateChanges 스트림 발생', () async {
        final user = KAuthUser(id: 'stream_test', provider: AuthProvider.apple);
        mockKAuth.mockUser = user;

        final states = <KAuthUser?>[];
        final subscription = mockKAuth.authStateChanges.listen(states.add);

        await mockKAuth.signIn(AuthProvider.apple);
        await Future.delayed(Duration.zero);

        expect(states.length, 1);
        expect(states.first?.id, 'stream_test');

        await subscription.cancel();
      });
    });

    group('signOut', () {
      test('로그아웃 성공', () async {
        // 먼저 로그인
        mockKAuth.mockUser =
            KAuthUser(id: 'user', provider: AuthProvider.kakao);
        await mockKAuth.signIn(AuthProvider.kakao);
        expect(mockKAuth.isSignedIn, true);

        // 로그아웃
        final result = await mockKAuth.signOut();

        expect(result.success, true);
        expect(mockKAuth.isSignedIn, false);
        expect(mockKAuth.currentUser, null);
      });

      test('signOutAll 성공', () async {
        // 먼저 로그인
        mockKAuth.mockUser =
            KAuthUser(id: 'user', provider: AuthProvider.kakao);
        await mockKAuth.signIn(AuthProvider.kakao);

        // 전체 로그아웃
        final results = await mockKAuth.signOutAll();

        expect(results.length, 4);
        expect(results.every((r) => r.success), true);
        expect(mockKAuth.isSignedIn, false);
      });
    });

    group('unlink', () {
      test('지원되는 Provider 연결해제 성공', () async {
        mockKAuth.mockUser =
            KAuthUser(id: 'user', provider: AuthProvider.kakao);
        await mockKAuth.signIn(AuthProvider.kakao);

        final result = await mockKAuth.unlink(AuthProvider.kakao);

        expect(result.success, true);
        expect(mockKAuth.isSignedIn, false);
      });

      test('Apple 연결해제 실패', () async {
        final result = await mockKAuth.unlink(AuthProvider.apple);

        expect(result.success, false);
        expect(result.errorCode, 'PROVIDER_NOT_SUPPORTED');
      });
    });

    group('refreshToken', () {
      test('로그인 상태에서 토큰 갱신 성공', () async {
        mockKAuth.mockUser =
            KAuthUser(id: 'user', provider: AuthProvider.kakao);
        await mockKAuth.signIn(AuthProvider.kakao);

        final result = await mockKAuth.refreshToken();

        expect(result.success, true);
        expect(result.accessToken, contains('refreshed'));
      });

      test('미로그인 상태에서 실패', () async {
        final result = await mockKAuth.refreshToken();

        expect(result.success, false);
        expect(result.errorCode, 'REFRESH_FAILED');
      });

      test('Apple 토큰 갱신 미지원', () async {
        mockKAuth.mockUser =
            KAuthUser(id: 'user', provider: AuthProvider.apple);
        await mockKAuth.signIn(AuthProvider.apple);

        final result = await mockKAuth.refreshToken(AuthProvider.apple);

        expect(result.success, false);
        expect(result.errorCode, 'PROVIDER_NOT_SUPPORTED');
      });
    });

    group('편의 getter', () {
      test('userId, name, email, avatar', () async {
        mockKAuth.mockUser = KAuthUser(
          id: 'id_123',
          provider: AuthProvider.kakao,
          name: 'Name',
          email: 'email@test.com',
          avatar: 'https://avatar.url',
        );
        await mockKAuth.signIn(AuthProvider.kakao);

        expect(mockKAuth.userId, 'id_123');
        expect(mockKAuth.name, 'Name');
        expect(mockKAuth.email, 'email@test.com');
        expect(mockKAuth.avatar, 'https://avatar.url');
      });
    });

    group('헬퍼 메서드', () {
      test('setSignedIn', () {
        final user = KAuthUser(id: 'helper_test', provider: AuthProvider.naver);

        mockKAuth.setSignedIn(user, serverToken: 'token');

        expect(mockKAuth.isSignedIn, true);
        expect(mockKAuth.currentUser?.id, 'helper_test');
        expect(mockKAuth.serverToken, 'token');
      });

      test('setSignedOut', () {
        mockKAuth.setSignedIn(
          KAuthUser(id: 'user', provider: AuthProvider.kakao),
        );
        expect(mockKAuth.isSignedIn, true);

        mockKAuth.setSignedOut();

        expect(mockKAuth.isSignedIn, false);
      });

      test('setFailure', () async {
        mockKAuth.setFailure(
          code: 'CUSTOM_ERROR',
          message: 'Custom error message',
        );

        final result = await mockKAuth.signIn(AuthProvider.kakao);

        expect(result.success, false);
        expect(result.errorCode, 'CUSTOM_ERROR');
      });

      test('setCancelled', () async {
        mockKAuth.setCancelled();

        final result = await mockKAuth.signIn(AuthProvider.kakao);

        expect(result.success, false);
        expect(result.errorCode, 'USER_CANCELLED');
      });

      test('setNetworkError', () async {
        mockKAuth.setNetworkError();

        final result = await mockKAuth.signIn(AuthProvider.google);

        expect(result.success, false);
        expect(result.errorCode, 'NETWORK_ERROR');
      });

      test('setTimeout', () async {
        mockKAuth.setTimeout();

        final result = await mockKAuth.signIn(AuthProvider.kakao);

        expect(result.success, false);
        expect(result.errorCode, 'TIMEOUT');
      });

      test('simulateTokenExpiry', () async {
        mockKAuth.simulateTokenExpiry();

        final result = await mockKAuth.signIn(AuthProvider.kakao);

        expect(result.success, false);
        expect(result.errorCode, 'TOKEN_EXPIRED');
      });

      test('simulateAuthStateChange', () async {
        final states = <KAuthUser?>[];
        final subscription = mockKAuth.authStateChanges.listen(states.add);

        final user =
            KAuthUser(id: 'state_change', provider: AuthProvider.naver);
        mockKAuth.simulateAuthStateChange(user);
        await Future.delayed(Duration.zero);

        expect(states.length, 1);
        expect(states.first?.id, 'state_change');
        expect(mockKAuth.currentUser?.id, 'state_change');

        await subscription.cancel();
      });

      test('reset', () async {
        mockKAuth.mockUser =
            KAuthUser(id: 'user', provider: AuthProvider.kakao);
        await mockKAuth.signIn(AuthProvider.kakao);
        expect(mockKAuth.isSignedIn, true);

        mockKAuth.reset();

        expect(mockKAuth.isInitialized, false);
        expect(mockKAuth.isSignedIn, false);
        expect(mockKAuth.mockUser, null);
        expect(mockKAuth.mockFailure, null);
      });
    });

    group('mockDelay', () {
      test('지연 시간 적용', () async {
        mockKAuth.mockDelay = Duration(milliseconds: 100);

        final stopwatch = Stopwatch()..start();
        await mockKAuth.signIn(AuthProvider.kakao);
        stopwatch.stop();

        expect(stopwatch.elapsedMilliseconds, greaterThanOrEqualTo(100));
      });
    });

    group('isConfigured', () {
      test('기본값은 모든 Provider 설정됨', () {
        expect(mockKAuth.isConfigured(AuthProvider.kakao), true);
        expect(mockKAuth.isConfigured(AuthProvider.naver), true);
        expect(mockKAuth.isConfigured(AuthProvider.google), true);
        expect(mockKAuth.isConfigured(AuthProvider.apple), true);
      });

      test('특정 Provider만 설정', () {
        final mock = MockKAuth(
          mockConfiguredProviders: [AuthProvider.kakao],
        );

        expect(mock.isConfigured(AuthProvider.kakao), true);
        expect(mock.isConfigured(AuthProvider.naver), false);

        mock.dispose();
      });
    });
  });
}
