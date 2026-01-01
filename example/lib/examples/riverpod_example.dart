/// Riverpod 상태 관리 예제
///
/// KAuth를 Riverpod Provider로 래핑하여 선언적으로 인증 상태를 관리합니다.
///
/// ## 주요 기능
/// - StreamProvider로 실시간 인증 상태 감지
/// - Provider로 KAuth 인스턴스 공유
/// - ConsumerWidget으로 반응형 UI
///
/// ## 실행
/// ```bash
/// flutter run -t lib/examples/riverpod_example.dart
/// ```
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:k_auth/k_auth.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Providers
// ─────────────────────────────────────────────────────────────────────────────

/// KAuth 인스턴스
/// main()에서 overrideWithValue로 초기화
final kAuthProvider = Provider<KAuth>((ref) {
  throw UnimplementedError('main()에서 override 필요');
});

/// 인증 상태 스트림
final authStateProvider = StreamProvider<KAuthUser?>((ref) {
  return ref.watch(kAuthProvider).authStateChanges;
});

/// 로그인 여부
final isSignedInProvider = Provider<bool>((ref) {
  return ref.watch(authStateProvider).valueOrNull != null;
});

/// 현재 사용자 (동기 접근)
final currentUserProvider = Provider<KAuthUser?>((ref) {
  return ref.watch(authStateProvider).valueOrNull;
});

/// 토큰 만료 임박 여부
final isExpiringSoonProvider = Provider<bool>((ref) {
  final kAuth = ref.watch(kAuthProvider);
  return kAuth.isExpiringSoon();
});

// ─────────────────────────────────────────────────────────────────────────────
// Main
// ─────────────────────────────────────────────────────────────────────────────

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final kAuth = await KAuth.init(
    kakao: KakaoConfig(appKey: 'YOUR_KAKAO_APP_KEY'),
    naver: NaverConfig(
      clientId: 'YOUR_NAVER_CLIENT_ID',
      clientSecret: 'YOUR_NAVER_CLIENT_SECRET',
      appName: 'Riverpod Example',
    ),
    google: GoogleConfig(),
    apple: AppleConfig(),
  );

  runApp(
    ProviderScope(
      overrides: [
        kAuthProvider.overrideWithValue(kAuth),
      ],
      child: const RiverpodExampleApp(),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// App
// ─────────────────────────────────────────────────────────────────────────────

class RiverpodExampleApp extends ConsumerWidget {
  const RiverpodExampleApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return MaterialApp(
      title: 'Riverpod Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: authState.when(
        data: (user) => user != null ? const HomeScreen() : const LoginScreen(),
        loading: () => const SplashScreen(),
        error: (e, _) => ErrorScreen(error: e),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SplashScreen
// ─────────────────────────────────────────────────────────────────────────────

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('로딩 중...'),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ErrorScreen
// ─────────────────────────────────────────────────────────────────────────────

class ErrorScreen extends StatelessWidget {
  const ErrorScreen({super.key, required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('에러: $error'),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LoginScreen
// ─────────────────────────────────────────────────────────────────────────────

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  AuthProvider? _loading;

  Future<void> _signIn(AuthProvider provider) async {
    setState(() => _loading = provider);

    final kAuth = ref.read(kAuthProvider);
    final result = await kAuth.signIn(provider);

    if (mounted) {
      setState(() => _loading = null);

      result.onFailure((failure) {
        if (!failure.shouldIgnore) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(failure.displayMessage)),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final kAuth = ref.watch(kAuthProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // 로고
              const Icon(Icons.flutter_dash, size: 64, color: Colors.teal),
              const SizedBox(height: 16),
              Text(
                'Riverpod Example',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'KAuth + Riverpod',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey,
                    ),
              ),

              const Spacer(flex: 2),

              // 로그인 버튼들
              LoginButtonGroup(
                providers: kAuth.configuredProviders,
                loading: _loading,
                onPressed: _signIn,
                spacing: 12,
              ),

              const Spacer(flex: 3),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HomeScreen
// ─────────────────────────────────────────────────────────────────────────────

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final kAuth = ref.read(kAuthProvider);
    final isExpiring = ref.watch(isExpiringSoonProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('홈'),
        actions: [
          // 토큰 갱신 버튼
          if (kAuth.currentProvider?.supportsTokenRefresh == true)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: '토큰 갱신',
              onPressed: () async {
                final result = await kAuth.refreshToken();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        result.success ? '토큰 갱신 성공' : '토큰 갱신 실패',
                      ),
                    ),
                  );
                }
              },
            ),
          // 로그아웃 버튼
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: '로그아웃',
            onPressed: () => kAuth.signOut(),
          ),
        ],
      ),
      body: Column(
        children: [
          // 토큰 만료 경고 배너
          if (isExpiring)
            MaterialBanner(
              content: const Text('세션이 곧 만료됩니다'),
              backgroundColor: Colors.orange.shade50,
              leading: const Icon(Icons.warning, color: Colors.orange),
              actions: [
                TextButton(
                  onPressed: () => kAuth.refreshToken(),
                  child: const Text('갱신'),
                ),
              ],
            ),

          // 사용자 정보
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 프로필 이미지
                    CircleAvatar(
                      radius: 48,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: user?.avatar != null
                          ? NetworkImage(user!.avatar!)
                          : null,
                      child: user?.avatar == null
                          ? const Icon(Icons.person,
                              size: 48, color: Colors.grey)
                          : null,
                    ),
                    const SizedBox(height: 24),

                    // 이름
                    Text(
                      user?.displayName ?? '사용자',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                    ),

                    // 이메일
                    if (user?.email != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        user!.email!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey,
                            ),
                      ),
                    ],

                    const SizedBox(height: 32),

                    // Provider 정보 카드
                    const ProviderInfoCard(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ProviderInfoCard
// ─────────────────────────────────────────────────────────────────────────────

class ProviderInfoCard extends ConsumerWidget {
  const ProviderInfoCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kAuth = ref.watch(kAuthProvider);
    final user = ref.watch(currentUserProvider);

    if (user == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Provider 정보',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const Divider(),
            _row('Provider', user.provider.displayName),
            _row('User ID', kAuth.userId ?? '-'),
            _row('토큰 만료', _formatExpiry(kAuth.expiresIn)),
            _row(
                '갱신 가능',
                kAuth.currentProvider?.supportsTokenRefresh == true
                    ? 'O'
                    : 'X'),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value),
        ],
      ),
    );
  }

  String _formatExpiry(Duration? duration) {
    if (duration == null) return '-';
    if (duration.isNegative) return '만료됨';
    if (duration.inHours > 0) return '${duration.inHours}시간';
    return '${duration.inMinutes}분';
  }
}
