# K-Auth 코드 패턴 (AI 코드 생성 가이드)

> 이 문서는 AI 코드 생성 도구(Claude Code, GitHub Copilot 등)가 k-auth를 사용하는 코드를 쉽게 생성할 수 있도록 작성되었습니다.

## 📋 목차

- [패턴 1: 가장 간단한 로그인 (복붙 가능)](#패턴-1-가장-간단한-로그인)
- [패턴 2: 백엔드 연동](#패턴-2-백엔드-연동)
- [패턴 3: 자동 로그인 (세션 복원)](#패턴-3-자동-로그인)
- [패턴 4: StreamBuilder 통합](#패턴-4-streambuilder-통합)
- [패턴 5: 에러 처리 (4가지 방법)](#패턴-5-에러-처리)
- [패턴 6: 버튼 위젯 사용](#패턴-6-버튼-위젯-사용)
- [안티패턴 (하지 말아야 할 것)](#안티패턴)

---

## 패턴 1: 가장 간단한 로그인

**사용 케이스**: 빠른 프로토타입, 간단한 앱

### 권장: KAuth.init() 사용

```dart
import 'package:flutter/material.dart';
import 'package:k_auth/k_auth.dart';

late final KAuth kAuth;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 한 줄로 초기화 + SecureStorage + 자동 로그인
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

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () async {
              final result = await kAuth.signIn(AuthProvider.kakao);

              if (result.success) {
                // 편의 getter 사용
                print('로그인 성공: ${kAuth.name}');
                print('이메일: ${kAuth.email}');
                print('프로필: ${kAuth.avatar}');
              } else {
                print('로그인 실패: ${result.errorMessage}');
              }
            },
            child: Text('카카오 로그인'),
          ),
        ),
      ),
    );
  }
}
```

### 기존 방식 (더 세밀한 제어)

```dart
final kAuth = KAuth(
  config: KAuthConfig(
    kakao: KakaoConfig(appKey: 'YOUR_KAKAO_APP_KEY'),
  ),
);

await kAuth.initialize();
```

---

## 패턴 2: 백엔드 연동

**사용 케이스**: 소셜 로그인 후 백엔드 서버에서 JWT 토큰 발급

```dart
import 'package:http/http.dart' as http;
import 'dart:convert';

final kAuth = KAuth(
  config: KAuthConfig(
    kakao: KakaoConfig(appKey: 'YOUR_APP_KEY'),
  ),
  // 로그인 성공 후 백엔드 호출
  onSignIn: (provider, tokens, user) async {
    try {
      // 백엔드 API 호출
      final response = await http.post(
        Uri.parse('https://api.myserver.com/auth/social'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'provider': provider.name,
          'accessToken': tokens.accessToken,
          'idToken': tokens.idToken,
          'user': {
            'id': user.id,
            'email': user.email,
            'name': user.displayName,
          },
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['jwt']; // serverToken에 저장됨
      }

      return null;
    } catch (e) {
      print('백엔드 연동 실패: $e');
      return null;
    }
  },
  // 로그아웃 시 백엔드에 알림
  onSignOut: (provider) async {
    try {
      await http.post(
        Uri.parse('https://api.myserver.com/auth/logout'),
        headers: {
          'Authorization': 'Bearer ${kAuth.serverToken}',
        },
      );
    } catch (e) {
      print('로그아웃 알림 실패: $e');
    }
  },
);

// 사용
void example() async {
  await kAuth.initialize();
  await kAuth.signIn(AuthProvider.kakao);

  // 백엔드에서 받은 JWT 토큰 사용
  final jwt = kAuth.serverToken;
  if (jwt != null) {
    print('JWT 토큰: $jwt');
    // API 요청 시 사용
    final response = await http.get(
      Uri.parse('https://api.myserver.com/profile'),
      headers: {'Authorization': 'Bearer $jwt'},
    );
  }
}
```

---

## 패턴 3: 자동 로그인

**사용 케이스**: 앱 재시작 시 자동으로 로그인 상태 복원

### 권장: KAuth.init() 사용 (기본 SecureStorage 포함)

```dart
late final KAuth kAuth;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // KAuth.init()은 자동으로:
  // - SecureStorage 사용 (암호화된 저장)
  // - 세션 자동 복원
  kAuth = await KAuth.init(
    kakao: KakaoConfig(appKey: 'YOUR_APP_KEY'),
  );

  // 자동 로그인 확인
  if (kAuth.isSignedIn) {
    print('자동 로그인 성공: ${kAuth.name}');
  }

  runApp(MyApp());
}
```

### 기존 방식 (직접 Storage 설정)

```dart
final kAuth = KAuth(
  config: KAuthConfig(
    kakao: KakaoConfig(appKey: 'YOUR_APP_KEY'),
  ),
  storage: SecureSessionStorage(),  // 기본 제공
);

await kAuth.initialize(autoRestore: true);
```

---

## 패턴 4: 화면 전환

**사용 케이스**: 로그인 상태에 따라 자동으로 화면 전환

### 권장: KAuthBuilder 사용

```dart
import 'package:flutter/material.dart';
import 'package:k_auth/k_auth.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: KAuthBuilder(
        stream: kAuth.authStateChanges,
        signedIn: (user) => HomeScreen(user: user),
        signedOut: () => LoginScreen(),
        loading: () => SplashScreen(),  // 선택
      ),
    );
  }
}
```

### 기존 방식: StreamBuilder 직접 사용

```dart
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: StreamBuilder<KAuthUser?>(
        stream: kAuth.authStateChanges,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return SplashScreen();
          }
          if (snapshot.hasData && snapshot.data != null) {
            return HomeScreen(user: snapshot.data!);
          }
          return LoginScreen();
        },
      ),
    );
  }
}

class LoginScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            // 로그인하면 자동으로 HomeScreen으로 전환됨
            await kAuth.signIn(AuthProvider.kakao);
          },
          child: Text('카카오 로그인'),
        ),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  final KAuthUser user;

  const HomeScreen({required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('환영합니다, ${user.displayName}!'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              // 로그아웃하면 자동으로 LoginScreen으로 전환됨
              await kAuth.signOut();
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (user.avatar != null)
              CircleAvatar(
                radius: 50,
                backgroundImage: NetworkImage(user.avatar!),
              ),
            SizedBox(height: 16),
            Text(user.displayName, style: TextStyle(fontSize: 24)),
            if (user.email != null) Text(user.email!),
          ],
        ),
      ),
    );
  }
}
```

---

## 패턴 5: 에러 처리

### 방법 1: fold (함수형 스타일)

```dart
final result = await kAuth.signIn(AuthProvider.kakao);

result.fold(
  onSuccess: (user) {
    print('로그인 성공: ${user.displayName}');
    navigateToHome();
  },
  onFailure: (failure) {
    print('로그인 실패: ${failure.message}');
    showErrorDialog(failure.displayMessage);
  },
);
```

### 방법 2: when (성공/취소/실패 구분)

```dart
final result = await kAuth.signIn(AuthProvider.kakao);

result.when(
  success: (user) {
    print('로그인 성공: ${user.displayName}');
    navigateToHome();
  },
  cancelled: () {
    print('사용자가 로그인을 취소했습니다');
    showSnackBar('로그인이 취소되었습니다');
  },
  failure: (failure) {
    print('로그인 실패 [${failure.code}]: ${failure.message}');
    showErrorDialog(failure.displayMessage);
  },
);
```

### 방법 3: if-else (간단한 방식)

```dart
final result = await kAuth.signIn(AuthProvider.kakao);

if (result.success) {
  print('로그인 성공: ${result.user?.displayName}');
  navigateToHome();
} else {
  print('로그인 실패: ${result.errorMessage}');
  showErrorDialog(result.errorMessage ?? '알 수 없는 오류');
}
```

### 방법 4: 체이닝 (간결한 방식)

```dart
final result = await kAuth.signIn(AuthProvider.kakao);

result
  .onSuccess((user) {
    print('로그인 성공: ${user.displayName}');
    saveUserToDatabase(user);
  })
  .onFailure((failure) {
    print('로그인 실패 [${failure.code}]: ${failure.message}');
    logError(failure.code, failure.message);
  });
```

### 방법 5: KAuthFailure 편의 메서드

```dart
final result = await kAuth.signIn(AuthProvider.kakao);

result.fold(
  onSuccess: (user) => navigateToHome(),
  onFailure: (failure) {
    // 취소는 에러가 아니므로 무시
    if (failure.isCancelled) return;

    // 네트워크 에러면 재시도 안내
    if (failure.isNetworkError) {
      showRetryDialog();
      return;
    }

    // 그 외 에러
    showError(failure.displayMessage);
  },
);
```

---

## 패턴 6: 버튼 위젯 사용

### 개별 버튼

```dart
import 'package:flutter/material.dart';
import 'package:k_auth/k_auth.dart';

class LoginScreen extends StatelessWidget {
  Future<void> _handleLogin(AuthProvider provider) async {
    final result = await kAuth.signIn(provider);
    if (result.success) {
      print('로그인 성공!');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 카카오 로그인 버튼 (공식 디자인)
        KakaoLoginButton(
          onPressed: () => _handleLogin(AuthProvider.kakao),
        ),
        SizedBox(height: 12),

        // 네이버 로그인 버튼
        NaverLoginButton(
          onPressed: () => _handleLogin(AuthProvider.naver),
        ),
        SizedBox(height: 12),

        // 구글 로그인 버튼
        GoogleLoginButton(
          onPressed: () => _handleLogin(AuthProvider.google),
        ),
        SizedBox(height: 12),

        // 애플 로그인 버튼
        AppleLoginButton(
          onPressed: () => _handleLogin(AuthProvider.apple),
        ),
      ],
    );
  }
}
```

### 버튼 그룹 (추천)

```dart
class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  AuthProvider? _loadingProvider;

  Future<void> _handleLogin(AuthProvider provider) async {
    setState(() => _loadingProvider = provider);

    final result = await kAuth.signIn(provider);

    setState(() => _loadingProvider = null);

    result.when(
      success: (user) => print('로그인 성공!'),
      cancelled: () => print('취소됨'),
      failure: (failure) => print('실패: ${failure.message}'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LoginButtonGroup(
      providers: [
        AuthProvider.kakao,
        AuthProvider.naver,
        AuthProvider.google,
        AuthProvider.apple,
      ],
      onPressed: _handleLogin,
      buttonSize: ButtonSize.large,
      spacing: 12,
      // 로딩 상태 표시
      loadingStates: {
        for (final p in AuthProvider.values) p: _loadingProvider == p,
      },
      // 로딩 중일 때 다른 버튼 비활성화
      disabledStates: {
        for (final p in AuthProvider.values)
          p: _loadingProvider != null && _loadingProvider != p,
      },
    );
  }
}
```

---

## 안티패턴

### ❌ 잘못된 방법

```dart
// 1. initialize() 전에 signIn() 호출
final kAuth = KAuth(config: config);
await kAuth.signIn(AuthProvider.kakao); // ❌ 에러 발생!

// 2. 설정하지 않은 Provider 사용
final kAuth = KAuth(
  config: KAuthConfig(
    kakao: KakaoConfig(appKey: 'KEY'),
    // naver는 설정 안함
  ),
);
await kAuth.initialize();
await kAuth.signIn(AuthProvider.naver); // ❌ 에러 발생!

// 3. null 체크 없이 user 접근
final result = await kAuth.signIn(AuthProvider.kakao);
print(result.user.displayName); // ❌ user가 null일 수 있음!

// 4. Apple 토큰 갱신 시도
await kAuth.refreshToken(AuthProvider.apple); // ❌ Apple은 토큰 갱신 미지원!

// 5. 에러 처리 없이 사용
await kAuth.signIn(AuthProvider.kakao); // ❌ 에러를 무시함!
```

### ✅ 올바른 방법

```dart
// 1. 반드시 initialize() 먼저 호출
final kAuth = KAuth(config: config);
await kAuth.initialize();
await kAuth.signIn(AuthProvider.kakao); // ✅

// 2. 설정된 Provider만 사용
if (kAuth.isConfigured(AuthProvider.naver)) {
  await kAuth.signIn(AuthProvider.naver); // ✅
}

// 3. null 체크 후 접근
final result = await kAuth.signIn(AuthProvider.kakao);
if (result.success && result.user != null) {
  print(result.user!.displayName); // ✅
}

// 4. 토큰 갱신 가능 여부 확인
if (kAuth.currentProvider?.supportsTokenRefresh ?? false) {
  await kAuth.refreshToken(); // ✅
}

// 5. 항상 에러 처리
final result = await kAuth.signIn(AuthProvider.kakao);
result.fold(
  onSuccess: (user) => print('성공'),
  onFailure: (failure) => print('실패: ${failure.message}'), // ✅
);
```

---

## 주요 메서드 체크리스트

### 초기화

```dart
await kAuth.initialize();                    // 기본 초기화
await kAuth.initialize(autoRestore: true);   // 세션 복원 포함
```

### 로그인

```dart
await kAuth.signIn(AuthProvider.kakao);   // 카카오
await kAuth.signIn(AuthProvider.naver);   // 네이버
await kAuth.signIn(AuthProvider.google);  // 구글
await kAuth.signIn(AuthProvider.apple);   // 애플
```

### 로그아웃

```dart
await kAuth.signOut();                       // 현재 Provider로 로그아웃
await kAuth.signOut(AuthProvider.kakao);     // 특정 Provider로 로그아웃
await kAuth.signOutAll();                    // 모든 Provider 로그아웃
```

### 토큰 갱신

```dart
await kAuth.refreshToken();                  // 현재 Provider로 갱신
await kAuth.refreshToken(AuthProvider.kakao); // 특정 Provider로 갱신
```

### 연결 해제 (회원 탈퇴)

```dart
await kAuth.unlink(AuthProvider.kakao);      // 카카오 연결 해제
await kAuth.unlink(AuthProvider.naver);      // 네이버 연결 해제
// Apple은 클라이언트에서 연결 해제 불가
```

### 상태 확인

```dart
kAuth.isSignedIn                  // 로그인 여부
kAuth.currentUser                 // 현재 사용자
kAuth.currentProvider             // 현재 Provider
kAuth.serverToken                 // 백엔드 JWT 토큰
kAuth.configuredProviders         // 설정된 Provider 목록
kAuth.isConfigured(provider)      // 특정 Provider 설정 여부
```

---

## 빠른 참고

### Provider별 특징

| Provider | 연결해제 | 토큰갱신 | 비고 |
|----------|:-------:|:-------:|------|
| kakao    | O | O | Native App Key 필요 |
| naver    | O | O | scope 미지원 |
| google   | O | O | iOS는 iosClientId 필요 |
| apple    | X | X | iOS 13+/macOS만 |

### KAuth 편의 Getter (짧고 간결)

```dart
kAuth.userId      // currentUser?.id
kAuth.name        // currentUser?.displayName
kAuth.email       // currentUser?.email
kAuth.avatar      // currentUser?.avatar
```

### KAuthUser 필드

```dart
user.id           // Provider 고유 ID (항상 존재)
user.email        // 이메일 (nullable)
user.name         // 이름 (nullable)
user.avatar       // 프로필 이미지 URL (nullable)
user.phone        // 전화번호 (nullable)
user.gender       // 성별 (nullable)
user.birthday     // 생일 (nullable)
user.birthyear    // 출생연도 (nullable)
user.age          // 나이 (nullable)
user.displayName  // 표시용 이름 (name ?? email 앞부분)
user.provider     // Provider 이름 (kakao, naver, google, apple)
```

---

## 마무리

더 많은 예제와 자세한 내용은 다음을 참고하세요:

- [README.md](README.md) - 전체 가이드
- [example/lib/main.dart](example/lib/main.dart) - 완전한 예제 앱
- [API 문서](https://pub.dev/documentation/k_auth/latest/) - API 레퍼런스
