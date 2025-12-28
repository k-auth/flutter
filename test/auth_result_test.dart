import 'package:flutter_test/flutter_test.dart';
import 'package:k_auth/k_auth.dart';

void main() {
  // ============================================
  // AuthResult 테스트
  // ============================================
  group('AuthResult', () {
    group('timeUntilExpiry', () {
      test('올바르게 계산된다', () {
        final user = KAuthUser(id: '1', provider: AuthProvider.kakao);
        final futureTime = DateTime.now().add(const Duration(hours: 1));

        final result = AuthResult.success(
          provider: AuthProvider.kakao,
          user: user,
          expiresAt: futureTime,
        );

        final remaining = result.timeUntilExpiry;
        expect(remaining, isNotNull);
        expect(remaining!.inMinutes, greaterThanOrEqualTo(59));
        expect(remaining.inMinutes, lessThanOrEqualTo(60));
      });

      test('만료된 경우 Duration.zero를 반환한다', () {
        final user = KAuthUser(id: '1', provider: AuthProvider.kakao);
        final pastTime = DateTime.now().subtract(const Duration(hours: 1));

        final result = AuthResult.success(
          provider: AuthProvider.kakao,
          user: user,
          expiresAt: pastTime,
        );

        expect(result.timeUntilExpiry, Duration.zero);
      });

      test('expiresAt이 null이면 null을 반환한다', () {
        final user = KAuthUser(id: '1', provider: AuthProvider.kakao);

        final result = AuthResult.success(
          provider: AuthProvider.kakao,
          user: user,
        );

        expect(result.timeUntilExpiry, isNull);
      });
    });

    group('isExpired', () {
      test('expiresAt이 null이면 false', () {
        final user = KAuthUser(id: '1', provider: AuthProvider.kakao);
        final result = AuthResult.success(
          provider: AuthProvider.kakao,
          user: user,
        );

        expect(result.isExpired, false);
      });

      test('미래 시간이면 false', () {
        final user = KAuthUser(id: '1', provider: AuthProvider.kakao);
        final result = AuthResult.success(
          provider: AuthProvider.kakao,
          user: user,
          expiresAt: DateTime.now().add(const Duration(hours: 1)),
        );

        expect(result.isExpired, false);
      });

      test('과거 시간이면 true', () {
        final user = KAuthUser(id: '1', provider: AuthProvider.kakao);
        final result = AuthResult.success(
          provider: AuthProvider.kakao,
          user: user,
          expiresAt: DateTime.now().subtract(const Duration(hours: 1)),
        );

        expect(result.isExpired, true);
      });
    });

    group('isExpiringSoon', () {
      test('곧 만료될 예정이면 true', () {
        final user = KAuthUser(id: '1', provider: AuthProvider.kakao);
        final result = AuthResult.success(
          provider: AuthProvider.kakao,
          user: user,
          expiresAt: DateTime.now().add(const Duration(minutes: 3)),
        );

        expect(result.isExpiringSoon(), true);
      });

      test('아직 여유가 있으면 false', () {
        final user = KAuthUser(id: '1', provider: AuthProvider.kakao);
        final result = AuthResult.success(
          provider: AuthProvider.kakao,
          user: user,
          expiresAt: DateTime.now().add(const Duration(hours: 1)),
        );

        expect(result.isExpiringSoon(), false);
      });

      test('커스텀 threshold 사용', () {
        final user = KAuthUser(id: '1', provider: AuthProvider.kakao);
        final result = AuthResult.success(
          provider: AuthProvider.kakao,
          user: user,
          expiresAt: DateTime.now().add(const Duration(minutes: 15)),
        );

        expect(result.isExpiringSoon(const Duration(minutes: 10)), false);
        expect(result.isExpiringSoon(const Duration(minutes: 20)), true);
      });
    });

    group('toString', () {
      test('성공 결과에서 올바른 형식을 반환한다', () {
        final user = KAuthUser(id: '123', provider: AuthProvider.kakao);

        final result = AuthResult.success(
          provider: AuthProvider.kakao,
          user: user,
        );

        final str = result.toString();
        expect(str, contains('AuthResult.success'));
        expect(str, contains('kakao'));
      });

      test('실패 결과에서 올바른 형식을 반환한다', () {
        final result = AuthResult.failure(
          provider: AuthProvider.naver,
          errorMessage: '로그인 실패',
        );

        final str = result.toString();
        expect(str, contains('AuthResult.failure'));
        expect(str, contains('naver'));
        expect(str, contains('로그인 실패'));
      });
    });

    group('toJson/fromJson', () {
      test('성공 결과 직렬화', () {
        final user = KAuthUser(id: '123', provider: AuthProvider.kakao);
        final result = AuthResult.success(
          provider: AuthProvider.kakao,
          user: user,
          accessToken: 'token',
        );

        final json = result.toJson();
        final restored = AuthResult.fromJson(json);

        expect(restored.success, true);
        expect(restored.provider, AuthProvider.kakao);
        expect(restored.user?.id, '123');
        expect(restored.accessToken, 'token');
      });

      test('실패 결과 직렬화', () {
        final result = AuthResult.failure(
          provider: AuthProvider.naver,
          errorMessage: '에러',
          errorCode: 'ERROR_CODE',
        );

        final json = result.toJson();
        final restored = AuthResult.fromJson(json);

        expect(restored.success, false);
        expect(restored.errorMessage, '에러');
        expect(restored.errorCode, 'ERROR_CODE');
      });

      test('알 수 없는 provider는 kakao로 fallback', () {
        final json = {
          'success': true,
          'provider': 'unknown',
          'user': {
            'id': '123',
            'provider': 'kakao',
          },
        };

        final result = AuthResult.fromJson(json);

        expect(result.provider, AuthProvider.kakao);
      });

      test('rawData가 있는 경우', () {
        final json = {
          'success': true,
          'provider': 'google',
          'rawData': {'custom': 'data'},
        };

        final result = AuthResult.fromJson(json);

        expect(result.rawData, {'custom': 'data'});
      });
    });

    group('fold', () {
      test('성공 시 onSuccess 호출', () {
        final user = KAuthUser(id: '1', provider: AuthProvider.kakao);
        final result = AuthResult.success(
          provider: AuthProvider.kakao,
          user: user,
        );

        final value = result.fold(
          onSuccess: (u) => 'success: ${u.id}',
          onFailure: (f) => 'failure',
        );

        expect(value, 'success: 1');
      });

      test('실패 시 onFailure 호출', () {
        final result = AuthResult.failure(
          provider: AuthProvider.kakao,
          errorMessage: '에러',
        );

        final value = result.fold(
          onSuccess: (u) => 'success',
          onFailure: (f) => 'failure: ${f.message}',
        );

        expect(value, 'failure: 에러');
      });
    });

    group('when', () {
      test('성공 시 success 호출', () {
        final user = KAuthUser(id: '1', provider: AuthProvider.kakao);
        final result = AuthResult.success(
          provider: AuthProvider.kakao,
          user: user,
        );

        final value = result.when(
          success: (u) => 'success',
          cancelled: () => 'cancelled',
          failure: (f) => 'failure',
        );

        expect(value, 'success');
      });

      test('취소 시 cancelled 호출', () {
        final result = AuthResult.failure(
          provider: AuthProvider.kakao,
          errorMessage: '취소됨',
          errorCode: 'USER_CANCELLED',
        );

        final value = result.when(
          success: (u) => 'success',
          cancelled: () => 'cancelled',
          failure: (f) => 'failure',
        );

        expect(value, 'cancelled');
      });

      test('일반 실패 시 failure 호출', () {
        final result = AuthResult.failure(
          provider: AuthProvider.kakao,
          errorMessage: '에러',
          errorCode: 'ERROR',
        );

        final value = result.when(
          success: (u) => 'success',
          cancelled: () => 'cancelled',
          failure: (f) => 'failure',
        );

        expect(value, 'failure');
      });
    });

    group('onSuccess/onFailure', () {
      test('onSuccess 체이닝', () {
        final user = KAuthUser(id: '1', provider: AuthProvider.kakao);
        final result = AuthResult.success(
          provider: AuthProvider.kakao,
          user: user,
        );

        var called = false;
        result.onSuccess((u) => called = true);

        expect(called, true);
      });

      test('onFailure 체이닝', () {
        final result = AuthResult.failure(
          provider: AuthProvider.kakao,
          errorMessage: '에러',
        );

        var called = false;
        result.onFailure((f) => called = true);

        expect(called, true);
      });
    });

    group('mapUser/mapUserOr', () {
      test('mapUser가 성공 시 값을 반환', () {
        final user = KAuthUser(
          id: '1',
          provider: AuthProvider.kakao,
          name: 'Test',
        );
        final result = AuthResult.success(
          provider: AuthProvider.kakao,
          user: user,
        );

        final name = result.mapUser((u) => u.name);
        expect(name, 'Test');
      });

      test('mapUser가 실패 시 null 반환', () {
        final result = AuthResult.failure(
          provider: AuthProvider.kakao,
          errorMessage: '에러',
        );

        final name = result.mapUser((u) => u.name);
        expect(name, isNull);
      });

      test('mapUserOr가 성공 시 값을 반환', () {
        final user = KAuthUser(
          id: '1',
          provider: AuthProvider.kakao,
          name: 'Test',
        );
        final result = AuthResult.success(
          provider: AuthProvider.kakao,
          user: user,
        );

        final name = result.mapUserOr((u) => u.name, 'Default');
        expect(name, 'Test');
      });

      test('mapUserOr가 실패 시 기본값 반환', () {
        final result = AuthResult.failure(
          provider: AuthProvider.kakao,
          errorMessage: '에러',
        );

        final name = result.mapUserOr((u) => u.name, 'Default');
        expect(name, 'Default');
      });
    });
  });

  // ============================================
  // AuthProvider 테스트
  // ============================================
  group('AuthProvider', () {
    test('displayName이 올바르다', () {
      expect(AuthProvider.kakao.displayName, '카카오');
      expect(AuthProvider.naver.displayName, '네이버');
      expect(AuthProvider.google.displayName, 'Google');
      expect(AuthProvider.apple.displayName, 'Apple');
    });

    test('englishName이 올바르다', () {
      expect(AuthProvider.kakao.englishName, 'Kakao');
      expect(AuthProvider.naver.englishName, 'Naver');
      expect(AuthProvider.google.englishName, 'Google');
      expect(AuthProvider.apple.englishName, 'Apple');
    });

    test('supportsUnlink가 올바르다', () {
      expect(AuthProvider.kakao.supportsUnlink, true);
      expect(AuthProvider.naver.supportsUnlink, true);
      expect(AuthProvider.google.supportsUnlink, true);
      expect(AuthProvider.apple.supportsUnlink, false);
    });

    test('supportsTokenRefresh가 올바르다', () {
      expect(AuthProvider.kakao.supportsTokenRefresh, true);
      expect(AuthProvider.naver.supportsTokenRefresh, true);
      expect(AuthProvider.google.supportsTokenRefresh, true);
      expect(AuthProvider.apple.supportsTokenRefresh, false);
    });
  });
}
