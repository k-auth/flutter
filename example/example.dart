/// K-Auth 패키지 사용 예제
///
/// 한국 소셜 로그인을 간단하게 구현하는 방법을 보여줍니다.
/// 전체 예제는 example/lib/main.dart를 참고하세요.
library;

import 'package:flutter/material.dart';
import 'package:k_auth/k_auth.dart';

late final KAuth kAuth;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. 초기화 (KAuth.init 권장)
  kAuth = await KAuth.init(
    kakao: KakaoConfig(appKey: 'YOUR_KAKAO_APP_KEY'),
    naver: NaverConfig(
      clientId: 'YOUR_NAVER_CLIENT_ID',
      clientSecret: 'YOUR_NAVER_CLIENT_SECRET',
      appName: 'My App',
    ),
    google: GoogleConfig(),
    apple: AppleConfig(),
  );

  runApp(const ExampleApp());
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: KAuthBuilder(
        stream: kAuth.authStateChanges,
        signedIn: (user) => HomeScreen(user: user),
        signedOut: () => const LoginScreen(),
      ),
    );
  }
}

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('로그인')),
      body: Center(
        child: LoginButtonGroup(
          providers: const [
            AuthProvider.kakao,
            AuthProvider.naver,
            AuthProvider.google,
            AuthProvider.apple,
          ],
          onPressed: (provider) async {
            final result = await kAuth.signIn(provider);
            result.fold(
              onSuccess: (user) => debugPrint('로그인 성공: ${user.displayName}'),
              onFailure: (failure) => debugPrint('로그인 실패: ${failure.message}'),
            );
          },
        ),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.user});
  final KAuthUser user;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('안녕하세요, ${user.displayName}!')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (user.avatar != null)
              CircleAvatar(
                radius: 50,
                backgroundImage: NetworkImage(user.avatar!),
              ),
            const SizedBox(height: 16),
            Text(user.email ?? '이메일 없음'),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => kAuth.signOut(),
              child: const Text('로그아웃'),
            ),
          ],
        ),
      ),
    );
  }
}
