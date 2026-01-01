# 프레임워크 통합 가이드

k_auth를 Dio, Riverpod 등 인기 있는 Flutter 패키지와 함께 사용하는 방법을 설명합니다.

## 목차

- [Dio HTTP 인터셉터](#dio-http-인터셉터)
- [Riverpod 상태 관리](#riverpod-상태-관리)
- [Dio + Riverpod 조합](#dio--riverpod-조합)

---

## Dio HTTP 인터셉터

백엔드 API 호출 시 토큰 자동 첨부 및 401 에러 시 자동 갱신을 처리합니다.

### 설치

```yaml
dependencies:
  dio: ^5.4.0
  k_auth: ^0.5.6
```

### AuthInterceptor 구현

```dart
import 'package:dio/dio.dart';
import 'package:k_auth/k_auth.dart';

/// KAuth 토큰을 자동으로 관리하는 Dio 인터셉터
///
/// - 모든 요청에 Authorization 헤더 자동 첨부
/// - 401 응답 시 토큰 갱신 후 재시도
/// - 갱신 실패 시 자동 로그아웃
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required this.kAuth,
    required this.dio,
    this.onAuthError,
  });

  final KAuth kAuth;
  final Dio dio;

  /// 인증 실패 시 콜백 (로그아웃 후 로그인 화면 이동 등)
  final void Function()? onAuthError;

  bool _isRefreshing = false;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = kAuth.lastResult?.accessToken;
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode != 401) {
      return handler.next(err);
    }

    // 이미 갱신 중이면 대기하지 않고 에러 반환
    if (_isRefreshing) {
      return handler.next(err);
    }

    // 토큰 갱신 불가능한 Provider (Apple 등)
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
```

### 사용법

```dart
late final Dio dio;
late final KAuth kAuth;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  kAuth = await KAuth.init(
    kakao: KakaoConfig(appKey: 'YOUR_KEY'),
  );

  dio = Dio(BaseOptions(
    baseUrl: 'https://api.example.com',
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  dio.interceptors.add(AuthInterceptor(
    kAuth: kAuth,
    dio: dio,
    onAuthError: () {
      // 로그인 화면으로 이동
      navigatorKey.currentState?.pushReplacementNamed('/login');
    },
  ));

  runApp(MyApp());
}

// 이제 모든 요청에 토큰이 자동으로 첨부됩니다
Future<void> fetchUserProfile() async {
  final response = await dio.get('/users/me');
  print(response.data);
}
```

### 토큰 만료 사전 체크

요청 전에 토큰 만료를 미리 확인하여 불필요한 401 에러를 방지합니다.

```dart
@override
void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
  // 토큰이 곧 만료되면 미리 갱신
  if (kAuth.isExpiringSoon(const Duration(minutes: 1))) {
    if (kAuth.currentProvider?.supportsTokenRefresh == true) {
      await kAuth.refreshToken();
    }
  }

  final token = kAuth.lastResult?.accessToken;
  if (token != null) {
    options.headers['Authorization'] = 'Bearer $token';
  }
  handler.next(options);
}
```

---

## Riverpod 상태 관리

KAuth를 Riverpod Provider로 래핑하여 선언적으로 인증 상태를 관리합니다.

### 설치

```yaml
dependencies:
  flutter_riverpod: ^2.4.0
  k_auth: ^0.5.6
```

### Provider 정의

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:k_auth/k_auth.dart';

/// KAuth 인스턴스 Provider
/// main()에서 overrideWithValue로 초기화
final kAuthProvider = Provider<KAuth>((ref) {
  throw UnimplementedError('main()에서 override 필요');
});

/// 현재 사용자 (실시간 스트림)
final authStateProvider = StreamProvider<KAuthUser?>((ref) {
  return ref.watch(kAuthProvider).authStateChanges;
});

/// 로그인 상태
final isSignedInProvider = Provider<bool>((ref) {
  return ref.watch(authStateProvider).valueOrNull != null;
});

/// 현재 사용자 (동기)
final currentUserProvider = Provider<KAuthUser?>((ref) {
  return ref.watch(authStateProvider).valueOrNull;
});
```

### main.dart 설정

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final kAuth = await KAuth.init(
    kakao: KakaoConfig(appKey: 'YOUR_KEY'),
    naver: NaverConfig(
      clientId: 'YOUR_ID',
      clientSecret: 'YOUR_SECRET',
      appName: 'My App',
    ),
  );

  runApp(
    ProviderScope(
      overrides: [
        kAuthProvider.overrideWithValue(kAuth),
      ],
      child: const MyApp(),
    ),
  );
}
```

### 화면에서 사용

```dart
class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return MaterialApp(
      home: authState.when(
        data: (user) => user != null ? HomeScreen() : LoginScreen(),
        loading: () => const SplashScreen(),
        error: (e, _) => ErrorScreen(error: e),
      ),
    );
  }
}
```

### 로그인 화면

```dart
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
      body: Center(
        child: LoginButtonGroup(
          providers: kAuth.configuredProviders,
          loading: _loading,
          onPressed: _signIn,
        ),
      ),
    );
  }
}
```

### 홈 화면

```dart
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final kAuth = ref.read(kAuthProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('안녕하세요, ${user?.displayName ?? "사용자"}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => kAuth.signOut(),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (user?.avatar != null)
              CircleAvatar(
                radius: 40,
                backgroundImage: NetworkImage(user!.avatar!),
              ),
            const SizedBox(height: 16),
            Text(user?.email ?? ''),
          ],
        ),
      ),
    );
  }
}
```

---

## Dio + Riverpod 조합

두 패키지를 함께 사용하여 완전한 인증 시스템을 구축합니다.

### Provider 정의

```dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:k_auth/k_auth.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Auth Providers
// ─────────────────────────────────────────────────────────────────────────────

final kAuthProvider = Provider<KAuth>((ref) {
  throw UnimplementedError();
});

final authStateProvider = StreamProvider<KAuthUser?>((ref) {
  return ref.watch(kAuthProvider).authStateChanges;
});

final isSignedInProvider = Provider<bool>((ref) {
  return ref.watch(authStateProvider).valueOrNull != null;
});

// ─────────────────────────────────────────────────────────────────────────────
// Dio Provider
// ─────────────────────────────────────────────────────────────────────────────

final dioProvider = Provider<Dio>((ref) {
  final kAuth = ref.watch(kAuthProvider);

  final dio = Dio(BaseOptions(
    baseUrl: 'https://api.example.com',
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  dio.interceptors.add(AuthInterceptor(
    kAuth: kAuth,
    dio: dio,
  ));

  return dio;
});

// ─────────────────────────────────────────────────────────────────────────────
// API Providers (예시)
// ─────────────────────────────────────────────────────────────────────────────

/// 사용자 프로필 조회
final userProfileProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get('/users/me');
  return response.data;
});

/// 게시글 목록 조회
final postsProvider = FutureProvider<List<dynamic>>((ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get('/posts');
  return response.data;
});
```

### 사용 예시

```dart
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('프로필')),
      body: profileAsync.when(
        data: (profile) => Column(
          children: [
            Text('이름: ${profile['name']}'),
            Text('이메일: ${profile['email']}'),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('에러: $e')),
      ),
    );
  }
}
```

---

## 관련 문서

- [기본 설정 가이드](SETUP.md)
- [문제 해결](TROUBLESHOOTING.md)
- [예제 앱](../example/)
