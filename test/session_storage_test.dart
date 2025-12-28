import 'package:flutter_test/flutter_test.dart';
import 'package:k_auth/k_auth.dart';

void main() {
  // ============================================
  // InMemorySessionStorage 테스트
  // ============================================
  group('InMemorySessionStorage', () {
    late InMemorySessionStorage storage;

    setUp(() {
      storage = InMemorySessionStorage();
    });

    test('save와 read가 올바르게 동작한다', () async {
      await storage.save('key1', 'value1');

      final value = await storage.read('key1');
      expect(value, 'value1');
    });

    test('존재하지 않는 키 read 시 null 반환', () async {
      final value = await storage.read('nonexistent');
      expect(value, isNull);
    });

    test('delete가 올바르게 동작한다', () async {
      await storage.save('key1', 'value1');
      await storage.delete('key1');

      final value = await storage.read('key1');
      expect(value, isNull);
    });

    test('clear가 모든 데이터를 삭제한다', () async {
      await storage.save('key1', 'value1');
      await storage.save('key2', 'value2');
      await storage.clear();

      expect(await storage.read('key1'), isNull);
      expect(await storage.read('key2'), isNull);
    });

    test('같은 키에 덮어쓰기', () async {
      await storage.save('key1', 'value1');
      await storage.save('key1', 'value2');

      final value = await storage.read('key1');
      expect(value, 'value2');
    });
  });

  // ============================================
  // KAuthSession 테스트
  // ============================================
  group('KAuthSession', () {
    group('toJson', () {
      test('필수 필드만 있는 경우', () {
        final user = KAuthUser(id: '123', provider: AuthProvider.kakao);
        final session = KAuthSession(
          provider: AuthProvider.kakao,
          user: user,
          savedAt: DateTime(2025, 1, 1),
        );

        final json = session.toJson();

        expect(json['provider'], 'kakao');
        expect(json['user'], isNotNull);
        expect(json['savedAt'], '2025-01-01T00:00:00.000');
        expect(json.containsKey('accessToken'), false);
        expect(json.containsKey('refreshToken'), false);
      });

      test('모든 필드가 있는 경우', () {
        final user = KAuthUser(id: '123', provider: AuthProvider.google);
        final session = KAuthSession(
          provider: AuthProvider.google,
          user: user,
          accessToken: 'access',
          refreshToken: 'refresh',
          idToken: 'id_token',
          serverToken: 'server_token',
          expiresAt: DateTime(2025, 12, 31),
          savedAt: DateTime(2025, 1, 1),
        );

        final json = session.toJson();

        expect(json['provider'], 'google');
        expect(json['accessToken'], 'access');
        expect(json['refreshToken'], 'refresh');
        expect(json['idToken'], 'id_token');
        expect(json['serverToken'], 'server_token');
        expect(json['expiresAt'], '2025-12-31T00:00:00.000');
      });
    });

    group('fromJson', () {
      test('알 수 없는 provider는 kakao로 fallback', () {
        final json = {
          'provider': 'unknown_provider',
          'user': {
            'id': '123',
            'provider': 'kakao',
          },
          'savedAt': '2025-01-01T00:00:00.000',
        };

        final session = KAuthSession.fromJson(json);

        expect(session.provider, AuthProvider.kakao);
      });

      test('optional 필드가 null인 경우', () {
        final json = {
          'provider': 'naver',
          'user': {
            'id': '123',
            'provider': 'naver',
          },
          'savedAt': '2025-01-01T00:00:00.000',
        };

        final session = KAuthSession.fromJson(json);

        expect(session.accessToken, isNull);
        expect(session.refreshToken, isNull);
        expect(session.idToken, isNull);
        expect(session.serverToken, isNull);
        expect(session.expiresAt, isNull);
      });
    });

    group('isExpired', () {
      test('expiresAt이 null이면 false', () {
        final user = KAuthUser(id: '123', provider: AuthProvider.kakao);
        final session = KAuthSession(
          provider: AuthProvider.kakao,
          user: user,
          savedAt: DateTime.now(),
        );

        expect(session.isExpired, false);
      });

      test('미래 시간이면 false', () {
        final user = KAuthUser(id: '123', provider: AuthProvider.kakao);
        final session = KAuthSession(
          provider: AuthProvider.kakao,
          user: user,
          expiresAt: DateTime.now().add(const Duration(hours: 1)),
          savedAt: DateTime.now(),
        );

        expect(session.isExpired, false);
      });

      test('과거 시간이면 true', () {
        final user = KAuthUser(id: '123', provider: AuthProvider.kakao);
        final session = KAuthSession(
          provider: AuthProvider.kakao,
          user: user,
          expiresAt: DateTime.now().subtract(const Duration(hours: 1)),
          savedAt: DateTime.now(),
        );

        expect(session.isExpired, true);
      });
    });

    test('encode와 decode가 올바르게 동작한다', () {
      final user = KAuthUser(id: '123', provider: AuthProvider.kakao);
      final session = KAuthSession(
        provider: AuthProvider.kakao,
        user: user,
        accessToken: 'token',
        savedAt: DateTime(2025, 1, 1),
      );

      final encoded = session.encode();
      final decoded = KAuthSession.decode(encoded);

      expect(decoded.provider, session.provider);
      expect(decoded.user.id, session.user.id);
      expect(decoded.accessToken, session.accessToken);
    });

    test('toString이 올바른 형식을 반환한다', () {
      final user = KAuthUser(id: '123', provider: AuthProvider.kakao);
      final session = KAuthSession(
        provider: AuthProvider.kakao,
        user: user,
        savedAt: DateTime.now(),
      );

      final str = session.toString();

      expect(str, contains('KAuthSession'));
      expect(str, contains('kakao'));
      expect(str, contains('123'));
    });
  });
}
