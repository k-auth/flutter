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
  // 2. 세션 저장소 (자동 로그인용)
  storage: InMemorySessionStorage(),
  // 3. 로그인 콜백 (백엔드 연동)
  onSignIn: (provider, tokens, user) async {
    debugPrint('[onSignIn] ${provider.displayName} 로그인 성공');
    debugPrint('  - accessToken: ${tokens.accessToken?.substring(0, 20)}...');
    debugPrint('  - user: ${user.displayName}');
    // 백엔드에 토큰 전송하고 JWT 받아오기
    // final jwt = await myApi.socialLogin(tokens.accessToken);
    // return jwt;
    return null;
  },
  // 4. 로그아웃 콜백
  onSignOut: (provider) async {
    debugPrint('[onSignOut] ${provider.displayName} 로그아웃');
    // 백엔드 JWT 무효화
    // await myApi.logout();
  },
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 5. 디버그 로깅 활성화 (개발 환경에서만)
  KAuthLogger.level = KAuthLogLevel.debug;

  // 6. 초기화 + 자동 로그인 (세션 복원)
  await kAuth.initialize(autoRestore: true);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'K-Auth Example',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
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
  AuthProvider? _loadingProvider;
  String? _error;

  @override
  void initState() {
    super.initState();
    // 4. 인증 상태 변화 감지
    kAuth.authStateChanges.listen((user) {
      setState(() => _user = user);
    });
  }

  // 5. 함수형 스타일 로그인
  Future<void> _signIn(AuthProvider provider) async {
    setState(() {
      _loadingProvider = provider;
      _error = null;
    });

    final result = await kAuth.signIn(provider);

    setState(() => _loadingProvider = null);

    // 함수형 패턴으로 결과 처리
    result.when(
      success: (user) {
        // 성공 시 자동으로 authStateChanges에서 처리됨
        _showSnackBar('환영합니다, ${user.displayName}님!');
      },
      cancelled: () {
        _showSnackBar('로그인을 취소했습니다');
      },
      failure: (failure) {
        setState(() => _error = failure.message);
        _showErrorDialog(failure.code, failure.message);
      },
    );
  }

  // 6. 로그아웃
  Future<void> _signOut() async {
    await kAuth.signOut();
    _showSnackBar('로그아웃되었습니다');
  }

  // 7. 토큰 갱신
  Future<void> _refreshToken() async {
    final result = await kAuth.refreshToken();
    result.fold(
      onSuccess: (user) => _showSnackBar('토큰이 갱신되었습니다'),
      onFailure: (error) => _showSnackBar('토큰 갱신 실패: $error'),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  void _showErrorDialog(String? code, String? message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('로그인 실패'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message ?? '알 수 없는 오류'),
            if (code != null) ...[
              const SizedBox(height: 8),
              Text(
                '에러 코드: $code',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('K-Auth Example'),
        centerTitle: true,
        actions: [
          if (_user != null)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: _signOut,
              tooltip: '로그아웃',
            ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _user != null ? _buildProfile() : _buildLogin(),
        ),
      ),
    );
  }

  Widget _buildLogin() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 헤더
        Icon(
          Icons.lock_outline,
          size: 64,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 16),
        Text(
          '소셜 로그인',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          '카카오, 네이버, 구글, 애플 계정으로\n간편하게 로그인하세요',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
        ),
        const SizedBox(height: 48),

        // 7. 버튼 그룹 사용 (로딩 상태 개별 관리)
        LoginButtonGroup(
          providers: kAuth.configuredProviders,
          onPressed: _signIn,
          buttonSize: ButtonSize.large,
          loadingStates: {
            for (final p in AuthProvider.values) p: _loadingProvider == p,
          },
          disabledStates: {
            for (final p in AuthProvider.values)
              p: _loadingProvider != null && _loadingProvider != p,
          },
        ),

        // 에러 메시지
        if (_error != null) ...[
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildProfile() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 프로필 이미지
          CircleAvatar(
            radius: 50,
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            backgroundImage:
                _user!.avatar != null ? NetworkImage(_user!.avatar!) : null,
            child: _user!.avatar == null
                ? Icon(
                    Icons.person,
                    size: 50,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  )
                : null,
          ),
          const SizedBox(height: 24),

          // 이름
          Text(
            _user!.displayName ?? 'User',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),

          // 이메일
          if (_user!.email != null) ...[
            const SizedBox(height: 4),
            Text(
              _user!.email!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ],

          const SizedBox(height: 12),

          // Provider 뱃지
          Chip(
            avatar: Icon(
              _getProviderIcon(_user!.provider),
              size: 18,
            ),
            label: Text(_user!.provider.toUpperCase()),
          ),

          const SizedBox(height: 32),

          // 사용자 정보 카드
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '사용자 정보',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const Divider(),
                  _buildInfoRow('ID', _user!.id),
                  if (_user!.name != null) _buildInfoRow('이름', _user!.name!),
                  if (_user!.email != null)
                    _buildInfoRow('이메일', _user!.email!),
                  if (_user!.phone != null)
                    _buildInfoRow('전화번호', _user!.phone!),
                  if (_user!.gender != null)
                    _buildInfoRow('성별', _user!.gender!),
                  if (_user!.age != null)
                    _buildInfoRow('나이', '만 ${_user!.age}세'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // 버튼 그룹
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 토큰 갱신 버튼
              if (kAuth.currentProvider?.supportsTokenRefresh ?? false)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: OutlinedButton.icon(
                    onPressed: _refreshToken,
                    icon: const Icon(Icons.refresh),
                    label: const Text('토큰 갱신'),
                  ),
                ),
              // 로그아웃 버튼
              FilledButton.tonalIcon(
                onPressed: _signOut,
                icon: const Icon(Icons.logout),
                label: const Text('로그아웃'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getProviderIcon(String provider) {
    switch (provider.toLowerCase()) {
      case 'kakao':
        return Icons.chat_bubble;
      case 'naver':
        return Icons.north_east;
      case 'google':
        return Icons.g_mobiledata;
      case 'apple':
        return Icons.apple;
      default:
        return Icons.login;
    }
  }
}
