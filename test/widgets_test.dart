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

    testWidgets('모든 Provider 버튼을 렌더링한다', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LoginButtonGroup(
              providers: AuthProvider.values,
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
}
