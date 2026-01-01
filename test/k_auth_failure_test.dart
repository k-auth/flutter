import 'package:flutter_test/flutter_test.dart';
import 'package:k_auth/k_auth.dart';

void main() {
  // ============================================
  // KAuthFailure 테스트
  // ============================================
  group('KAuthFailure', () {
    group('편의 getter', () {
      test('isCancelled가 올바르게 동작한다', () {
        final cancelled = KAuthFailure.fromCode(ErrorCodes.userCancelled);
        final other = KAuthFailure.fromCode(ErrorCodes.loginFailed);

        expect(cancelled.isCancelled, true);
        expect(other.isCancelled, false);
      });

      test('isNetworkError가 올바르게 동작한다', () {
        final networkError = KAuthFailure.fromCode(ErrorCodes.networkError);
        final otherError = KAuthFailure.fromCode(ErrorCodes.loginFailed);

        expect(networkError.isNetworkError, true);
        expect(otherError.isNetworkError, false);
      });

      test('isTokenExpired가 올바르게 동작한다', () {
        final tokenExpired = KAuthFailure.fromCode(ErrorCodes.tokenExpired);
        final otherError = KAuthFailure.fromCode(ErrorCodes.loginFailed);

        expect(tokenExpired.isTokenExpired, true);
        expect(otherError.isTokenExpired, false);
      });

      test('isProviderNotConfigured가 올바르게 동작한다', () {
        final notConfigured =
            KAuthFailure.fromCode(ErrorCodes.providerNotConfigured);
        final otherError = KAuthFailure.fromCode(ErrorCodes.loginFailed);

        expect(notConfigured.isProviderNotConfigured, true);
        expect(otherError.isProviderNotConfigured, false);
      });

      test('code가 null일 때 편의 getter가 false를 반환한다', () {
        const failure = KAuthFailure(message: '에러');

        expect(failure.isCancelled, false);
        expect(failure.isNetworkError, false);
        expect(failure.isTokenExpired, false);
        expect(failure.isProviderNotConfigured, false);
      });

      test('canRetry가 네트워크/타임아웃 에러에서 true를 반환한다', () {
        final networkError = KAuthFailure.fromCode(ErrorCodes.networkError);
        final timeoutError = KAuthFailure.fromCode(ErrorCodes.timeout);
        final otherError = KAuthFailure.fromCode(ErrorCodes.loginFailed);

        expect(networkError.canRetry, true);
        expect(timeoutError.canRetry, true);
        expect(otherError.canRetry, false);
      });

      test('shouldIgnore가 취소 에러에서 true를 반환한다', () {
        final cancelled = KAuthFailure.fromCode(ErrorCodes.userCancelled);
        final otherError = KAuthFailure.fromCode(ErrorCodes.loginFailed);

        expect(cancelled.shouldIgnore, true);
        expect(otherError.shouldIgnore, false);
      });

      test('isConfigError가 설정 관련 에러에서 true를 반환한다', () {
        final configErrors = [
          KAuthFailure.fromCode(ErrorCodes.providerNotConfigured),
          KAuthFailure.fromCode(ErrorCodes.missingAppKey),
          KAuthFailure.fromCode(ErrorCodes.missingClientId),
          KAuthFailure.fromCode(ErrorCodes.missingClientSecret),
          KAuthFailure.fromCode(ErrorCodes.invalidConfig),
          KAuthFailure.fromCode(ErrorCodes.noProviderConfigured),
        ];

        for (final error in configErrors) {
          expect(error.isConfigError, true, reason: 'code: ${error.code}');
        }

        final otherError = KAuthFailure.fromCode(ErrorCodes.loginFailed);
        expect(otherError.isConfigError, false);
      });

      test('isTemporary가 canRetry와 동일하다', () {
        final networkError = KAuthFailure.fromCode(ErrorCodes.networkError);
        final timeoutError = KAuthFailure.fromCode(ErrorCodes.timeout);
        final otherError = KAuthFailure.fromCode(ErrorCodes.loginFailed);

        expect(networkError.isTemporary, networkError.canRetry);
        expect(timeoutError.isTemporary, timeoutError.canRetry);
        expect(otherError.isTemporary, otherError.canRetry);
      });

      test('isPermanent가 재시도/무시 불가능한 에러에서 true를 반환한다', () {
        final permanentErrors = [
          KAuthFailure.fromCode(ErrorCodes.loginFailed),
          KAuthFailure.fromCode(ErrorCodes.invalidConfig),
        ];

        for (final error in permanentErrors) {
          expect(error.isPermanent, true, reason: 'code: ${error.code}');
        }

        // 재시도 가능하면 false
        final networkError = KAuthFailure.fromCode(ErrorCodes.networkError);
        expect(networkError.isPermanent, false);

        // 무시 가능하면 false
        final cancelled = KAuthFailure.fromCode(ErrorCodes.userCancelled);
        expect(cancelled.isPermanent, false);
      });

      test('requiresReauth가 재인증 필요 에러에서 true를 반환한다', () {
        final reauthErrors = [
          KAuthFailure.fromCode(ErrorCodes.tokenExpired),
          KAuthFailure.fromCode(ErrorCodes.refreshFailed),
          KAuthFailure.fromCode(ErrorCodes.accessTokenError),
        ];

        for (final error in reauthErrors) {
          expect(error.requiresReauth, true, reason: 'code: ${error.code}');
        }

        final otherError = KAuthFailure.fromCode(ErrorCodes.loginFailed);
        expect(otherError.requiresReauth, false);
      });
    });

    group('severity', () {
      test('취소 에러는 ignorable', () {
        final cancelled = KAuthFailure.fromCode(ErrorCodes.userCancelled);
        expect(cancelled.severity, ErrorSeverity.ignorable);
      });

      test('네트워크/타임아웃 에러는 retryable', () {
        final networkError = KAuthFailure.fromCode(ErrorCodes.networkError);
        final timeoutError = KAuthFailure.fromCode(ErrorCodes.timeout);

        expect(networkError.severity, ErrorSeverity.retryable);
        expect(timeoutError.severity, ErrorSeverity.retryable);
      });

      test('토큰 만료 에러는 authRequired', () {
        final tokenExpired = KAuthFailure.fromCode(ErrorCodes.tokenExpired);
        final refreshFailed = KAuthFailure.fromCode(ErrorCodes.refreshFailed);

        expect(tokenExpired.severity, ErrorSeverity.authRequired);
        expect(refreshFailed.severity, ErrorSeverity.authRequired);
      });

      test('설정/기타 에러는 fixRequired', () {
        final configError = KAuthFailure.fromCode(ErrorCodes.invalidConfig);
        final loginFailed = KAuthFailure.fromCode(ErrorCodes.loginFailed);

        expect(configError.severity, ErrorSeverity.fixRequired);
        expect(loginFailed.severity, ErrorSeverity.fixRequired);
      });

      test('severity 우선순위: ignorable > retryable > authRequired > fixRequired',
          () {
        // shouldIgnore가 true면 ignorable (canRetry여도)
        final cancelled = KAuthFailure.fromCode(ErrorCodes.userCancelled);
        expect(cancelled.severity, ErrorSeverity.ignorable);

        // canRetry가 true면 retryable
        final networkError = KAuthFailure.fromCode(ErrorCodes.networkError);
        expect(networkError.severity, ErrorSeverity.retryable);

        // requiresReauth가 true면 authRequired
        final tokenExpired = KAuthFailure.fromCode(ErrorCodes.tokenExpired);
        expect(tokenExpired.severity, ErrorSeverity.authRequired);

        // 나머지는 fixRequired
        final loginFailed = KAuthFailure.fromCode(ErrorCodes.loginFailed);
        expect(loginFailed.severity, ErrorSeverity.fixRequired);
      });
    });

    group('displayMessage', () {
      test('message가 있으면 message를 반환', () {
        const failure = KAuthFailure(message: '커스텀 메시지');

        expect(failure.displayMessage, '커스텀 메시지');
      });

      test('message가 null이면 기본 메시지를 반환', () {
        const failure = KAuthFailure();

        expect(failure.displayMessage, '알 수 없는 오류가 발생했습니다.');
      });
    });

    group('fromCode', () {
      test('ErrorCodes에 정의된 코드로 생성', () {
        final failure = KAuthFailure.fromCode(ErrorCodes.userCancelled);

        expect(failure.code, ErrorCodes.userCancelled);
        expect(failure.message, isNotNull);
      });

      test('알 수 없는 코드로 생성해도 동작', () {
        final failure = KAuthFailure.fromCode('UNKNOWN_CODE');

        expect(failure.code, 'UNKNOWN_CODE');
      });
    });

    group('toJson/fromJson', () {
      test('모든 필드가 있는 경우', () {
        const failure = KAuthFailure(
          code: 'ERROR_CODE',
          message: '에러 메시지',
          hint: '힌트',
        );

        final json = failure.toJson();
        expect(json['code'], 'ERROR_CODE');
        expect(json['message'], '에러 메시지');
        expect(json['hint'], '힌트');

        final restored = KAuthFailure.fromJson(json);
        expect(restored.code, 'ERROR_CODE');
        expect(restored.message, '에러 메시지');
        expect(restored.hint, '힌트');
      });

      test('null 필드가 있는 경우', () {
        const failure = KAuthFailure(message: '메시지만');

        final json = failure.toJson();
        expect(json.containsKey('code'), false);
        expect(json.containsKey('hint'), false);
        expect(json['message'], '메시지만');
      });
    });

    group('toString', () {
      test('code가 있는 경우', () {
        const failure = KAuthFailure(code: 'CODE', message: '메시지');

        final str = failure.toString();
        expect(str, contains('KAuthFailure'));
        expect(str, contains('CODE'));
        expect(str, contains('메시지'));
      });

      test('code가 없는 경우', () {
        const failure = KAuthFailure(message: '메시지만');

        final str = failure.toString();
        expect(str, contains('KAuthFailure'));
        expect(str, contains('메시지만'));
      });
    });

    group('equality', () {
      test('같은 값이면 equal', () {
        const failure1 = KAuthFailure(
          code: 'CODE',
          message: '메시지',
          hint: '힌트',
        );
        const failure2 = KAuthFailure(
          code: 'CODE',
          message: '메시지',
          hint: '힌트',
        );

        expect(failure1, equals(failure2));
        expect(failure1.hashCode, failure2.hashCode);
      });

      test('다른 값이면 not equal', () {
        const failure1 = KAuthFailure(code: 'CODE1', message: '메시지');
        const failure2 = KAuthFailure(code: 'CODE2', message: '메시지');

        expect(failure1, isNot(equals(failure2)));
      });
    });
  });
}
