import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_auth/k_auth.dart';

void main() {
  group('KakaoLoginButton', () {
    testWidgets('기본 버튼이 렌더링된다', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: KakaoLoginButton()),
        ),
      );

      expect(find.text('카카오 로그인'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('커스텀 텍스트를 표시한다', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: KakaoLoginButton(text: '카카오로 시작하기'),
          ),
        ),
      );

      expect(find.text('카카오로 시작하기'), findsOneWidget);
    });

    testWidgets('onPressed가 호출된다', (tester) async {
      bool pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: KakaoLoginButton(onPressed: () => pressed = true),
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      expect(pressed, true);
    });

    testWidgets('disabled 상태에서 onPressed가 호출되지 않는다', (tester) async {
      bool pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: KakaoLoginButton(
              onPressed: () => pressed = true,
              disabled: true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      expect(pressed, false);
    });

    testWidgets('isLoading일 때 CircularProgressIndicator를 표시한다', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: KakaoLoginButton(isLoading: true),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('카카오 로그인'), findsNothing);
    });

    testWidgets('아이콘 모드에서 텍스트가 표시되지 않는다', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: KakaoLoginButton(size: ButtonSize.icon),
          ),
        ),
      );

      expect(find.text('카카오 로그인'), findsNothing);
    });
  });

  group('NaverLoginButton', () {
    testWidgets('기본 버튼이 렌더링된다', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: NaverLoginButton()),
        ),
      );

      expect(find.text('네이버 로그인'), findsOneWidget);
    });

    testWidgets('onPressed가 호출된다', (tester) async {
      bool pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NaverLoginButton(onPressed: () => pressed = true),
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      expect(pressed, true);
    });
  });

  group('GoogleLoginButton', () {
    testWidgets('기본 버튼이 렌더링된다', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: GoogleLoginButton()),
        ),
      );

      expect(find.text('Google로 로그인'), findsOneWidget);
      expect(find.byType(OutlinedButton), findsOneWidget);
    });

    testWidgets('onPressed가 호출된다', (tester) async {
      bool pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GoogleLoginButton(onPressed: () => pressed = true),
          ),
        ),
      );

      await tester.tap(find.byType(OutlinedButton));
      expect(pressed, true);
    });
  });

  group('AppleLoginButton', () {
    testWidgets('기본 버튼이 렌더링된다', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: AppleLoginButton()),
        ),
      );

      expect(find.text('Apple로 로그인'), findsOneWidget);
    });

    testWidgets('다크 모드 버튼이 렌더링된다', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: AppleLoginButton(isDark: true)),
        ),
      );

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      // 다크 모드일 때 배경색이 검정
      expect(button.style?.backgroundColor?.resolve({}), Colors.black);
    });

    testWidgets('라이트 모드 버튼이 렌더링된다', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: AppleLoginButton(isDark: false)),
        ),
      );

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      // 라이트 모드일 때 배경색이 흰색
      expect(button.style?.backgroundColor?.resolve({}), Colors.white);
    });
  });

  group('LoginButtonGroup', () {
    testWidgets('vertical 방향으로 버튼들을 렌더링한다', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LoginButtonGroup(
              providers: [AuthProvider.kakao, AuthProvider.google],
              direction: ButtonGroupDirection.vertical,
            ),
          ),
        ),
      );

      expect(find.byType(Column), findsOneWidget);
      expect(find.text('카카오 로그인'), findsOneWidget);
      expect(find.text('Google로 로그인'), findsOneWidget);
    });

    testWidgets('horizontal 방향으로 버튼들을 렌더링한다', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: LoginButtonGroup(
                providers: [AuthProvider.kakao, AuthProvider.google],
                direction: ButtonGroupDirection.horizontal,
                buttonSize: ButtonSize.icon, // 아이콘 모드로 너비 제한
              ),
            ),
          ),
        ),
      );

      // 두 버튼이 모두 렌더링됨
      expect(find.byType(KakaoLoginButton), findsOneWidget);
      expect(find.byType(GoogleLoginButton), findsOneWidget);
    });

    testWidgets('모든 소셜 Provider 버튼을 렌더링한다', (tester) async {
      // phone은 LoginButtonGroup에서 지원하지 않음 (sendCode/verifyCode 사용)
      final socialProviders =
          AuthProvider.values.where((p) => p != AuthProvider.phone).toList();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LoginButtonGroup(
              providers: socialProviders,
            ),
          ),
        ),
      );

      expect(find.text('카카오 로그인'), findsOneWidget);
      expect(find.text('네이버 로그인'), findsOneWidget);
      expect(find.text('Google로 로그인'), findsOneWidget);
      expect(find.text('Apple로 로그인'), findsOneWidget);
    });

    testWidgets('onPressed가 올바른 provider로 호출된다', (tester) async {
      AuthProvider? pressedProvider;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LoginButtonGroup(
              providers: [AuthProvider.kakao, AuthProvider.naver],
              onPressed: (provider) => pressedProvider = provider,
            ),
          ),
        ),
      );

      await tester.tap(find.text('네이버 로그인'));
      expect(pressedProvider, AuthProvider.naver);
    });

    testWidgets('개별 로딩 상태를 지원한다', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LoginButtonGroup(
              providers: [AuthProvider.kakao, AuthProvider.naver],
              loadingStates: {
                AuthProvider.kakao: true,
                AuthProvider.naver: false,
              },
            ),
          ),
        ),
      );

      // 카카오 버튼에만 로딩 인디케이터가 있어야 함
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('네이버 로그인'), findsOneWidget);
    });
  });

  group('ButtonSize', () {
    testWidgets('small 사이즈가 적용된다', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: KakaoLoginButton(size: ButtonSize.small),
          ),
        ),
      );

      final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox).first);
      expect(sizedBox.height, 36);
    });

    testWidgets('medium 사이즈가 적용된다', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: KakaoLoginButton(size: ButtonSize.medium),
          ),
        ),
      );

      final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox).first);
      expect(sizedBox.height, 48);
    });

    testWidgets('large 사이즈가 적용된다', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: KakaoLoginButton(size: ButtonSize.large),
          ),
        ),
      );

      final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox).first);
      expect(sizedBox.height, 56);
    });
  });

  group('KAuthBuilder', () {
    testWidgets('로그인 상태에서 signedIn 위젯을 표시한다', (tester) async {
      final user =
          KAuthUser(id: '123', name: '홍길동', provider: AuthProvider.kakao);
      final controller = StreamController<KAuthUser?>.broadcast();

      await tester.pumpWidget(
        MaterialApp(
          home: KAuthBuilder(
            stream: controller.stream,
            signedIn: (user) => Text('안녕하세요, ${user.name}!'),
            signedOut: () => const Text('로그인 화면'),
          ),
        ),
      );

      // 로그인 이벤트 발생
      controller.add(user);
      await tester.pump();

      expect(find.text('안녕하세요, 홍길동!'), findsOneWidget);
      expect(find.text('로그인 화면'), findsNothing);

      await controller.close();
    });

    testWidgets('로그아웃 상태에서 signedOut 위젯을 표시한다', (tester) async {
      final controller = StreamController<KAuthUser?>.broadcast();

      await tester.pumpWidget(
        MaterialApp(
          home: KAuthBuilder(
            stream: controller.stream,
            signedIn: (user) => Text('안녕하세요, ${user.name}!'),
            signedOut: () => const Text('로그인 화면'),
          ),
        ),
      );

      // 로그아웃 이벤트 발생 (null)
      controller.add(null);
      await tester.pump();

      expect(find.text('로그인 화면'), findsOneWidget);
      expect(find.textContaining('안녕하세요'), findsNothing);

      await controller.close();
    });

    testWidgets('로딩 중 loading 위젯을 표시한다', (tester) async {
      final controller = StreamController<KAuthUser?>.broadcast();

      await tester.pumpWidget(
        MaterialApp(
          home: KAuthBuilder(
            stream: controller.stream,
            signedIn: (user) => const Text('홈'),
            signedOut: () => const Text('로그인'),
            loading: () => const Text('로딩 중...'),
          ),
        ),
      );

      // 스트림이 아직 데이터를 방출하지 않은 상태 (waiting)
      expect(find.text('로딩 중...'), findsOneWidget);
      expect(find.text('홈'), findsNothing);
      expect(find.text('로그인'), findsNothing);

      await controller.close();
    });

    testWidgets('loading이 없으면 기본 CircularProgressIndicator를 표시한다',
        (tester) async {
      final controller = StreamController<KAuthUser?>.broadcast();

      await tester.pumpWidget(
        MaterialApp(
          home: KAuthBuilder(
            stream: controller.stream,
            signedIn: (user) => const Text('홈'),
            signedOut: () => const Text('로그인'),
          ),
        ),
      );

      // 기본 로딩 인디케이터
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await controller.close();
    });

    testWidgets('initialUser가 있으면 로딩 없이 바로 표시한다', (tester) async {
      final user =
          KAuthUser(id: '123', name: '초기유저', provider: AuthProvider.kakao);
      final controller = StreamController<KAuthUser?>.broadcast();

      await tester.pumpWidget(
        MaterialApp(
          home: KAuthBuilder(
            stream: controller.stream,
            signedIn: (user) => Text('안녕, ${user.name}!'),
            signedOut: () => const Text('로그인'),
            initialUser: user,
          ),
        ),
      );

      // initialData가 있어도 connectionState가 waiting이면 로딩 표시
      // 스트림이 데이터를 방출하면 initialData와 함께 표시
      controller.add(user);
      await tester.pump();

      expect(find.text('안녕, 초기유저!'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);

      await controller.close();
    });

    testWidgets('스트림 상태 변화에 따라 화면이 전환된다', (tester) async {
      final user =
          KAuthUser(id: '123', name: '테스트', provider: AuthProvider.kakao);
      final controller = StreamController<KAuthUser?>.broadcast();

      await tester.pumpWidget(
        MaterialApp(
          home: KAuthBuilder(
            stream: controller.stream,
            signedIn: (user) => const Text('로그인됨'),
            signedOut: () => const Text('로그아웃됨'),
          ),
        ),
      );

      // 로그인
      controller.add(user);
      await tester.pumpAndSettle();
      expect(find.text('로그인됨'), findsOneWidget);

      // 로그아웃
      controller.add(null);
      await tester.pumpAndSettle();
      expect(find.text('로그아웃됨'), findsOneWidget);

      // 다시 로그인
      controller.add(user);
      await tester.pumpAndSettle();
      expect(find.text('로그인됨'), findsOneWidget);

      await controller.close();
    });

    testWidgets('에러 발생 시 error 위젯이 표시된다', (tester) async {
      final controller = StreamController<KAuthUser?>.broadcast();

      await tester.pumpWidget(
        MaterialApp(
          home: KAuthBuilder(
            stream: controller.stream,
            signedIn: (user) => const Text('로그인됨'),
            signedOut: () => const Text('로그아웃됨'),
            error: (e) => Text('에러: $e'),
          ),
        ),
      );

      controller.addError('테스트 에러');
      await tester.pumpAndSettle();
      expect(find.text('에러: 테스트 에러'), findsOneWidget);

      await controller.close();
    });

    testWidgets('error 위젯 없으면 기본 에러 메시지가 표시된다', (tester) async {
      final controller = StreamController<KAuthUser?>.broadcast();

      await tester.pumpWidget(
        MaterialApp(
          home: KAuthBuilder(
            stream: controller.stream,
            signedIn: (user) => const Text('로그인됨'),
            signedOut: () => const Text('로그아웃됨'),
          ),
        ),
      );

      controller.addError('테스트 에러');
      await tester.pumpAndSettle();
      expect(find.text('오류: 테스트 에러'), findsOneWidget);

      await controller.close();
    });
  });
}
