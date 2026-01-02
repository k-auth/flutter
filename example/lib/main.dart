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
/// - 에러 처리 UI (재시도 다이얼로그, 토큰 만료 배너)
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
      failure: (failure) => _handleFailure(failure, provider),
    );
  }

  Future<void> _handleFailure(
      KAuthFailure failure, AuthProvider provider) async {
    if (!mounted || failure.shouldIgnore) return;

    // 재시도 가능한 에러는 다이얼로그로 처리
    if (failure.canRetry) {
      final retry = await showRetryDialog(context, failure);
      if (retry && mounted) {
        _signIn(provider);
      }
    } else {
      // 그 외 에러는 SnackBar로 표시
      showErrorSnackBar(context, failure);
    }
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

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.user});

  final KAuthUser user;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  KAuthUser get user => widget.user;
  bool _refreshing = false;

  Future<void> _refreshToken() async {
    setState(() => _refreshing = true);
    final result = await kAuth.refreshToken();
    if (mounted) {
      setState(() => _refreshing = false);
      result.onFailure((f) => showErrorSnackBar(context, f));
    }
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('로그아웃'),
        content: const Text('정말 로그아웃하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('로그아웃'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await kAuth.signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('프로필'),
        actions: [
          // 토큰 갱신 버튼
          if (kAuth.currentProvider?.supportsTokenRefresh == true)
            IconButton(
              onPressed: _refreshing ? null : _refreshToken,
              icon: _refreshing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
              tooltip: '토큰 갱신',
            ),
          // 로그아웃 버튼
          IconButton(
            onPressed: () => _confirmSignOut(context),
            icon: const Icon(Icons.logout),
            tooltip: '로그아웃',
          ),
        ],
      ),
      body: Column(
        children: [
          // ✅ 토큰 만료 배너
          TokenExpiryBanner(onRefresh: _refreshToken),
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
                      color:
                          _providerColor(user.provider).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _providerColor(user.provider)
                            .withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      '${user.provider.displayName}로 로그인',
                      style: TextStyle(
                        // 카카오는 노란색이라 검정 텍스트 사용
                        color: user.provider == AuthProvider.kakao
                            ? Colors.black87
                            : _providerColor(user.provider),
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
          )),
        ],
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
        AuthProvider.phone => const Color(0xFF1976D2),
      };
}

// ─────────────────────────────────────────────────────────────────────────────
// 에러 처리 UI
// ─────────────────────────────────────────────────────────────────────────────

/// 에러 SnackBar 표시 (severity에 따라 스타일 변경)
void showErrorSnackBar(BuildContext context, KAuthFailure failure) {
  if (failure.shouldIgnore) return; // 취소 등은 무시

  final color = switch (failure.severity) {
    ErrorSeverity.retryable => Colors.orange,
    ErrorSeverity.authRequired => Colors.deepPurple,
    ErrorSeverity.fixRequired => Colors.red.shade700,
    _ => Colors.red,
  };

  // 기존 SnackBar 제거 후 표시
  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(
        content: Text(failure.displayMessage),
        backgroundColor: color,
      ),
    );
}

/// 재시도 다이얼로그
Future<bool> showRetryDialog(BuildContext context, KAuthFailure failure) async {
  return await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('로그인 실패'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(failure.displayMessage),
              if (failure.canRetry) ...[
                const SizedBox(height: 12),
                Text(
                  '네트워크 연결을 확인하고 다시 시도해주세요.',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소'),
            ),
            if (failure.canRetry)
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('재시도'),
              ),
          ],
        ),
      ) ??
      false;
}

/// 토큰 만료 배너 위젯
class TokenExpiryBanner extends StatelessWidget {
  const TokenExpiryBanner({super.key, required this.onRefresh});

  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    // 토큰이 만료 임박하거나 만료된 경우에만 표시
    if (!kAuth.isSignedIn) return const SizedBox.shrink();
    if (!kAuth.isExpired && !kAuth.isExpiringSoon()) {
      return const SizedBox.shrink();
    }

    final isExpired = kAuth.isExpired;

    return MaterialBanner(
      content: Text(
        isExpired ? '세션이 만료되었습니다. 다시 로그인해주세요.' : '세션이 곧 만료됩니다.',
      ),
      backgroundColor: isExpired ? Colors.red.shade50 : Colors.orange.shade50,
      leading: Icon(
        isExpired ? Icons.error : Icons.warning,
        color: isExpired ? Colors.red : Colors.orange,
      ),
      actions: [
        if (!isExpired && kAuth.currentProvider?.supportsTokenRefresh == true)
          TextButton(
            onPressed: onRefresh,
            child: const Text('갱신'),
          ),
        if (isExpired)
          TextButton(
            onPressed: () => kAuth.signOut(),
            child: const Text('로그아웃'),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 백엔드 연동 예제 (주석)
// ─────────────────────────────────────────────────────────────────────────────

/*
/// 백엔드 연동 시 onSignIn 콜백 사용 예제
///
/// ```dart
/// final kAuth = await KAuth.init(
///   kakao: KakaoConfig(appKey: 'xxx'),
///   onSignIn: (provider, tokens) async {
///     // 1. 백엔드에 토큰 전송하여 JWT 발급
///     final response = await http.post(
///       Uri.parse('https://your-api.com/auth/social'),
///       body: {
///         'provider': provider.name,
///         'accessToken': tokens.accessToken,
///         'idToken': tokens.idToken,
///       },
///     );
///
///     // 2. JWT 저장
///     final jwt = jsonDecode(response.body)['jwt'];
///     await secureStorage.write(key: 'jwt', value: jwt);
///   },
///   onSignOut: (provider) async {
///     // JWT 삭제
///     await secureStorage.delete(key: 'jwt');
///   },
/// );
/// ```
///
/// 토큰 정보:
/// - tokens.accessToken: Provider 액세스 토큰
/// - tokens.refreshToken: Provider 리프레시 토큰 (nullable)
/// - tokens.idToken: ID 토큰 (Google/Apple만 제공)
/// - tokens.expiresAt: 만료 시간
*/
