import 'package:flutter_test/flutter_test.dart';
import 'package:k_auth/k_auth.dart';

import '../helpers/test_utils.dart';

void main() {
  group('세션 라이프사이클 통합 테스트', () {
    late TestSessionStorage storage;
    late MockAuthProvider mockKakao;
    late KAuth kAuth;

    setUp(() {
      storage = TestSessionStorage();
      mockKakao = MockAuthProvider.success(AuthProvider.kakao);
      kAuth = TestKAuthFactory.withMockProviders(
        providers: {AuthProvider.kakao: mockKakao},
        storage: storage,
      );
    });

    tearDown(() {
      kAuth.dispose();
    });

    group('세션 저장', () {
      test('로그인 성공 시 세션이 저장된다', () async {
        await kAuth.signIn(AuthProvider.kakao);

        expect(storage.containsKey('k_auth_session'), true);
        expect(kAuth.isSignedIn, true);
      });

      test('로그아웃 시 세션이 삭제된다', () async {
        await kAuth.signIn(AuthProvider.kakao);
        expect(storage.containsKey('k_auth_session'), true);

        await kAuth.signOut();

        expect(storage.containsKey('k_auth_session'), false);
        expect(kAuth.isSignedIn, false);
      });

      test('unlink 시 세션이 삭제된다', () async {
        await kAuth.signIn(AuthProvider.kakao);
        expect(storage.containsKey('k_auth_session'), true);

        await kAuth.unlink(AuthProvider.kakao);

        expect(storage.containsKey('k_auth_session'), false);
        expect(kAuth.isSignedIn, false);
      });

      test('토큰 갱신 시 세션이 업데이트된다', () async {
        await kAuth.signIn(AuthProvider.kakao);
        final oldSession = await storage.read('k_auth_session');

        await kAuth.refreshToken();
        final newSession = await storage.read('k_auth_session');

        expect(newSession, isNot(equals(oldSession)));
      });
    });

    group('KAuthSession', () {
      test('세션 encode/decode가 올바르게 동작한다', () {
        final session = SessionScenarios.valid();
        final encoded = session.encode();
        final decoded = KAuthSession.decode(encoded);

        expect(decoded.provider, session.provider);
        expect(decoded.user.id, session.user.id);
        expect(decoded.accessToken, session.accessToken);
      });

      test('만료된 세션의 isExpired가 true를 반환한다', () {
        final expired = SessionScenarios.expired();
        expect(expired.isExpired, true);

        final valid = SessionScenarios.valid();
        expect(valid.isExpired, false);
      });
    });

    group('signIn → signOut 전체 플로우', () {
      test('로그인 → 세션 저장 → 로그아웃 → 세션 삭제', () async {
        final events = <KAuthUser?>[];
        final subscription = kAuth.authStateChanges.listen(events.add);

        // 로그인
        final signInResult = await kAuth.signIn(AuthProvider.kakao);
        expect(signInResult.success, true);
        expect(kAuth.isSignedIn, true);
        expect(storage.containsKey('k_auth_session'), true);

        // 로그아웃
        final signOutResult = await kAuth.signOut();
        expect(signOutResult.success, true);
        expect(kAuth.isSignedIn, false);
        expect(storage.containsKey('k_auth_session'), false);

        // 스트림 이벤트 확인
        await Future.delayed(Duration.zero);
        expect(events.length, 2);
        expect(events[0]?.id, 'mock_user_id');
        expect(events[1], isNull);

        await subscription.cancel();
      });

      test('로그인 실패 시 세션 저장 안됨', () async {
        mockKakao.signInResult = AuthResult.failure(
          provider: AuthProvider.kakao,
          errorCode: ErrorCodes.loginFailed,
          errorMessage: '로그인 실패',
        );

        await kAuth.signIn(AuthProvider.kakao);

        expect(kAuth.isSignedIn, false);
        expect(storage.containsKey('k_auth_session'), false);
      });
    });
  });
}
