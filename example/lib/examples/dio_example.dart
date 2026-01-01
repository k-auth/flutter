/// Dio HTTP 인터셉터 예제
///
/// KAuth와 Dio를 함께 사용하여 백엔드 API 호출 시
/// 토큰 자동 첨부 및 401 에러 시 자동 갱신을 처리합니다.
///
/// ## 주요 기능
/// - Authorization 헤더 자동 첨부
/// - 401 응답 시 토큰 갱신 후 재시도
/// - 갱신 실패 시 자동 로그아웃
///
/// ## 실행
/// ```bash
/// flutter run -t lib/examples/dio_example.dart
/// ```
library;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:k_auth/k_auth.dart';

// ─────────────────────────────────────────────────────────────────────────────
// 설정
// ─────────────────────────────────────────────────────────────────────────────

late final KAuth kAuth;
late final Dio dio;

final navigatorKey = GlobalKey<NavigatorState>();

// ─────────────────────────────────────────────────────────────────────────────
// Main
// ─────────────────────────────────────────────────────────────────────────────

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. KAuth 초기화
  kAuth = await KAuth.init(
    kakao: KakaoConfig(appKey: 'YOUR_KAKAO_APP_KEY'),
    naver: NaverConfig(
      clientId: 'YOUR_NAVER_CLIENT_ID',
      clientSecret: 'YOUR_NAVER_CLIENT_SECRET',
      appName: 'Dio Example',
    ),
  );

  // 2. Dio 초기화 + AuthInterceptor 추가
  dio = Dio(BaseOptions(
    baseUrl: 'https://api.example.com',
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  dio.interceptors.add(AuthInterceptor(
    kAuth: kAuth,
    dio: dio,
    onAuthError: () {
      // 인증 실패 시 로그인 화면으로 이동
      navigatorKey.currentState
          ?.pushNamedAndRemoveUntil('/login', (_) => false);
    },
  ));

  runApp(const DioExampleApp());
}

// ─────────────────────────────────────────────────────────────────────────────
// AuthInterceptor
// ─────────────────────────────────────────────────────────────────────────────

/// KAuth 토큰을 자동으로 관리하는 Dio 인터셉터
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required this.kAuth,
    required this.dio,
    this.onAuthError,
  });

  final KAuth kAuth;
  final Dio dio;
  final VoidCallback? onAuthError;

  bool _isRefreshing = false;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // 토큰이 곧 만료되면 미리 갱신 (1분 이내)
    if (kAuth.isExpiringSoon(const Duration(minutes: 1))) {
      if (kAuth.currentProvider?.supportsTokenRefresh == true) {
        await kAuth.refreshToken();
      }
    }

    // Authorization 헤더 추가
    final token = kAuth.lastResult?.accessToken;
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // 401이 아니면 그대로 전달
    if (err.response?.statusCode != 401) {
      return handler.next(err);
    }

    // 이미 갱신 중이면 에러 반환
    if (_isRefreshing) {
      return handler.next(err);
    }

    // 토큰 갱신 불가능한 Provider
    if (kAuth.currentProvider?.supportsTokenRefresh != true) {
      await _handleAuthFailure();
      return handler.next(err);
    }

    // 토큰 갱신 시도
    _isRefreshing = true;
    final result = await kAuth.refreshToken();
    _isRefreshing = false;

    if (result.success) {
      // 갱신 성공 → 원래 요청 재시도
      final newToken = kAuth.lastResult?.accessToken;
      err.requestOptions.headers['Authorization'] = 'Bearer $newToken';

      try {
        final response = await dio.fetch(err.requestOptions);
        return handler.resolve(response);
      } catch (e) {
        return handler.next(err);
      }
    }

    // 갱신 실패 → 로그아웃
    await _handleAuthFailure();
    handler.next(err);
  }

  Future<void> _handleAuthFailure() async {
    await kAuth.signOut();
    onAuthError?.call();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// App
// ─────────────────────────────────────────────────────────────────────────────

class DioExampleApp extends StatelessWidget {
  const DioExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dio Example',
      navigatorKey: navigatorKey,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      routes: {
        '/': (_) => const AuthGate(),
        '/login': (_) => const LoginScreen(),
        '/home': (_) => const HomeScreen(),
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AuthGate - 인증 상태에 따라 화면 분기
// ─────────────────────────────────────────────────────────────────────────────

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return KAuthBuilder(
      stream: kAuth.authStateChanges,
      initialUser: kAuth.currentUser,
      signedIn: (_) => const HomeScreen(),
      signedOut: () => const LoginScreen(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LoginScreen
// ─────────────────────────────────────────────────────────────────────────────

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  AuthProvider? _loading;

  Future<void> _signIn(AuthProvider provider) async {
    setState(() => _loading = provider);
    final result = await kAuth.signIn(provider);
    if (mounted) setState(() => _loading = null);

    result.onFailure((failure) {
      if (!failure.shouldIgnore && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failure.displayMessage)),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dio Example')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: LoginButtonGroup(
            providers: kAuth.configuredProviders,
            loading: _loading,
            onPressed: _signIn,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HomeScreen - API 호출 예시
// ─────────────────────────────────────────────────────────────────────────────

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _apiResult = '버튼을 눌러 API를 호출하세요';
  bool _loading = false;

  /// API 호출 예시
  /// AuthInterceptor가 자동으로 토큰을 첨부합니다.
  Future<void> _callApi() async {
    setState(() {
      _loading = true;
      _apiResult = '로딩 중...';
    });

    try {
      // 실제 API 호출 (예시)
      // final response = await dio.get('/users/me');
      // _apiResult = response.data.toString();

      // 데모: 토큰 정보 표시
      await Future.delayed(const Duration(milliseconds: 500));
      final token = kAuth.lastResult?.accessToken;
      final tokenPreview = token != null && token.length > 20
          ? '${token.substring(0, 20)}...'
          : token ?? '없음';
      _apiResult = '''
API 호출 성공!

토큰이 자동으로 첨부되었습니다:
Authorization: Bearer $tokenPreview

만료 시간: ${kAuth.expiresAt}
남은 시간: ${kAuth.expiresIn.inMinutes}분
''';
    } on DioException catch (e) {
      _apiResult = 'API 에러: ${e.message}';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('안녕하세요, ${kAuth.name ?? "사용자"}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => kAuth.signOut(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // API 호출 버튼
            FilledButton.icon(
              onPressed: _loading ? null : _callApi,
              icon: _loading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.cloud_download),
              label: const Text('API 호출'),
            ),

            const SizedBox(height: 24),

            // 결과 표시
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _apiResult,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 토큰 갱신 버튼
            if (kAuth.currentProvider?.supportsTokenRefresh == true)
              OutlinedButton.icon(
                onPressed: () async {
                  final result = await kAuth.refreshToken();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          result.success ? '토큰 갱신 성공' : '토큰 갱신 실패',
                        ),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.refresh),
                label: const Text('토큰 갱신'),
              ),
          ],
        ),
      ),
    );
  }
}
