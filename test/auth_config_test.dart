import 'package:flutter/foundation.dart' show TargetPlatform;
import 'package:flutter_test/flutter_test.dart';
import 'package:k_auth/k_auth.dart';

void main() {
  // ============================================
  // KakaoCollectOptions 테스트
  // ============================================
  group('KakaoCollectOptions', () {
    group('toScopes', () {
      test('기본 옵션의 scope 목록', () {
        const options = KakaoCollectOptions();
        final scopes = options.toScopes();

        expect(scopes, contains('profile_nickname'));
        expect(scopes, contains('profile_image'));
        expect(scopes, contains('account_email'));
        expect(scopes, isNot(contains('phone_number')));
      });

      test('phone 옵션이 true면 phone_number scope 추가', () {
        const options = KakaoCollectOptions(phone: true);
        final scopes = options.toScopes();

        expect(scopes, contains('phone_number'));
      });

      test('birthday 옵션이 true면 birthday, birthyear scope 추가', () {
        const options = KakaoCollectOptions(birthday: true);
        final scopes = options.toScopes();

        expect(scopes, contains('birthday'));
        expect(scopes, contains('birthyear'));
      });

      test('gender 옵션이 true면 gender scope 추가', () {
        const options = KakaoCollectOptions(gender: true);
        final scopes = options.toScopes();

        expect(scopes, contains('gender'));
      });

      test('ageRange 옵션이 true면 age_range scope 추가', () {
        const options = KakaoCollectOptions(ageRange: true);
        final scopes = options.toScopes();

        expect(scopes, contains('age_range'));
      });

      test('ci 옵션이 true면 account_ci scope 추가', () {
        const options = KakaoCollectOptions(ci: true);
        final scopes = options.toScopes();

        expect(scopes, contains('account_ci'));
      });

      test('모든 옵션 비활성화', () {
        const options = KakaoCollectOptions(
          email: false,
          profile: false,
          phone: false,
          birthday: false,
          gender: false,
          ageRange: false,
          ci: false,
        );
        final scopes = options.toScopes();

        expect(scopes, isEmpty);
      });
    });

    test('defaults가 기본값을 반환한다', () {
      const options = KakaoCollectOptions.defaults;

      expect(options.email, true);
      expect(options.profile, true);
      expect(options.phone, false);
    });

    test('all이 모든 옵션을 활성화한다', () {
      const options = KakaoCollectOptions.all;

      expect(options.email, true);
      expect(options.profile, true);
      expect(options.phone, true);
      expect(options.birthday, true);
      expect(options.gender, true);
      expect(options.ageRange, true);
      expect(options.ci, true);
    });
  });

  // ============================================
  // NaverCollectOptions 테스트
  // ============================================
  group('NaverCollectOptions', () {
    test('기본값 테스트', () {
      const options = NaverCollectOptions();

      expect(options.email, true);
      expect(options.nickname, true);
      expect(options.profileImage, true);
      expect(options.name, false);
      expect(options.birthday, false);
      expect(options.ageRange, false);
      expect(options.gender, false);
      expect(options.mobile, false);
    });

    test('defaults가 기본값을 반환한다', () {
      const options = NaverCollectOptions.defaults;

      expect(options.email, true);
      expect(options.nickname, true);
      expect(options.profileImage, true);
      expect(options.name, false);
    });

    test('모든 옵션 활성화', () {
      const options = NaverCollectOptions(
        email: true,
        nickname: true,
        profileImage: true,
        name: true,
        birthday: true,
        ageRange: true,
        gender: true,
        mobile: true,
      );

      expect(options.email, true);
      expect(options.name, true);
      expect(options.birthday, true);
      expect(options.ageRange, true);
      expect(options.gender, true);
      expect(options.mobile, true);
    });

    test('NaverConfig에 collect를 설정할 수 있다', () {
      const options = NaverCollectOptions(name: true, mobile: true);

      final config = NaverConfig(
        clientId: 'id',
        clientSecret: 'secret',
        appName: 'app',
        collect: options,
      );

      expect(config.collect?.name, true);
      expect(config.collect?.mobile, true);
    });
  });

  // ============================================
  // GoogleCollectOptions 테스트
  // ============================================
  group('GoogleCollectOptions', () {
    test('기본값 테스트', () {
      const options = GoogleCollectOptions();

      expect(options.email, true);
      expect(options.profile, true);
      expect(options.openid, true);
    });

    test('defaults가 기본값을 반환한다', () {
      const options = GoogleCollectOptions.defaults;

      expect(options.email, true);
      expect(options.profile, true);
      expect(options.openid, true);
    });

    test('toScopes가 올바른 scope 목록을 반환한다', () {
      const options = GoogleCollectOptions();
      final scopes = options.toScopes();

      expect(scopes, contains('openid'));
      expect(scopes, contains('email'));
      expect(scopes, contains('profile'));
    });

    test('일부 옵션만 활성화', () {
      const options = GoogleCollectOptions(
        email: true,
        profile: false,
        openid: false,
      );
      final scopes = options.toScopes();

      expect(scopes, contains('email'));
      expect(scopes, isNot(contains('profile')));
      expect(scopes, isNot(contains('openid')));
    });
  });

  // ============================================
  // AppleCollectOptions 테스트
  // ============================================
  group('AppleCollectOptions', () {
    test('기본값 테스트', () {
      const options = AppleCollectOptions();

      expect(options.email, true);
      expect(options.fullName, true);
    });

    test('defaults가 기본값을 반환한다', () {
      const options = AppleCollectOptions.defaults;

      expect(options.email, true);
      expect(options.fullName, true);
    });
  });

  // ============================================
  // AppleConfig 테스트
  // ============================================
  group('AppleConfig', () {
    test('validate가 항상 빈 리스트를 반환한다', () {
      const config = AppleConfig();
      final errors = config.validate();

      expect(errors, isEmpty);
    });

    test('커스텀 collect 옵션으로 생성', () {
      const config = AppleConfig(
        collect: AppleCollectOptions(email: false, fullName: true),
      );

      expect(config.collect.email, false);
      expect(config.collect.fullName, true);
    });
  });

  // ============================================
  // GoogleConfig 테스트
  // ============================================
  group('GoogleConfig', () {
    test('forceConsent 기본값은 false', () {
      final config = GoogleConfig();

      expect(config.forceConsent, false);
    });

    test('forceConsent 설정', () {
      final config = GoogleConfig(forceConsent: true);

      expect(config.forceConsent, true);
    });

    test('allScopes가 중복 없이 scope 목록을 반환한다', () {
      final config = GoogleConfig(additionalScopes: ['email', 'custom_scope']);
      final scopes = config.allScopes;

      expect(scopes.where((s) => s == 'email').length, 1);
      expect(scopes, contains('custom_scope'));
    });

    test('iOS에서 iosClientId가 없으면 에러', () {
      final config = GoogleConfig();
      final errors = config.validate(targetPlatform: TargetPlatform.iOS);

      expect(errors, isNotEmpty);
      expect(errors.first.code, ErrorCodes.googleMissingIosClientId);
    });

    test('iOS에서 iosClientId가 있으면 에러 없음', () {
      final config = GoogleConfig(iosClientId: 'client_id');
      final errors = config.validate(targetPlatform: TargetPlatform.iOS);

      expect(errors, isEmpty);
    });

    test('Android에서는 iosClientId 없어도 에러 없음', () {
      final config = GoogleConfig();
      final errors = config.validate(targetPlatform: TargetPlatform.android);

      expect(errors, isEmpty);
    });
  });

  // ============================================
  // KakaoConfig 테스트
  // ============================================
  group('KakaoConfig', () {
    test('appKey가 비어있으면 에러', () {
      final config = KakaoConfig(appKey: '');
      final errors = config.validate();

      expect(errors, isNotEmpty);
      expect(errors.first.code, ErrorCodes.missingAppKey);
    });

    test('allScopes가 중복 없이 scope 목록을 반환한다', () {
      final config = KakaoConfig(
        appKey: 'key',
        additionalScopes: ['account_email', 'custom_scope'],
      );
      final scopes = config.allScopes;

      expect(scopes.where((s) => s == 'account_email').length, 1);
      expect(scopes, contains('custom_scope'));
    });
  });

  // ============================================
  // NaverConfig 테스트
  // ============================================
  group('NaverConfig', () {
    test('clientId가 비어있으면 에러', () {
      final config = NaverConfig(
        clientId: '',
        clientSecret: 'secret',
        appName: 'app',
      );
      final errors = config.validate();

      expect(errors.any((e) => e.code == ErrorCodes.missingClientId), true);
    });

    test('clientSecret이 비어있으면 에러', () {
      final config = NaverConfig(
        clientId: 'id',
        clientSecret: '',
        appName: 'app',
      );
      final errors = config.validate();

      expect(errors.any((e) => e.code == ErrorCodes.missingClientSecret), true);
    });
  });

  // ============================================
  // KAuthConfig 테스트
  // ============================================
  group('KAuthConfig', () {
    group('validate', () {
      test('throwOnError가 true일 때 에러 발생', () {
        final config = KAuthConfig();

        expect(
          () => config.validate(throwOnError: true),
          throwsA(isA<KAuthError>()),
        );
      });

      test('throwOnError가 false일 때 에러 목록 반환', () {
        final config = KAuthConfig();

        final errors = config.validate(throwOnError: false);

        expect(errors, isNotEmpty);
        expect(errors.first.code, ErrorCodes.noProviderConfigured);
      });

      test('유효한 설정에서 throwOnError가 true여도 에러 없음', () {
        final config = KAuthConfig(
          kakao: KakaoConfig(appKey: 'valid_key'),
        );

        expect(
          () => config.validate(throwOnError: true),
          returnsNormally,
        );
      });

      test('isValid가 설정 상태를 반환한다', () {
        final invalidConfig = KAuthConfig();
        final validConfig = KAuthConfig(
          kakao: KakaoConfig(appKey: 'key'),
        );

        expect(invalidConfig.isValid, false);
        expect(validConfig.isValid, true);
      });

      test('configuredProviders가 설정된 Provider 목록을 반환한다', () {
        final config = KAuthConfig(
          kakao: KakaoConfig(appKey: 'key'),
          naver: NaverConfig(
            clientId: 'id',
            clientSecret: 'secret',
            appName: 'app',
          ),
        );

        expect(config.configuredProviders, contains('kakao'));
        expect(config.configuredProviders, contains('naver'));
        expect(config.configuredProviders, isNot(contains('google')));
        expect(config.configuredProviders, isNot(contains('apple')));
      });
    });
  });
}
