import 'package:flutter/material.dart';
import 'package:k_auth/k_auth.dart';

// 1. KAuth 인스턴스 생성
final kAuth = KAuth(
  config: KAuthConfig(
    kakao: KakaoConfig(
      appKey: 'YOUR_KAKAO_APP_KEY',
      collect: KakaoCollectOptions(email: true, profile: true),
    ),
    naver: NaverConfig(
      clientId: 'YOUR_NAVER_CLIENT_ID',
      clientSecret: 'YOUR_NAVER_CLIENT_SECRET',
      appName: 'K-Auth Example',
    ),
    google: GoogleConfig(),
    apple: AppleConfig(),
  ),
);

void main() {
  // 2. 초기화
  kAuth.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'K-Auth Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  KAuthUser? _user;
  bool _isLoading = false;
  String? _error;

  // 3. 로그인 처리
  Future<void> _signIn(AuthProvider provider) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await kAuth.signIn(provider);

    setState(() {
      _isLoading = false;
      if (result.success) {
        _user = result.user;
      } else {
        _error = result.errorMessage;
      }
    });
  }

  // 4. 로그아웃 처리
  Future<void> _signOut() async {
    if (_user == null) return;

    await kAuth.signOutAll();
    setState(() => _user = null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('K-Auth Example'),
        actions: [
          if (_user != null)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: _signOut,
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: _user != null ? _buildProfile() : _buildLogin(),
      ),
    );
  }

  Widget _buildLogin() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          '소셜 로그인',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 32),

        // 5. 버튼 그룹 사용
        LoginButtonGroup(
          providers: kAuth.configuredProviders,
          onPressed: _signIn,
          buttonSize: ButtonSize.large,
          loadingStates: {
            for (final p in AuthProvider.values) p: _isLoading,
          },
        ),

        if (_error != null) ...[
          const SizedBox(height: 16),
          Text(_error!, style: const TextStyle(color: Colors.red)),
        ],
      ],
    );
  }

  Widget _buildProfile() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_user!.image != null)
            CircleAvatar(
              radius: 50,
              backgroundImage: NetworkImage(_user!.image!),
            ),
          const SizedBox(height: 16),
          Text(
            _user!.displayName ?? 'User',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          if (_user!.email != null) ...[
            const SizedBox(height: 8),
            Text(_user!.email!, style: const TextStyle(color: Colors.grey)),
          ],
          const SizedBox(height: 8),
          Chip(label: Text(_user!.provider.toUpperCase())),
        ],
      ),
    );
  }
}
