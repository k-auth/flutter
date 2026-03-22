import 'package:flutter_test/flutter_test.dart';
import 'package:k_auth/k_auth.dart';

void main() {
  // ============================================
  // KAuthUser.fromKakao 테스트
  // ============================================
  group('KAuthUser.fromKakao', () {
    test('전체 데이터가 있을 때 올바르게 파싱한다', () {
      final data = {
        'id': 12345678,
        'kakao_account': {
          'email': 'test@kakao.com',
          'profile': {
            'nickname': '홍길동',
            'profile_image_url': 'https://k.kakaocdn.net/profile.jpg',
          },
          'phone_number': '+82 10-1234-5678',
          'birthday': '0315',
          'birthyear': '1990',
          'gender': 'male',
          'age_range': '30~39',
          'ci': 'CI_VALUE_HERE',
        },
      };

      final user = KAuthUser.fromKakao(data);

      expect(user.id, '12345678');
      expect(user.provider, AuthProvider.kakao);
      expect(user.name, '홍길동');
      expect(user.email, 'test@kakao.com');
      expect(user.avatar, 'https://k.kakaocdn.net/profile.jpg');
      expect(user.phone, '+82 10-1234-5678');
      expect(user.birthday, '0315');
      expect(user.birthyear, '1990');
      expect(user.gender, 'male');
      expect(user.ageRange, '30~39');
      expect(user.ci, 'CI_VALUE_HERE');
      expect(user.rawData, data);
    });

    test('여성 성별이 올바르게 파싱된다', () {
      final data = {
        'id': 12345678,
        'kakao_account': {
          'gender': 'female',
        },
      };

      final user = KAuthUser.fromKakao(data);
      expect(user.gender, 'female');
    });

    test('최소 데이터만 있을 때도 파싱된다', () {
      final data = {'id': 99999999};

      final user = KAuthUser.fromKakao(data);

      expect(user.id, '99999999');
      expect(user.provider, AuthProvider.kakao);
      expect(user.name, isNull);
      expect(user.email, isNull);
    });

    test('kakao_account가 없어도 파싱된다', () {
      final data = {'id': 11111111};

      final user = KAuthUser.fromKakao(data);

      expect(user.id, '11111111');
      expect(user.provider, AuthProvider.kakao);
    });

    test('profile이 없어도 파싱된다', () {
      final data = {
        'id': 22222222,
        'kakao_account': {
          'email': 'test@kakao.com',
        },
      };

      final user = KAuthUser.fromKakao(data);

      expect(user.id, '22222222');
      expect(user.email, 'test@kakao.com');
      expect(user.name, isNull);
    });
  });

  // ============================================
  // KAuthUser.fromNaver 테스트
  // ============================================
  group('KAuthUser.fromNaver', () {
    test('전체 데이터가 있을 때 올바르게 파싱한다', () {
      final data = {
        'response': {
          'id': 'NAVER_USER_ID',
          'email': 'test@naver.com',
          'name': '김철수',
          'nickname': '철수닉네임',
          'profile_image': 'https://phinf.naver.net/profile.jpg',
          'gender': 'M',
          'age': '30-39',
          'birthday': '03-15',
          'birthyear': '1990',
          'mobile': '010-1234-5678',
        },
      };

      final user = KAuthUser.fromNaver(data);

      expect(user.id, 'NAVER_USER_ID');
      expect(user.provider, AuthProvider.naver);
      expect(user.name, '김철수');
      expect(user.email, 'test@naver.com');
      expect(user.avatar, 'https://phinf.naver.net/profile.jpg');
      expect(user.phone, '010-1234-5678');
      expect(user.birthday, '03-15');
      expect(user.birthyear, '1990');
      expect(user.gender, 'male');
      expect(user.ageRange, '30-39');
    });

    test('여성 성별이 올바르게 파싱된다', () {
      final data = {
        'response': {
          'id': 'NAVER_USER_ID',
          'gender': 'F',
        },
      };

      final user = KAuthUser.fromNaver(data);
      expect(user.gender, 'female');
    });

    test('name이 없으면 nickname을 사용한다', () {
      final data = {
        'response': {
          'id': 'NAVER_USER_ID',
          'nickname': '닉네임만있음',
        },
      };

      final user = KAuthUser.fromNaver(data);
      expect(user.name, '닉네임만있음');
    });

    test('response 없이 직접 데이터가 있어도 파싱된다', () {
      final data = {
        'id': 'DIRECT_ID',
        'email': 'direct@naver.com',
      };

      final user = KAuthUser.fromNaver(data);

      expect(user.id, 'DIRECT_ID');
      expect(user.email, 'direct@naver.com');
    });
  });

  // ============================================
  // KAuthUser.fromGoogle 테스트
  // ============================================
  group('KAuthUser.fromGoogle', () {
    test('전체 데이터가 있을 때 올바르게 파싱한다', () {
      final data = {
        'id': 'GOOGLE_USER_ID',
        'email': 'test@gmail.com',
        'displayName': '박영희',
        'photoUrl': 'https://lh3.googleusercontent.com/photo.jpg',
      };

      final user = KAuthUser.fromGoogle(data);

      expect(user.id, 'GOOGLE_USER_ID');
      expect(user.provider, AuthProvider.google);
      expect(user.name, '박영희');
      expect(user.email, 'test@gmail.com');
      expect(user.avatar, 'https://lh3.googleusercontent.com/photo.jpg');
    });

    test('name 필드도 지원한다', () {
      final data = {
        'id': 'GOOGLE_USER_ID',
        'name': '이름필드',
      };

      final user = KAuthUser.fromGoogle(data);
      expect(user.name, '이름필드');
    });

    test('picture 필드도 지원한다', () {
      final data = {
        'id': 'GOOGLE_USER_ID',
        'picture': 'https://picture.url',
      };

      final user = KAuthUser.fromGoogle(data);
      expect(user.avatar, 'https://picture.url');
    });

    test('sub 필드를 id로 사용할 수 있다 (JWT)', () {
      final data = {
        'sub': 'JWT_SUB_ID',
        'email': 'jwt@gmail.com',
      };

      final user = KAuthUser.fromGoogle(data);
      expect(user.id, 'JWT_SUB_ID');
    });

    test('id와 sub가 둘 다 있으면 id 우선', () {
      final data = {
        'id': 'PREFERRED_ID',
        'sub': 'JWT_SUB_ID',
      };

      final user = KAuthUser.fromGoogle(data);
      expect(user.id, 'PREFERRED_ID');
    });

    test('id와 sub가 둘 다 없으면 빈 문자열', () {
      final data = <String, dynamic>{
        'email': 'test@google.com',
      };

      final user = KAuthUser.fromGoogle(data);
      expect(user.id, '');
    });
  });

  // ============================================
  // KAuthUser.fromApple 테스트
  // ============================================
  group('KAuthUser.fromApple', () {
    test('전체 데이터가 있을 때 올바르게 파싱한다', () {
      final data = {
        'userIdentifier': 'APPLE_USER_ID',
        'email': 'test@privaterelay.appleid.com',
        'givenName': '길동',
        'familyName': '홍',
      };

      final user = KAuthUser.fromApple(data);

      expect(user.id, 'APPLE_USER_ID');
      expect(user.provider, AuthProvider.apple);
      expect(user.name, '홍 길동');
      expect(user.email, 'test@privaterelay.appleid.com');
    });

    test('이름이 givenName만 있을 때', () {
      final data = {
        'userIdentifier': 'APPLE_USER_ID',
        'givenName': '길동',
      };

      final user = KAuthUser.fromApple(data);
      expect(user.name, '길동');
    });

    test('이름이 familyName만 있을 때', () {
      final data = {
        'userIdentifier': 'APPLE_USER_ID',
        'familyName': '홍',
      };

      final user = KAuthUser.fromApple(data);
      expect(user.name, '홍');
    });

    test('이름이 없을 때 null', () {
      final data = {
        'userIdentifier': 'APPLE_USER_ID',
        'email': 'test@apple.com',
      };

      final user = KAuthUser.fromApple(data);
      expect(user.name, isNull);
    });

    test('sub 필드를 id로 사용할 수 있다 (JWT)', () {
      final data = {
        'sub': 'JWT_SUB_ID',
      };

      final user = KAuthUser.fromApple(data);
      expect(user.id, 'JWT_SUB_ID');
    });

    test('userIdentifier와 sub가 둘 다 있으면 userIdentifier 우선', () {
      final data = {
        'userIdentifier': 'PREFERRED_ID',
        'sub': 'JWT_SUB_ID',
      };

      final user = KAuthUser.fromApple(data);
      expect(user.id, 'PREFERRED_ID');
    });

    test('userIdentifier와 sub가 둘 다 없으면 빈 문자열', () {
      final data = <String, dynamic>{
        'email': 'test@apple.com',
      };

      final user = KAuthUser.fromApple(data);
      expect(user.id, '');
    });
  });

  // ============================================
  // KAuthUser 공통 기능 테스트
  // ============================================
  group('KAuthUser 공통 기능', () {
    test('displayName은 name을 우선 반환한다', () {
      final user = KAuthUser(
        id: '123',
        provider: AuthProvider.kakao,
        name: '홍길동',
        email: 'hong@kakao.com',
      );

      expect(user.displayName, '홍길동');
    });

    test('displayName은 name이 없으면 email 앞부분 반환', () {
      final user = KAuthUser(
        id: '123',
        provider: AuthProvider.kakao,
        email: 'hong@kakao.com',
      );

      expect(user.displayName, 'hong');
    });

    test('displayName은 둘 다 없으면 null', () {
      final user = KAuthUser(
        id: '123',
        provider: AuthProvider.kakao,
      );

      expect(user.displayName, isNull);
    });

    test('age는 birthyear로 계산된다', () {
      final currentYear = DateTime.now().year;
      final user = KAuthUser(
        id: '123',
        provider: AuthProvider.kakao,
        birthyear: '1990',
      );

      expect(user.age, currentYear - 1990);
    });

    test('age는 birthyear가 없으면 null', () {
      final user = KAuthUser(
        id: '123',
        provider: AuthProvider.kakao,
      );

      expect(user.age, isNull);
    });

    test('toJson과 fromJson이 올바르게 동작한다', () {
      final original = KAuthUser(
        id: '123',
        provider: AuthProvider.kakao,
        name: '홍길동',
        email: 'hong@kakao.com',
        avatar: 'https://image.url',
        phone: '010-1234-5678',
        birthday: '0315',
        birthyear: '1990',
        gender: 'male',
        ageRange: '30~39',
        ci: 'CI_VALUE',
      );

      final json = original.toJson();
      final restored = KAuthUser.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.provider, original.provider);
      expect(restored.name, original.name);
      expect(restored.email, original.email);
      expect(restored.avatar, original.avatar);
      expect(restored.phone, original.phone);
      expect(restored.birthday, original.birthday);
      expect(restored.birthyear, original.birthyear);
      expect(restored.gender, original.gender);
      expect(restored.ageRange, original.ageRange);
      expect(restored.ci, original.ci);
    });

    test('copyWith가 올바르게 동작한다', () {
      final original = KAuthUser(
        id: '123',
        provider: AuthProvider.kakao,
        name: '홍길동',
      );

      final copied = original.copyWith(name: '김철수', email: 'kim@kakao.com');

      expect(copied.id, '123');
      expect(copied.provider, AuthProvider.kakao);
      expect(copied.name, '김철수');
      expect(copied.email, 'kim@kakao.com');
    });

    test('equality가 id와 provider로 결정된다', () {
      final user1 =
          KAuthUser(id: '123', provider: AuthProvider.kakao, name: '홍길동');
      final user2 =
          KAuthUser(id: '123', provider: AuthProvider.kakao, name: '김철수');
      final user3 =
          KAuthUser(id: '123', provider: AuthProvider.naver, name: '홍길동');

      expect(user1, equals(user2)); // 같은 id, provider
      expect(user1, isNot(equals(user3))); // 다른 provider
    });
  });
}
