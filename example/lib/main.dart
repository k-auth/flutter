/// K-Auth Example
///
/// 이 예제는 k_auth 패키지의 핵심 기능을 보여줍니다.
/// 복사해서 바로 사용할 수 있도록 작성되었습니다.
///
/// ## 주요 기능
/// - KAuth.init()으로 간단한 초기화
/// - KAuthBuilder로 인증 상태 기반 화면 전환
/// - LoginButtonGroup으로 로그인 버튼
/// - fold/when 패턴으로 결과 처리
library;

import 'package:flutter/material.dart';
import 'package:k_auth/k_auth.dart';

// ─────────────────────────────────────────────────────────────────────────────
// 설정
// ─────────────────────────────────────────────────────────────────────────────

/// Demo 모드: true면 API 키 없이 UI 테스트 가능
const kDemoMode = true;

/// KAuth 인스턴스 (main에서 초기화)
late final KAuth kAuth;

// ─────────────────────────────────────────────────────────────────────────────
// Main
// ─────────────────────────────────────────────────────────────────────────────

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ 권장: KAuth.init()으로 한 번에 초기화
  // - SecureStorage 자동 설정
  // - 자동 로그인 복원
  // - 모든 Provider 초기화
  kAuth = await KAuth.init(
    kakao: KakaoConfig(appKey: 'YOUR_KAKAO_APP_KEY'),
    naver: NaverConfig(
      clientId: 'YOUR_NAVER_CLIENT_ID',
      clientSecret: 'YOUR_NAVER_CLIENT_SECRET',
      appName: 'K-Auth Example',
    ),
    google: GoogleConfig(),
    apple: AppleConfig(),
  );

  runApp(const App());
}

// ─────────────────────────────────────────────────────────────────────────────
// App
// ─────────────────────────────────────────────────────────────────────────────

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'K-Auth Example',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      // ✅ 권장: KAuthBuilder로 인증 상태에 따라 화면 전환
      home: KAuthBuilder(
        stream: kAuth.authStateChanges,
        initialUser: kAuth.currentUser,
        signedIn: (user) => ProfileScreen(user: user),
        signedOut: () => const LoginScreen(),
        loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 로그인 화면
// ─────────────────────────────────────────────────────────────────────────────

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  AuthProvider? _loadingProvider;

  Future<void> _signIn(AuthProvider provider) async {
    setState(() => _loadingProvider = provider);

    final result = await kAuth.signIn(provider);

    if (mounted) setState(() => _loadingProvider = null);

    // ✅ 권장: when 패턴으로 성공/취소/실패 구분
    result.when(
      success: (user) {
        // KAuthBuilder가 자동으로 화면 전환하므로 별도 처리 불필요
      },
      cancelled: () {
        // 사용자가 취소한 경우 - 보통 무시
      },
      failure: (failure) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(failure.displayMessage),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // 로고
              const Icon(Icons.lock_open, size: 64, color: Colors.blue),
              const SizedBox(height: 16),
              Text(
                'K-Auth',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                '한국 앱을 위한 소셜 로그인',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey,
                    ),
              ),

              const Spacer(flex: 2),

              // ✅ 권장: LoginButtonGroup으로 로그인 버튼들
              LoginButtonGroup(
                providers: kAuth.configuredProviders,
                onPressed: _signIn,
                spacing: 12,
                // 로딩 상태 표시
                loadingStates: {
                  for (final p in AuthProvider.values) p: _loadingProvider == p,
                },
                // 다른 버튼 비활성화
                disabledStates: {
                  for (final p in AuthProvider.values)
                    p: _loadingProvider != null && _loadingProvider != p,
                },
              ),

              const Spacer(flex: 3),

              // Demo 모드 표시
              if (kDemoMode)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    'DEMO MODE',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.withValues(alpha: 0.5),
                      letterSpacing: 2,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 프로필 화면
// ─────────────────────────────────────────────────────────────────────────────

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.user});

  final KAuthUser user;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('프로필'),
        actions: [
          // 로그아웃 버튼
          IconButton(
            onPressed: () => kAuth.signOut(),
            icon: const Icon(Icons.logout),
            tooltip: '로그아웃',
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 프로필 이미지
              CircleAvatar(
                radius: 48,
                backgroundColor: Colors.grey.shade200,
                backgroundImage:
                    user.avatar != null ? NetworkImage(user.avatar!) : null,
                child: user.avatar == null
                    ? const Icon(Icons.person, size: 48, color: Colors.grey)
                    : null,
              ),
              const SizedBox(height: 24),

              // 이름
              Text(
                user.displayName ?? '사용자',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),

              // 이메일
              if (user.email != null) ...[
                const SizedBox(height: 4),
                Text(
                  user.email!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey,
                      ),
                ),
              ],

              const SizedBox(height: 24),

              // Provider 배지
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _providerColor(user.provider).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _providerColor(user.provider).withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  '${user.provider.displayName}로 로그인',
                  style: TextStyle(
                    color: _providerColor(user.provider),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              const SizedBox(height: 48),

              // ✅ 편의 getter 예시
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '편의 getter 예시',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const Divider(),
                      _infoRow('kAuth.userId', kAuth.userId ?? '-'),
                      _infoRow('kAuth.name', kAuth.name ?? '-'),
                      _infoRow('kAuth.email', kAuth.email ?? '-'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontFamily: 'monospace')),
          const Spacer(),
          Text(value, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Color _providerColor(AuthProvider provider) => switch (provider) {
        AuthProvider.kakao => const Color(0xFFFFE812),
        AuthProvider.naver => const Color(0xFF03C75A),
        AuthProvider.google => const Color(0xFF4285F4),
        AuthProvider.apple => Colors.black,
      };
}
