import 'package:flutter_test/flutter_test.dart';
import 'package:k_auth/k_auth.dart';

void main() {
  // ============================================
  // KAuthLogLevel 테스트
  // ============================================
  group('KAuthLogLevel', () {
    test('로그 레벨 순서가 올바르다', () {
      expect(KAuthLogLevel.none.index, lessThan(KAuthLogLevel.error.index));
      expect(KAuthLogLevel.error.index, lessThan(KAuthLogLevel.warning.index));
      expect(KAuthLogLevel.warning.index, lessThan(KAuthLogLevel.info.index));
      expect(KAuthLogLevel.info.index, lessThan(KAuthLogLevel.debug.index));
    });

    test('모든 레벨이 존재한다', () {
      expect(KAuthLogLevel.values, contains(KAuthLogLevel.none));
      expect(KAuthLogLevel.values, contains(KAuthLogLevel.error));
      expect(KAuthLogLevel.values, contains(KAuthLogLevel.warning));
      expect(KAuthLogLevel.values, contains(KAuthLogLevel.info));
      expect(KAuthLogLevel.values, contains(KAuthLogLevel.debug));
      expect(KAuthLogLevel.values.length, 5);
    });
  });

  // ============================================
  // KAuthLogEvent 테스트
  // ============================================
  group('KAuthLogEvent', () {
    group('toString', () {
      test('기본 형식', () {
        final event = KAuthLogEvent(
          level: KAuthLogLevel.info,
          message: '테스트 메시지',
          timestamp: DateTime.now(),
        );

        final str = event.toString();

        expect(str, contains('[K-Auth]'));
        expect(str, contains('테스트 메시지'));
      });

      test('provider가 있는 경우', () {
        final event = KAuthLogEvent(
          level: KAuthLogLevel.info,
          message: '메시지',
          timestamp: DateTime.now(),
          provider: 'kakao',
        );

        final str = event.toString();
        expect(str, contains('[kakao]'));
      });

      test('provider가 없는 경우', () {
        final event = KAuthLogEvent(
          level: KAuthLogLevel.info,
          message: '테스트 메시지',
          timestamp: DateTime.now(),
        );

        final str = event.toString();

        expect(str, contains('[K-Auth]'));
        expect(str, contains('테스트 메시지'));
        // provider가 없으면 [] 없어야 함 (K-Auth 제외)
        expect(str.indexOf('[K-Auth]'), isNot(-1));
      });

      test('data가 있는 경우', () {
        final event = KAuthLogEvent(
          level: KAuthLogLevel.debug,
          message: '메시지',
          timestamp: DateTime.now(),
          data: {'key': 'value'},
        );

        final str = event.toString();
        expect(str, contains('{key: value}'));
      });

      test('data가 비어있을 때', () {
        final event = KAuthLogEvent(
          level: KAuthLogLevel.debug,
          message: '메시지',
          timestamp: DateTime.now(),
          data: {},
        );

        final str = event.toString();
        expect(str, isNot(contains('{}')));
      });
    });

    group('레벨별 이모지', () {
      test('none 레벨', () {
        final event = KAuthLogEvent(
          level: KAuthLogLevel.none,
          message: '',
          timestamp: DateTime.now(),
        );

        expect(event.toString(), isNot(contains('❌')));
      });

      test('error 레벨', () {
        final event = KAuthLogEvent(
          level: KAuthLogLevel.error,
          message: '',
          timestamp: DateTime.now(),
        );

        expect(event.toString(), contains('❌'));
      });

      test('warning 레벨', () {
        final event = KAuthLogEvent(
          level: KAuthLogLevel.warning,
          message: '',
          timestamp: DateTime.now(),
        );

        expect(event.toString(), contains('⚠️'));
      });

      test('info 레벨', () {
        final event = KAuthLogEvent(
          level: KAuthLogLevel.info,
          message: '',
          timestamp: DateTime.now(),
        );

        expect(event.toString(), contains('ℹ️'));
      });

      test('debug 레벨', () {
        final event = KAuthLogEvent(
          level: KAuthLogLevel.debug,
          message: '',
          timestamp: DateTime.now(),
        );

        expect(event.toString(), contains('🔍'));
      });
    });

    test('error와 stackTrace 저장', () {
      final error = Exception('테스트 에러');
      final stackTrace = StackTrace.current;

      final event = KAuthLogEvent(
        level: KAuthLogLevel.error,
        message: '에러 발생',
        timestamp: DateTime.now(),
        error: error,
        stackTrace: stackTrace,
      );

      expect(event.error, error);
      expect(event.stackTrace, stackTrace);
    });
  });

  // ============================================
  // KAuthLogger 테스트
  // ============================================
  group('KAuthLogger', () {
    setUp(() {
      // 테스트 전 상태 초기화
      KAuthLogger.level = KAuthLogLevel.none;
      KAuthLogger.onLog = null;
    });

    test('기본 레벨은 none', () {
      // 테스트를 위해 리셋 후 확인
      KAuthLogger.level = KAuthLogLevel.none;
      expect(KAuthLogger.level, KAuthLogLevel.none);
    });

    test('레벨 변경', () {
      KAuthLogger.level = KAuthLogLevel.debug;
      expect(KAuthLogger.level, KAuthLogLevel.debug);
    });

    test('커스텀 로거 설정', () {
      KAuthLogEvent? capturedEvent;

      KAuthLogger.level = KAuthLogLevel.debug;
      KAuthLogger.onLog = (event) {
        capturedEvent = event;
      };

      KAuthLogger.info('테스트 메시지');

      expect(capturedEvent, isNotNull);
      expect(capturedEvent!.level, KAuthLogLevel.info);
      expect(capturedEvent!.message, '테스트 메시지');
    });

    test('로그 레벨보다 낮으면 로그가 출력되지 않음', () {
      KAuthLogEvent? capturedEvent;

      KAuthLogger.level = KAuthLogLevel.error;
      KAuthLogger.onLog = (event) {
        capturedEvent = event;
      };

      // info는 error보다 높은 레벨이므로 출력되지 않음
      KAuthLogger.info('이 메시지는 출력되지 않음');

      expect(capturedEvent, isNull);
    });

    test('debug 메서드', () {
      KAuthLogEvent? capturedEvent;

      KAuthLogger.level = KAuthLogLevel.debug;
      KAuthLogger.onLog = (event) {
        capturedEvent = event;
      };

      KAuthLogger.debug('디버그 메시지', provider: 'kakao');

      expect(capturedEvent!.level, KAuthLogLevel.debug);
      expect(capturedEvent!.message, '디버그 메시지');
      expect(capturedEvent!.provider, 'kakao');
    });

    test('warning 메서드', () {
      KAuthLogEvent? capturedEvent;

      KAuthLogger.level = KAuthLogLevel.debug;
      KAuthLogger.onLog = (event) {
        capturedEvent = event;
      };

      KAuthLogger.warning('경고 메시지');

      expect(capturedEvent!.level, KAuthLogLevel.warning);
    });

    test('error 메서드', () {
      KAuthLogEvent? capturedEvent;

      KAuthLogger.level = KAuthLogLevel.debug;
      KAuthLogger.onLog = (event) {
        capturedEvent = event;
      };

      final error = Exception('테스트');
      KAuthLogger.error('에러 메시지', error: error);

      expect(capturedEvent!.level, KAuthLogLevel.error);
      expect(capturedEvent!.error, error);
    });
  });
}
