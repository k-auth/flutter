import 'dart:async';
import 'package:flutter/material.dart';
import 'package:k_auth/k_auth.dart';

// ─────────────────────────────────────────────────────────────────────────────
// 설정
// ─────────────────────────────────────────────────────────────────────────────

/// Demo 모드: API 키 없이 UI 테스트 가능
const kDemoMode = true;

late final dynamic kAuth;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  kAuth = kDemoMode
      ? (MockKAuth(mockDelay: const Duration(milliseconds: 800))..initialize())
      : (KAuth(
          config: KAuthConfig(
            kakao: KakaoConfig(appKey: 'YOUR_KAKAO_APP_KEY'),
            naver: NaverConfig(
              clientId: 'YOUR_NAVER_CLIENT_ID',
              clientSecret: 'YOUR_NAVER_CLIENT_SECRET',
              appName: 'K-Auth Example',
            ),
            google: GoogleConfig(),
            apple: AppleConfig(),
          ),
        )..initialize());

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
      title: 'K-Auth',
      debugShowCheckedModeBanner: false,
      theme: _theme(Brightness.light),
      darkTheme: _theme(Brightness.dark),
      home: const AuthScreen(),
    );
  }

  ThemeData _theme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return ThemeData(
      brightness: brightness,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: const Color(0xFF1A1A1A),
        onPrimary: Colors.white,
        secondary: const Color(0xFF1A1A1A),
        onSecondary: Colors.white,
        error: Colors.red,
        onError: Colors.white,
        surface: isDark ? const Color(0xFF0A0A0A) : Colors.white,
        onSurface: isDark ? const Color(0xFFFAFAFA) : const Color(0xFF1A1A1A),
        outline: isDark ? const Color(0xFF757575) : const Color(0xFF9E9E9E),
      ),
      scaffoldBackgroundColor: isDark ? const Color(0xFF0A0A0A) : Colors.white,
      useMaterial3: true,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Auth Screen
// ─────────────────────────────────────────────────────────────────────────────

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  KAuthUser? _user;
  AuthProvider? _loadingProvider;
  StreamSubscription? _authSub;

  @override
  void initState() {
    super.initState();
    _authSub = kAuth.authStateChanges.listen((user) {
      if (mounted) setState(() => _user = user);
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  Future<void> _signIn(AuthProvider provider) async {
    setState(() => _loadingProvider = provider);

    if (kDemoMode && kAuth is MockKAuth) {
      (kAuth as MockKAuth).mockUser = _getMockUser(provider);
    }

    final result = await kAuth.signIn(provider);
    if (mounted) setState(() => _loadingProvider = null);

    result.fold(
      onSuccess: (_) {},
      onFailure: (f) {
        if (!f.isCancelled && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(f.message ?? '로그인 실패')),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _user != null
            ? _ProfileView(user: _user!, onSignOut: kAuth.signOut)
            : _LoginView(
                onSignIn: _signIn,
                loadingProvider: _loadingProvider,
              ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Login View
// ─────────────────────────────────────────────────────────────────────────────

class _LoginView extends StatelessWidget {
  const _LoginView({required this.onSignIn, this.loadingProvider});

  final Future<void> Function(AuthProvider) onSignIn;
  final AuthProvider? loadingProvider;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          const Spacer(flex: 2),
          // Logo
          Text(
            'K-Auth',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: colors.onSurface,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '한국 앱을 위한 소셜 로그인',
            style: TextStyle(fontSize: 15, color: colors.outline),
          ),
          const Spacer(flex: 2),
          // Buttons
          LoginButtonGroup(
            providers: kAuth.configuredProviders,
            onPressed: onSignIn,
            spacing: 12,
            loadingStates: {
              for (final p in AuthProvider.values) p: loadingProvider == p,
            },
            disabledStates: {
              for (final p in AuthProvider.values)
                p: loadingProvider != null && loadingProvider != p,
            },
          ),
          const Spacer(flex: 3),
          // Demo badge
          if (kDemoMode)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                'demo',
                style: TextStyle(
                  fontSize: 11,
                  color: colors.outline.withValues(alpha: 0.5),
                  letterSpacing: 2,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Profile View
// ─────────────────────────────────────────────────────────────────────────────

class _ProfileView extends StatelessWidget {
  const _ProfileView({required this.user, required this.onSignOut});

  final KAuthUser user;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          const Spacer(flex: 2),
          // Avatar
          CircleAvatar(
            radius: 48,
            backgroundColor: colors.outline.withValues(alpha: 0.1),
            backgroundImage:
                user.avatar != null ? NetworkImage(user.avatar!) : null,
            child: user.avatar == null
                ? Icon(Icons.person, size: 48, color: colors.outline)
                : null,
          ),
          const SizedBox(height: 24),
          // Name
          Text(
            user.displayName ?? 'User',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: colors.onSurface,
            ),
          ),
          if (user.email != null) ...[
            const SizedBox(height: 4),
            Text(
              user.email!,
              style: TextStyle(fontSize: 15, color: colors.outline),
            ),
          ],
          const SizedBox(height: 32),
          // Provider badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: colors.outline.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _providerColor(user.provider, isDark),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${user.provider.displayName}로 로그인',
                  style: TextStyle(fontSize: 14, color: colors.onSurface),
                ),
              ],
            ),
          ),
          const Spacer(flex: 3),
          // Sign out
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onSignOut,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: colors.outline.withValues(alpha: 0.3)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                '로그아웃',
                style: TextStyle(fontSize: 16, color: colors.onSurface),
              ),
            ),
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  Color _providerColor(AuthProvider provider, bool isDark) =>
      switch (provider) {
        AuthProvider.kakao => const Color(0xFFFEE500),
        AuthProvider.naver => const Color(0xFF03C75A),
        AuthProvider.google => const Color(0xFF4285F4),
        AuthProvider.apple => isDark ? Colors.white : Colors.black,
      };
}

// ─────────────────────────────────────────────────────────────────────────────
// Mock Data (Demo 모드 전용)
// ─────────────────────────────────────────────────────────────────────────────

KAuthUser _getMockUser(AuthProvider provider) => KAuthUser(
      id: '${provider.name}_mock',
      provider: provider,
      email: 'user@${provider.name}.com',
      name: switch (provider) {
        AuthProvider.kakao => '카카오 사용자',
        AuthProvider.naver => '네이버 사용자',
        AuthProvider.google => 'Google User',
        AuthProvider.apple => 'Apple User',
      },
      avatar:
          'https://api.dicebear.com/7.x/avataaars/png?seed=${provider.name}',
    );
