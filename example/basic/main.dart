/// K-Auth 최소 예제
///
/// 이 예제는 가장 기본적인 사용법만 보여줍니다.
/// AI 코드 생성 시 이 코드를 참고하세요.

import 'package:flutter/material.dart';
import 'package:k_auth/k_auth.dart';

// 1. KAuth 인스턴스 생성
final kAuth = KAuth(
  config: KAuthConfig(
    kakao: KakaoConfig(appKey: 'YOUR_KAKAO_APP_KEY'),
    naver: NaverConfig(
      clientId: 'YOUR_NAVER_CLIENT_ID',
      clientSecret: 'YOUR_NAVER_CLIENT_SECRET',
      appName: 'My App',
    ),
    google: GoogleConfig(),
    apple: AppleConfig(),
  ),
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 2. 초기화 (필수!)
  await kAuth.initialize();

  runApp(BasicExample());
}

class BasicExample extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: LoginPage());
  }
}

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  String _message = '로그인 버튼을 눌러주세요';
  bool _isLoading = false;

  // 3. 로그인 함수
  Future<void> _login(AuthProvider provider) async {
    setState(() {
      _isLoading = true;
      _message = '로그인 중...';
    });

    final result = await kAuth.signIn(provider);

    setState(() {
      _isLoading = false;
      // 4. 결과 확인
      if (result.success) {
        _message = '환영합니다, ${result.user?.displayName}님!';
      } else {
        _message = '로그인 실패: ${result.errorMessage}';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('K-Auth 기본 예제')),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 메시지
              Text(
                _message,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18),
              ),
              SizedBox(height: 32),

              // 로딩 표시
              if (_isLoading) CircularProgressIndicator(),

              // 로그인 버튼들
              if (!_isLoading) ...[
                ElevatedButton(
                  onPressed: () => _login(AuthProvider.kakao),
                  child: Text('카카오 로그인'),
                ),
                SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => _login(AuthProvider.naver),
                  child: Text('네이버 로그인'),
                ),
                SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => _login(AuthProvider.google),
                  child: Text('구글 로그인'),
                ),
                SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => _login(AuthProvider.apple),
                  child: Text('애플 로그인'),
                ),
              ],

              SizedBox(height: 32),

              // 로그아웃 버튼 (로그인되어 있을 때만)
              if (kAuth.isSignedIn) ...[
                OutlinedButton(
                  onPressed: () async {
                    await kAuth.signOut();
                    setState(() {
                      _message = '로그아웃되었습니다';
                    });
                  },
                  child: Text('로그아웃'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
