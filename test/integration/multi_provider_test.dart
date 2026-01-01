import 'package:flutter_test/flutter_test.dart';
import 'package:k_auth/k_auth.dart';

import '../helpers/test_utils.dart';

void main() {
  group('멀티 Provider 통합 테스트', () {
    late MockAuthProvider mockKakao;
    late MockAuthProvider mockNaver;
    late MockAuthProvider mockGoogle;
    late KAuth kAuth;

    setUp(() {
      mockKakao = MockAuthProvider.success(AuthProvider.kakao);
      mockNaver = MockAuthProvider.success(AuthProvider.naver);
      mockGoogle = MockAuthProvider.success(AuthProvider.google);
      kAuth = TestKAuthFactory.withMockProviders(
        providers: {
          AuthProvider.kakao: mockKakao,
          AuthProvider.naver: mockNaver,
          AuthProvider.google: mockGoogle,
        },
      );
    });

    tearDown(() {
      kAuth.dispose();
    });

    group('Provider 전환', () {
      test('Provider A 로그인 → Provider B 로그인 시 전환', () async {
        // 카카오 로그인
        await kAuth.signIn(AuthProvider.kakao);
        expect(kAuth.currentProvider, AuthProvider.kakao);
        expect(kAuth.userId, 'mock_user_id');

        // 네이버로 전환
        await kAuth.signIn(AuthProvider.naver);
        expect(kAuth.currentProvider, AuthProvider.naver);
      });

      test('다른 Provider로 로그인해도 이전 Provider는 로그아웃되지 않음', () async {
        await kAuth.signIn(AuthProvider.kakao);
        await kAuth.signIn(AuthProvider.naver);

        // 카카오 signOut은 호출되지 않음
        expect(mockKakao.signOutCalled, false);
      });
    });

    group('signOutAll', () {
      test('signOutAll이 모든 설정된 Provider를 로그아웃', () async {
        await kAuth.signIn(AuthProvider.kakao);

        final results = await kAuth.signOutAll();

        expect(results.length, 3);
        expect(results.every((r) => r.success), true);
        expect(mockKakao.signOutCalled, true);
        expect(mockNaver.signOutCalled, true);
        expect(mockGoogle.signOutCalled, true);
      });

      test('signOutAll 후 isSignedIn이 false', () async {
        await kAuth.signIn(AuthProvider.kakao);
        expect(kAuth.isSignedIn, true);

        await kAuth.signOutAll();

        expect(kAuth.isSignedIn, false);
        expect(kAuth.currentUser, isNull);
        expect(kAuth.currentProvider, isNull);
      });
    });

    group('Provider 설정 확인', () {
      test('Mock으로 설정된 Provider만 사용 가능', () async {
        // Mock이 설정된 Provider는 성공
        final result = await kAuth.signIn(AuthProvider.kakao);
        expect(result.success, true);
      });

      test('isConfigured로 설정 여부 확인', () {
        // TestKAuthFactory가 모든 Provider를 config에 설정함
        expect(kAuth.isConfigured(AuthProvider.kakao), true);
        expect(kAuth.isConfigured(AuthProvider.naver), true);
        expect(kAuth.isConfigured(AuthProvider.google), true);
      });

      test('configuredProviders가 설정된 Provider 목록 반환', () {
        final providers = kAuth.configuredProviders;

        expect(providers, contains(AuthProvider.kakao));
        expect(providers, contains(AuthProvider.naver));
        expect(providers, contains(AuthProvider.google));
        expect(providers.length, greaterThanOrEqualTo(3));
      });
    });

    group('Provider별 특성', () {
      test('각 Provider의 supportsTokenRefresh 확인', () {
        expect(AuthProvider.kakao.supportsTokenRefresh, true);
        expect(AuthProvider.naver.supportsTokenRefresh, true);
        expect(AuthProvider.google.supportsTokenRefresh, true);
        expect(AuthProvider.apple.supportsTokenRefresh, false);
      });

      test('각 Provider의 supportsUnlink 확인', () {
        expect(AuthProvider.kakao.supportsUnlink, true);
        expect(AuthProvider.naver.supportsUnlink, true);
        expect(AuthProvider.google.supportsUnlink, true);
        expect(AuthProvider.apple.supportsUnlink, false);
      });
    });

    group('authStateChanges 스트림', () {
      test('Provider 전환 시 스트림에 새 사용자 발생', () async {
        final events = <KAuthUser?>[];
        final subscription = kAuth.authStateChanges.listen(events.add);

        await kAuth.signIn(AuthProvider.kakao);
        await kAuth.signIn(AuthProvider.naver);
        await kAuth.signOut();

        await Future.delayed(Duration.zero);

        expect(events.length, 3);
        expect(events[0]?.provider, AuthProvider.kakao);
        expect(events[1]?.provider, AuthProvider.naver);
        expect(events[2], isNull);

        await subscription.cancel();
      });
    });
  });
}
