import 'package:flutter_test/flutter_test.dart';
import 'package:k_auth/k_auth.dart';

void main() {
  group('PhoneConfig', () {
    test('기본 설정은 Firebase Provider', () {
      const config = PhoneConfig();
      expect(config.provider, PhoneProvider.firebase);
      expect(config.codeLength, 6);
      expect(config.resendDelay, const Duration(seconds: 60));
    });

    test('커스텀 설정', () {
      const config = PhoneConfig.custom(
        sendUrl: 'https://api.example.com/send',
        verifyUrl: 'https://api.example.com/verify',
        codeLength: 4,
        resendDelay: Duration(seconds: 30),
      );
      expect(config.provider, PhoneProvider.custom);
      expect(config.sendUrl, 'https://api.example.com/send');
      expect(config.verifyUrl, 'https://api.example.com/verify');
      expect(config.codeLength, 4);
    });

    test('Firebase 명시적 설정', () {
      const config = PhoneConfig.firebase(
        codeLength: 8,
        debug: true,
      );
      expect(config.provider, PhoneProvider.firebase);
      expect(config.codeLength, 8);
      expect(config.debug, true);
      expect(config.sendUrl, null);
      expect(config.verifyUrl, null);
    });
  });

  group('PhoneResult', () {
    test('성공 결과 생성', () {
      final result = PhoneResult.success(
        user: PhoneUser(
          phoneNumber: '+821012345678',
          uid: 'test_uid',
          verifiedAt: DateTime.now(),
        ),
      );

      expect(result.ok, true);
      expect(result.user?.phoneNumber, '+821012345678');
      expect(result.user?.uid, 'test_uid');
    });

    test('실패 결과 생성', () {
      final result = PhoneResult.failure(
        code: 'INVALID_CODE',
        message: '인증번호가 일치하지 않습니다.',
      );

      expect(result.ok, false);
      expect(result.errorCode, 'INVALID_CODE');
      expect(result.errorMessage, '인증번호가 일치하지 않습니다.');
    });

    test('취소 결과 생성', () {
      final result = PhoneResult.cancelled();

      expect(result.ok, false);
      expect(result.failure.isCancelled, true);
      expect(result.failure.shouldIgnore, true);
    });

    test('fold 패턴', () {
      final successResult = PhoneResult.success(
        user: PhoneUser(
          phoneNumber: '+821012345678',
          verifiedAt: DateTime.now(),
        ),
      );
      final failureResult = PhoneResult.failure(message: '실패');

      final successMessage = successResult.fold(
        ok: (user) => '성공: ${user?.phoneNumber}',
        err: (e) => '실패',
      );
      expect(successMessage, '성공: +821012345678');

      final failMessage = failureResult.fold(
        ok: (user) => '성공',
        err: (e) => '실패: ${e.message}',
      );
      expect(failMessage, '실패: 실패');
    });

    test('when 패턴', () {
      final cancelled = PhoneResult.cancelled();

      var called = '';
      cancelled.when(
        ok: (_) => called = 'ok',
        cancelled: () => called = 'cancelled',
        err: (_) => called = 'err',
      );

      expect(called, 'cancelled');
    });

    test('체이닝 패턴', () {
      var successCalled = false;
      var failureCalled = false;

      PhoneResult.success().onSuccess((_) => successCalled = true);
      PhoneResult.failure(message: '실패').onFailure((_) => failureCalled = true);

      expect(successCalled, true);
      expect(failureCalled, true);
    });
  });

  group('PhoneFailure', () {
    test('취소 여부 확인', () {
      const failure = PhoneFailure(code: 'USER_CANCELLED');
      expect(failure.isCancelled, true);
      expect(failure.shouldIgnore, true);
    });

    test('네트워크 에러 확인', () {
      const failure = PhoneFailure(code: 'NETWORK_ERROR');
      expect(failure.isNetworkError, true);
      expect(failure.canRetry, true);
    });

    test('잘못된 코드 확인', () {
      const failure = PhoneFailure(code: 'INVALID_CODE');
      expect(failure.isInvalidCode, true);
      expect(failure.canRetry, false);
    });

    test('만료 확인', () {
      const failure = PhoneFailure(code: 'CODE_EXPIRED');
      expect(failure.isCodeExpired, true);
      expect(failure.canRetry, true);
    });

    test('표시 메시지', () {
      const withMessage = PhoneFailure(message: '커스텀 메시지');
      const withoutMessage = PhoneFailure();

      expect(withMessage.displayMessage, '커스텀 메시지');
      expect(withoutMessage.displayMessage, '인증에 실패했습니다.');
    });
  });

  group('PhoneUser', () {
    test('기본 생성', () {
      final user = PhoneUser(
        phoneNumber: '+821012345678',
        verifiedAt: DateTime(2024, 1, 1),
      );

      expect(user.phoneNumber, '+821012345678');
      expect(user.uid, null);
      expect(user.isNewUser, false);
    });

    test('전체 정보 생성', () {
      final user = PhoneUser(
        phoneNumber: '+821012345678',
        uid: 'firebase_uid',
        verifiedAt: DateTime(2024, 1, 1),
        isNewUser: true,
      );

      expect(user.phoneNumber, '+821012345678');
      expect(user.uid, 'firebase_uid');
      expect(user.isNewUser, true);
    });

    test('toString', () {
      final user = PhoneUser(
        phoneNumber: '+821012345678',
        uid: 'test_uid',
        verifiedAt: DateTime.now(),
      );

      expect(user.toString(), contains('phoneNumber: +821012345678'));
      expect(user.toString(), contains('uid: test_uid'));
    });
  });

  group('PhoneState', () {
    test('모든 상태가 존재한다', () {
      expect(PhoneState.values, contains(PhoneState.idle));
      expect(PhoneState.values, contains(PhoneState.sending));
      expect(PhoneState.values, contains(PhoneState.codeSent));
      expect(PhoneState.values, contains(PhoneState.verifying));
      expect(PhoneState.values, contains(PhoneState.verified));
      expect(PhoneState.values, contains(PhoneState.error));
    });
  });

  group('PhoneProvider enum', () {
    test('모든 Provider가 존재한다', () {
      expect(PhoneProvider.values, contains(PhoneProvider.firebase));
      expect(PhoneProvider.values, contains(PhoneProvider.custom));
      expect(PhoneProvider.values.length, 2);
    });
  });

  group('KAuthPhone', () {
    // Custom provider 사용 (Firebase 초기화 불필요)
    const testConfig = PhoneConfig(
      provider: PhoneProvider.custom,
      sendUrl: 'https://test.com/send',
      verifyUrl: 'https://test.com/verify',
    );

    test('초기 상태는 idle', () {
      final phone = KAuthPhone(testConfig);
      expect(phone.state, PhoneState.idle);
      expect(phone.isVerified, false);
      expect(phone.number, null);
      phone.dispose();
    });

    test('reset 호출 시 상태 초기화', () {
      final phone = KAuthPhone(testConfig);
      phone.reset();
      expect(phone.state, PhoneState.idle);
      expect(phone.canResend, true);
      expect(phone.resendIn, Duration.zero);
      phone.dispose();
    });

    test('stateChanges 스트림 존재', () {
      final phone = KAuthPhone(testConfig);
      expect(phone.stateChanges, isA<Stream<PhoneState>>());
      phone.dispose();
    });

    test('resendTimer 스트림 존재', () {
      final phone = KAuthPhone(testConfig);
      expect(phone.resendTimer, isA<Stream<Duration>>());
      phone.dispose();
    });
  });

  group('KAuthConfig with phone', () {
    test('phone 설정 포함', () {
      const config = KAuthConfig(
        kakao: KakaoConfig(appKey: 'test_key'),
        phone: PhoneConfig(),
      );

      expect(config.phone, isNotNull);
      expect(config.phone!.provider, PhoneProvider.firebase);
      expect(config.configuredProviders, contains('phone'));
    });

    test('phone만 설정해도 유효', () {
      const config = KAuthConfig(
        phone: PhoneConfig(),
      );

      expect(config.isValid, true);
      expect(config.configuredProviders, ['phone']);
    });
  });

  group('AuthProvider.phone', () {
    test('phone Provider 속성', () {
      expect(AuthProvider.phone.displayName, '전화번호');
      expect(AuthProvider.phone.englishName, 'Phone');
      expect(AuthProvider.phone.supportsUnlink, false);
      expect(AuthProvider.phone.supportsTokenRefresh, false);
    });
  });
}
