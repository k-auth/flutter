import 'package:flutter_test/flutter_test.dart';
import 'package:k_auth/k_auth.dart';

// TokenUtils는 내부용이지만 KAuth/AuthResult/MockKAuth를 통해 테스트
void main() {
  group('TokenUtils (via KAuth)', () {
    late MockKAuth mockKAuth;

    setUp(() {
      mockKAuth = MockKAuth();
    });

    tearDown(() {
      mockKAuth.dispose();
    });

    group('isExpired', () {
      test('expiresAt이 null이면 false', () {
        expect(mockKAuth.isExpired, false);
      });

      test('만료 시간이 지났으면 true', () {
        mockKAuth.mockUser =
            KAuthUser(id: 'test', provider: AuthProvider.kakao);
        mockKAuth.expireAfter(Duration.zero);
        // 즉시 만료되도록 설정
        mockKAuth.expireNow();

        expect(mockKAuth.isExpired, true);
      });

      test('만료 시간이 안 지났으면 false', () {
        mockKAuth.mockUser =
            KAuthUser(id: 'test', provider: AuthProvider.kakao);
        mockKAuth.expireAfter(Duration(hours: 1));

        expect(mockKAuth.isExpired, false);
      });
    });

    group('isExpiringSoon', () {
      test('expiresAt이 null이면 false', () {
        expect(mockKAuth.isExpiringSoon(), false);
      });

      test('5분 이내 만료 예정이면 true (기본값)', () {
        mockKAuth.mockUser =
            KAuthUser(id: 'test', provider: AuthProvider.kakao);
        mockKAuth.expireAfter(Duration(minutes: 3));

        expect(mockKAuth.isExpiringSoon(), true);
      });

      test('5분 이상 남았으면 false (기본값)', () {
        mockKAuth.mockUser =
            KAuthUser(id: 'test', provider: AuthProvider.kakao);
        mockKAuth.expireAfter(Duration(minutes: 10));

        expect(mockKAuth.isExpiringSoon(), false);
      });

      test('커스텀 threshold 지원', () {
        mockKAuth.mockUser =
            KAuthUser(id: 'test', provider: AuthProvider.kakao);
        mockKAuth.expireAfter(Duration(minutes: 3));

        // 2분 threshold로는 만료 임박 아님
        expect(mockKAuth.isExpiringSoon(Duration(minutes: 2)), false);

        // 5분 threshold로는 만료 임박
        expect(mockKAuth.isExpiringSoon(Duration(minutes: 5)), true);
      });
    });

    group('expiresIn', () {
      test('expiresAt이 null이면 Duration.zero', () {
        expect(mockKAuth.expiresIn, Duration.zero);
      });

      test('이미 만료되었으면 Duration.zero', () {
        mockKAuth.mockUser =
            KAuthUser(id: 'test', provider: AuthProvider.kakao);
        mockKAuth.expireNow();

        expect(mockKAuth.expiresIn, Duration.zero);
      });

      test('남은 시간 반환', () {
        mockKAuth.mockUser =
            KAuthUser(id: 'test', provider: AuthProvider.kakao);
        mockKAuth.expireAfter(Duration(hours: 1));

        // 약간의 오차 허용 (테스트 실행 시간)
        expect(mockKAuth.expiresIn.inMinutes, greaterThanOrEqualTo(59));
        expect(mockKAuth.expiresIn.inMinutes, lessThanOrEqualTo(60));
      });
    });
  });

  group('TokenUtils (via AuthResult)', () {
    group('isExpired', () {
      test('expiresAt이 null이면 false', () {
        final result = AuthResult.success(
          provider: AuthProvider.kakao,
          user: KAuthUser(id: 'test', provider: AuthProvider.kakao),
        );

        expect(result.isExpired, false);
      });

      test('만료 시간이 지났으면 true', () {
        final result = AuthResult.success(
          provider: AuthProvider.kakao,
          user: KAuthUser(id: 'test', provider: AuthProvider.kakao),
          expiresAt: DateTime.now().subtract(Duration(hours: 1)),
        );

        expect(result.isExpired, true);
      });

      test('만료 시간이 안 지났으면 false', () {
        final result = AuthResult.success(
          provider: AuthProvider.kakao,
          user: KAuthUser(id: 'test', provider: AuthProvider.kakao),
          expiresAt: DateTime.now().add(Duration(hours: 1)),
        );

        expect(result.isExpired, false);
      });
    });

    group('isExpiringSoon', () {
      test('expiresAt이 null이면 false', () {
        final result = AuthResult.success(
          provider: AuthProvider.kakao,
          user: KAuthUser(id: 'test', provider: AuthProvider.kakao),
        );

        expect(result.isExpiringSoon(), false);
      });

      test('5분 이내 만료 예정이면 true', () {
        final result = AuthResult.success(
          provider: AuthProvider.kakao,
          user: KAuthUser(id: 'test', provider: AuthProvider.kakao),
          expiresAt: DateTime.now().add(Duration(minutes: 3)),
        );

        expect(result.isExpiringSoon(), true);
      });

      test('5분 이상 남았으면 false', () {
        final result = AuthResult.success(
          provider: AuthProvider.kakao,
          user: KAuthUser(id: 'test', provider: AuthProvider.kakao),
          expiresAt: DateTime.now().add(Duration(minutes: 10)),
        );

        expect(result.isExpiringSoon(), false);
      });
    });

    group('timeUntilExpiry', () {
      test('expiresAt이 null이면 null', () {
        final result = AuthResult.success(
          provider: AuthProvider.kakao,
          user: KAuthUser(id: 'test', provider: AuthProvider.kakao),
        );

        expect(result.timeUntilExpiry, null);
      });

      test('이미 만료되었으면 Duration.zero', () {
        final result = AuthResult.success(
          provider: AuthProvider.kakao,
          user: KAuthUser(id: 'test', provider: AuthProvider.kakao),
          expiresAt: DateTime.now().subtract(Duration(hours: 1)),
        );

        expect(result.timeUntilExpiry, Duration.zero);
      });

      test('남은 시간 반환', () {
        final result = AuthResult.success(
          provider: AuthProvider.kakao,
          user: KAuthUser(id: 'test', provider: AuthProvider.kakao),
          expiresAt: DateTime.now().add(Duration(hours: 1)),
        );

        expect(result.timeUntilExpiry!.inMinutes, greaterThanOrEqualTo(59));
        expect(result.timeUntilExpiry!.inMinutes, lessThanOrEqualTo(60));
      });
    });
  });

  group('일관성 검증', () {
    test('KAuth, AuthResult, MockKAuth의 토큰 만료 로직이 일관적이다', () {
      final expiresAt = DateTime.now().add(Duration(minutes: 3));

      // AuthResult
      final result = AuthResult.success(
        provider: AuthProvider.kakao,
        user: KAuthUser(id: 'test', provider: AuthProvider.kakao),
        expiresAt: expiresAt,
      );

      // MockKAuth
      final mockKAuth = MockKAuth();
      mockKAuth.mockUser = KAuthUser(id: 'test', provider: AuthProvider.kakao);
      mockKAuth.expireAfter(Duration(minutes: 3));

      // 모두 동일한 결과를 반환해야 함
      expect(result.isExpired, false);
      expect(mockKAuth.isExpired, false);

      expect(result.isExpiringSoon(), true);
      expect(mockKAuth.isExpiringSoon(), true);

      expect(result.isExpiringSoon(Duration(minutes: 2)), false);
      expect(mockKAuth.isExpiringSoon(Duration(minutes: 2)), false);

      mockKAuth.dispose();
    });
  });
}
