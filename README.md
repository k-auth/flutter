<p align="center">
  <h1 align="center">K-Auth</h1>
  <p align="center">
    <strong>한국 앱을 위한 소셜 로그인 SDK</strong>
  </p>
  <p align="center">
한국 앱을 위한 소셜 로그인 SDK (v0.5.2). 카카오, 네이버, 구글, 애플 로그인을 통합 API로 제공.
  </p>
</p>

<p align="center">
  <a href="https://pub.dev/packages/k_auth"><img src="https://img.shields.io/pub/v/k_auth.svg" alt="pub package"></a>
  <a href="https://pub.dev/packages/k_auth/score"><img src="https://img.shields.io/pub/points/k_auth" alt="pub points"></a>
  <a href="https://github.com/k-auth/flutter/actions/workflows/ci.yml"><img src="https://github.com/k-auth/flutter/actions/workflows/ci.yml/badge.svg" alt="CI"></a>
  <a href="https://codecov.io/gh/k-auth/flutter"><img src="https://codecov.io/gh/k-auth/flutter/branch/main/graph/badge.svg" alt="codecov"></a>
  <a href="https://opensource.org/licenses/MIT"><img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="License: MIT"></a>
</p>

<p align="center">
  <a href="#features">Features</a> •
  <a href="#설치">설치</a> •
  <a href="#빠른-시작">빠른 시작</a> •
  <a href="#provider-설정">Provider 설정</a> •
  <a href="#플랫폼-설정">플랫폼 설정</a> •
  <a href="#고급-사용법">고급 사용법</a> •
  <a href="#트러블슈팅">트러블슈팅</a>
</p>

---

## Features

|                   |            K-Auth            |          기존 방식          |
| ----------------- | :--------------------------: | :-------------------------: |
| **통합 API**      | `signIn(provider)` 하나로 끝 |  Provider마다 다른 메서드   |
| **표준화된 응답** |      `KAuthUser`로 통일      | Provider마다 다른 응답 형식 |
| **한글 에러**     |   한글 메시지 + 해결 힌트    |      영어 에러 메시지       |
| **함수형 패턴**   |     `fold`, `when` 지원      |      if-else 분기 처리      |
| **공식 UI**       | 디자인 가이드라인 준수 버튼  |       직접 구현 필요        |

### Provider별 지원 기능

| Provider | 연결해제 | 토큰갱신 | 비고                |
| :------: | :------: | :------: | ------------------- |
|  Kakao   |    ✅    |    ✅    | Native App Key 필요 |
|  Naver   |    ✅    |    ✅    | scope 미지원        |
|  Google  |    ✅    |    ✅    | iOS는 clientId 필요 |
|  Apple   |    ❌    |    ❌    | iOS 13+/macOS만     |

---

## 설치

```bash
flutter pub add k_auth
```

### CLI로 빠른 설정 (권장)

```bash
dart run k_auth
```

대화형으로 Provider를 선택하고 앱 키를 입력하면:
- `AndroidManifest.xml`, `Info.plist` 자동 수정
- `lib/k_auth_config.dart` 설정 파일 생성

```bash
🔐 K-Auth 설정 도우미

사용할 로그인 방식을 선택하세요 (쉼표로 구분):
  1. 카카오
  2. 네이버
  3. 구글
  4. 애플

선택 (예: 1,2,3): 1,3

📱 카카오 설정
  Native App Key: abc123...

✅ 설정 완료!
```

설정 진단:
```bash
dart run k_auth doctor
```

---

## 빠른 시작

### TL;DR (3줄 요약)

```dart
final kAuth = await KAuth.init(kakao: KakaoConfig(appKey: 'YOUR_APP_KEY'));
final result = await kAuth.signIn(AuthProvider.kakao);
if (result.success) print('환영합니다, ${kAuth.name}!');
```

### 1. 초기화

```dart
import 'package:k_auth/k_auth.dart';

// 권장: KAuth.init() - 한 줄로 초기화 + SecureStorage + 자동 로그인
final kAuth = await KAuth.init(
  kakao: KakaoConfig(appKey: 'YOUR_NATIVE_APP_KEY'),
  naver: NaverConfig(
    clientId: 'YOUR_CLIENT_ID',
    clientSecret: 'YOUR_CLIENT_SECRET',
    appName: 'Your App',
  ),
  google: GoogleConfig(),
  apple: AppleConfig(),
);

// 또는 기존 방식 (더 세밀한 제어)
final kAuth = KAuth(
  config: KAuthConfig(
    kakao: KakaoConfig(appKey: 'YOUR_NATIVE_APP_KEY'),
  ),
);

await kAuth.initialize();
```

### 2. 로그인

```dart
final result = await kAuth.signIn(AuthProvider.kakao);

result.fold(
  onSuccess: (user) => print('환영합니다, ${user.displayName}!'),
  onFailure: (failure) => print('로그인 실패: ${failure.message}'),
);
```

### 3. UI 버튼

```dart
// 개별 버튼
KakaoLoginButton(onPressed: () => kAuth.signIn(AuthProvider.kakao))
NaverLoginButton(onPressed: () => kAuth.signIn(AuthProvider.naver))
GoogleLoginButton(onPressed: () => kAuth.signIn(AuthProvider.google))
AppleLoginButton(onPressed: () => kAuth.signIn(AuthProvider.apple))

// 버튼 그룹
LoginButtonGroup(
  providers: [AuthProvider.kakao, AuthProvider.naver, AuthProvider.google],
  onPressed: (provider) => kAuth.signIn(provider),
)
```

---

## Provider 설정

각 Provider를 사용하려면 해당 개발자 콘솔에서 앱을 등록해야 합니다.

### 카카오 (Kakao)

1. [Kakao Developers](https://developers.kakao.com/)에서 애플리케이션 등록
2. **앱 키** > **네이티브 앱 키** 복사
3. **플랫폼** > Android/iOS 플랫폼 등록
   - Android: 패키지명, 키 해시 등록
   - iOS: 번들 ID 등록
4. **카카오 로그인** > 활성화 설정 ON
5. **동의항목** > 필요한 정보 설정

```dart
KakaoConfig(
  appKey: 'YOUR_NATIVE_APP_KEY',  // 네이티브 앱 키 (필수)
  collect: KakaoCollectOptions(   // 선택 (기본값: email, profile만 수집)
    email: true,
    profile: true,
    phone: false,      // 개발자센터에서 활성화 필요
    birthday: false,
    gender: false,
  ),
)
```

### 네이버 (Naver)

1. [네이버 개발자 센터](https://developers.naver.com/)에서 애플리케이션 등록
2. **사용 API**: 네아로 (네이버 로그인) 선택
3. **환경 추가**: Android/iOS 환경 추가
   - Android: 패키지명, 다운로드 URL
   - iOS: URL Scheme, 번들 ID
4. **Client ID**와 **Client Secret** 복사

```dart
NaverConfig(
  clientId: 'YOUR_CLIENT_ID',      // 필수
  clientSecret: 'YOUR_CLIENT_SECRET',  // 필수
  appName: 'Your App Name',        // 필수 (동의 화면에 표시)
)
```

### 구글 (Google)

1. [Google Cloud Console](https://console.cloud.google.com/)에서 프로젝트 생성
2. **API 및 서비스** > **사용자 인증 정보** > **OAuth 클라이언트 ID 만들기**
3. Android 클라이언트 ID 생성
   - 패키지명, SHA-1 인증서 지문 입력
4. iOS 클라이언트 ID 생성
   - 번들 ID 입력
5. **OAuth 동의 화면** 설정

```dart
GoogleConfig(
  iosClientId: 'YOUR_IOS_CLIENT_ID',  // iOS 필수
  serverClientId: 'YOUR_SERVER_CLIENT_ID',  // 백엔드 연동 시
  collect: GoogleCollectOptions(  // 선택 (기본값: openid, email, profile)
    openid: true,
    email: true,
    profile: true,
  ),
)
```

### 애플 (Apple)

1. [Apple Developer](https://developer.apple.com/)에서 App ID 생성
2. **Certificates, Identifiers & Profiles** > **Identifiers**
3. App ID에서 **Sign in with Apple** Capability 활성화
4. Xcode에서 **Signing & Capabilities** > **+ Capability** > **Sign in with Apple** 추가

```dart
AppleConfig()  // 별도 설정 불필요
```

---

## 플랫폼 설정

### iOS 설정

#### 1. Info.plist 설정

`ios/Runner/Info.plist`에 다음을 추가:

```xml
<!-- URL Schemes (카카오, 네이버, 구글) -->
<key>CFBundleURLTypes</key>
<array>
  <!-- 카카오 -->
  <dict>
    <key>CFBundleTypeRole</key>
    <string>Editor</string>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>kakao{YOUR_NATIVE_APP_KEY}</string>
    </array>
  </dict>
  <!-- 네이버 -->
  <dict>
    <key>CFBundleTypeRole</key>
    <string>Editor</string>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>{YOUR_NAVER_URL_SCHEME}</string>
    </array>
  </dict>
  <!-- 구글 (역방향 클라이언트 ID) -->
  <dict>
    <key>CFBundleTypeRole</key>
    <string>Editor</string>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>com.googleusercontent.apps.{YOUR_CLIENT_ID}</string>
    </array>
  </dict>
</array>

<!-- 카카오/네이버 앱 호출을 위한 설정 -->
<key>LSApplicationQueriesSchemes</key>
<array>
  <!-- 카카오 -->
  <string>kakaokompassauth</string>
  <string>kakaolink</string>
  <string>kakaotalk</string>
  <!-- 네이버 -->
  <string>naversearchapp</string>
  <string>naversearchthirdlogin</string>
</array>

<!-- 네이버 로그인 설정 -->
<key>NidConsumerKey</key>
<string>{YOUR_NAVER_CLIENT_ID}</string>
<key>NidConsumerSecret</key>
<string>{YOUR_NAVER_CLIENT_SECRET}</string>
<key>NidAppName</key>
<string>{YOUR_APP_NAME}</string>
```

#### 2. AppDelegate 설정 (네이버)

`ios/Runner/AppDelegate.swift`에서 네이버 URL 핸들링 추가:

```swift
import UIKit
import Flutter
import NidThirdPartyLogin  // 추가

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // 네이버 로그인 URL 핸들링 추가
  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey : Any] = [:]
  ) -> Bool {
    if NidOAuth.shared.handleURL(url) {
      return true
    }
    return super.application(app, open: url, options: options)
  }
}
```

#### 3. Apple Sign In 설정 (Xcode)

1. Xcode에서 프로젝트 열기
2. **Runner** 타겟 선택
3. **Signing & Capabilities** 탭
4. **+ Capability** 클릭
5. **Sign in with Apple** 추가

### Android 설정

#### 1. strings.xml 설정 (네이버)

`android/app/src/main/res/values/strings.xml` 파일 생성 또는 수정:

```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="client_id">{YOUR_NAVER_CLIENT_ID}</string>
    <string name="client_secret">{YOUR_NAVER_CLIENT_SECRET}</string>
    <string name="client_name">{YOUR_APP_NAME}</string>
</resources>
```

#### 2. AndroidManifest.xml 설정

`android/app/src/main/AndroidManifest.xml`의 `<application>` 태그 안에 추가:

```xml
<!-- 네이버 로그인 메타데이터 -->
<meta-data
    android:name="com.naver.sdk.clientId"
    android:value="@string/client_id" />
<meta-data
    android:name="com.naver.sdk.clientSecret"
    android:value="@string/client_secret" />
<meta-data
    android:name="com.naver.sdk.clientName"
    android:value="@string/client_name" />

<!-- 카카오 로그인 -->
<activity
    android:name="com.kakao.sdk.flutter.AuthCodeCustomTabsActivity"
    android:exported="true">
    <intent-filter>
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />
        <data android:host="oauth"
              android:scheme="kakao{YOUR_NATIVE_APP_KEY}" />
    </intent-filter>
</activity>
```

#### 3. MainActivity 수정 (네이버 필수)

`android/app/src/main/kotlin/.../MainActivity.kt`:

```kotlin
// 변경 전
import io.flutter.embedding.android.FlutterActivity

class MainActivity: FlutterActivity()

// 변경 후
import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity: FlutterFragmentActivity()
```

#### 4. 키 해시 등록 (카카오)

디버그/릴리즈 키 해시를 카카오 개발자 콘솔에 등록:

```bash
# 디버그 키 해시
keytool -exportcert -alias androiddebugkey -keystore ~/.android/debug.keystore -storepass android -keypass android | openssl sha1 -binary | openssl base64

# 릴리즈 키 해시
keytool -exportcert -alias {YOUR_ALIAS} -keystore {YOUR_KEYSTORE_PATH} | openssl sha1 -binary | openssl base64
```

---

## API 레퍼런스

### KAuth 클래스

#### 메서드

| 메서드                      | 설명                                          |
| --------------------------- | --------------------------------------------- |
| `initialize({autoRestore})` | SDK 초기화. `autoRestore: true`로 자동 로그인 |
| `signIn(provider)`          | 소셜 로그인 실행                              |
| `signOut()`                 | 현재 Provider에서 로그아웃                    |
| `refreshToken()`            | 토큰 갱신 (Apple 미지원)                      |
| `unlink(provider)`          | 연결 해제 (회원 탈퇴)                         |

#### 프로퍼티

| 프로퍼티           | 타입                 | 설명                  |
| ------------------ | -------------------- | --------------------- |
| `currentUser`      | `KAuthUser?`         | 현재 로그인된 사용자  |
| `currentProvider`  | `AuthProvider?`      | 현재 로그인 Provider  |
| `isSignedIn`       | `bool`               | 로그인 여부           |
| `serverToken`      | `String?`            | 백엔드에서 받은 토큰  |
| `authStateChanges` | `Stream<KAuthUser?>` | 인증 상태 변화 스트림 |

### AuthResult 클래스

#### 함수형 처리

```dart
// fold: 성공/실패 분기
result.fold(
  onSuccess: (user) => navigateToHome(user),
  onFailure: (failure) => showError(failure.message),
);

// when: 성공/취소/실패 세분화
result.when(
  success: (user) => navigateToHome(user),
  cancelled: () => showToast('로그인이 취소되었습니다'),
  failure: (failure) => showError(failure.message),
);

// 체이닝
result
  .onSuccess((user) => saveUser(user))
  .onFailure((failure) => logError(failure.code, failure.message));

// KAuthFailure 편의 메서드
result.fold(
  onSuccess: (user) => navigateToHome(user),
  onFailure: (failure) {
    if (failure.isCancelled) return;  // 취소는 무시
    showError(failure.displayMessage);
  },
);

// 사용자 정보 변환
final customUser = result.mapUser((user) => MyUser.fromKAuth(user));
final customUserOrNull = result.mapUserOr((user) => MyUser.fromKAuth(user), null);
```

### KAuthUser 클래스

| 프로퍼티      | 타입           | 설명                                          |
| ------------- | -------------- | --------------------------------------------- |
| `id`          | `String`       | Provider 고유 ID                              |
| `provider`    | `AuthProvider` | 로그인한 Provider (kakao, naver, google, apple) |
| `email`       | `String?`      | 이메일                                        |
| `name`        | `String?`      | 이름                                          |
| `avatar`      | `String?`      | 프로필 이미지 URL                             |
| `phone`       | `String?`      | 전화번호                                      |
| `gender`      | `String?`      | 성별                                          |
| `birthday`    | `String?`      | 생일                                          |
| `birthyear`   | `String?`      | 출생연도                                      |
| `displayName` | `String?`      | 표시용 이름 (name ?? email의 앞부분)          |

---

## 고급 사용법

### 자동 로그인 (세션 저장)

세션 저장소를 구현하여 앱 재시작 시 자동 로그인을 지원합니다.

```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureSessionStorage implements KAuthSessionStorage {
  final _storage = FlutterSecureStorage();

  @override
  Future<void> save(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  @override
  Future<String?> read(String key) async {
    return await _storage.read(key: key);
  }

  @override
  Future<void> delete(String key) async {
    await _storage.delete(key: key);
  }

  @override
  Future<void> clear() async {
    await _storage.deleteAll();
  }
}

// 사용
final kAuth = KAuth(
  config: config,
  storage: SecureSessionStorage(),
);

await kAuth.initialize(autoRestore: true);

if (kAuth.isSignedIn) {
  print('자동 로그인 성공: ${kAuth.currentUser?.displayName}');
}
```

### 백엔드 연동

소셜 로그인 후 백엔드 서버와 연동하여 JWT 토큰을 받아올 수 있습니다.

```dart
final kAuth = KAuth(
  config: config,
  onSignIn: (provider, tokens, user) async {
    // 백엔드 API 호출
    final response = await http.post(
      Uri.parse('https://api.myserver.com/auth/social'),
      body: {
        'provider': provider.name,
        'accessToken': tokens.accessToken,
        'idToken': tokens.idToken,
      },
    );

    final data = jsonDecode(response.body);
    return data['jwt'];  // serverToken에 저장됨
  },
  onSignOut: (provider) async {
    // 로그아웃 시 백엔드에 알림
    await http.post(Uri.parse('https://api.myserver.com/auth/logout'));
  },
);

// 로그인 후
await kAuth.signIn(AuthProvider.kakao);
print(kAuth.serverToken);  // 백엔드에서 받은 JWT
```

### 토큰 갱신

```dart
// 마지막 로그인 결과에서 토큰 만료 여부 확인
final lastResult = kAuth.lastResult;
if (lastResult?.isExpired == true) {
  final result = await kAuth.refreshToken();
  result.fold(
    onSuccess: (user) => print('토큰 갱신 성공'),
    onFailure: (failure) => print('토큰 갱신 실패: ${failure.message}'),
  );
}

// 토큰 만료 임박 확인 (기본 5분 전)
if (lastResult?.isExpiringSoon() == true) {
  await kAuth.refreshToken();
}

// 커스텀 임계값 (10분 전)
if (lastResult?.isExpiringSoon(Duration(minutes: 10)) == true) {
  await kAuth.refreshToken();
}
```

### 인증 상태 스트림

```dart
// 인증 상태 변화 감지
kAuth.authStateChanges.listen((user) {
  if (user != null) {
    print('로그인됨: ${user.displayName}');
  } else {
    print('로그아웃됨');
  }
});

// StreamBuilder와 함께 사용
StreamBuilder<KAuthUser?>(
  stream: kAuth.authStateChanges,
  builder: (context, snapshot) {
    if (snapshot.data != null) {
      return HomeScreen(user: snapshot.data!);
    }
    return LoginScreen();
  },
)
```

### 설정 진단

앱 설정이 올바른지 진단합니다. 개발 중 디버깅에 유용합니다.

```dart
final result = await KAuthDiagnostic.run(kAuth.config);

if (result.hasErrors) {
  print(result.prettyPrint());
  // 출력 예시:
  // ❌ [kakao] 네이티브 앱 키가 설정되지 않았습니다.
  // ⚠️ [google] iOS 클라이언트 ID가 없으면 iOS에서 로그인이 실패합니다.
  // ✅ [naver] 설정이 올바릅니다.
}

// 특정 Provider만 진단
final kakaoResult = await KAuthDiagnostic.checkKakao(kAuth.config.kakao!);
```

---

## 버튼 UI 프리뷰 (Widgetbook)

로그인 버튼 디자인을 **Storybook처럼** 미리 확인하고 싶으신가요?

```bash
flutter run -t widgetbook/main.dart -d chrome
```

Widgetbook으로 모든 버튼을 인터랙티브하게 확인:
- ✅ 실시간 Props 조정 (사이즈, 로딩, 비활성화, 텍스트)
- ✅ 다크/라이트 모드 토글
- ✅ 디바이스 프레임 프리뷰 (iPhone, iPad, etc.)
- ✅ 모든 Use Case 체계적 관리
- ✅ 4가지 Provider × 4가지 사이즈 × 다양한 상태

---

## 코드 패턴 가이드

AI 코드 생성 도구를 사용하시나요? [PATTERNS.md](PATTERNS.md) 문서에서 복사해서 바로 사용할 수 있는 코드 패턴들을 확인하세요.

- 모든 주요 사용 패턴
- 안티패턴과 베스트 프랙티스
- VSCode 스니펫 (`.vscode/k_auth.code-snippets`)
- 프로덕션 예제 (`example/lib/main.dart`)

---

## 테스트

`MockKAuth`를 사용하면 실제 SDK 없이 인증 로직을 테스트할 수 있습니다.

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:k_auth/k_auth.dart';

void main() {
  test('로그인 성공 테스트', () async {
    final mockKAuth = MockKAuth();
    mockKAuth.mockUser = KAuthUser(
      id: 'test_123',
      provider: AuthProvider.kakao,
      name: 'Test User',
    );

    final result = await mockKAuth.signIn(AuthProvider.kakao);

    expect(result.success, true);
    expect(mockKAuth.isSignedIn, true);
    expect(mockKAuth.name, 'Test User');
  });

  test('로그인 취소 테스트', () async {
    final mockKAuth = MockKAuth();
    mockKAuth.setCancelled();

    final result = await mockKAuth.signIn(AuthProvider.kakao);

    expect(result.success, false);
    expect(result.errorCode, 'USER_CANCELLED');
  });

  testWidgets('Widget 테스트', (tester) async {
    final mockKAuth = MockKAuth.signedIn(
      user: KAuthUser(id: 'user_123', provider: AuthProvider.kakao),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: KAuthBuilder(
          stream: mockKAuth.authStateChanges,
          signedIn: (user) => Text('Welcome ${user.displayName}'),
          signedOut: () => Text('Please login'),
        ),
      ),
    );

    expect(find.textContaining('Welcome'), findsOneWidget);
  });
}
```

**MockKAuth 헬퍼 메서드:**

| 메서드 | 설명 |
|--------|------|
| `MockKAuth.signedIn(user:)` | 이미 로그인된 상태로 생성 |
| `setSignedIn(user)` | 로그인 상태로 변경 |
| `setSignedOut()` | 로그아웃 상태로 변경 |
| `setCancelled()` | 다음 signIn이 취소로 실패 |
| `setNetworkError()` | 다음 signIn이 네트워크 에러로 실패 |
| `setFailure(code:, message:)` | 커스텀 에러로 실패 |
| `reset()` | 모든 상태 초기화 |

---

## 전체 예제

실제 앱에서 사용하는 전체 플로우 예제입니다.

### main.dart

```dart
import 'package:flutter/material.dart';
import 'package:k_auth/k_auth.dart';

// 전역 KAuth 인스턴스
late final KAuth kAuth;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  kAuth = KAuth(
    config: KAuthConfig(
      kakao: KakaoConfig(appKey: 'YOUR_NATIVE_APP_KEY'),
      naver: NaverConfig(
        clientId: 'YOUR_CLIENT_ID',
        clientSecret: 'YOUR_CLIENT_SECRET',
        appName: 'My App',
      ),
      google: GoogleConfig(
        iosClientId: 'YOUR_IOS_CLIENT_ID',
      ),
      apple: AppleConfig(),
    ),
    storage: SecureSessionStorage(),
    onSignIn: (provider, tokens, user) async {
      // 백엔드 연동
      final jwt = await MyApi.socialLogin(
        provider: provider.name,
        accessToken: tokens.accessToken,
      );
      return jwt;
    },
  );

  await kAuth.initialize(autoRestore: true);

  runApp(MyApp());
}

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
          if (snapshot.data != null) {
            return HomeScreen(user: snapshot.data!);
          }
          return LoginScreen();
        },
      ),
    );
  }
}
```

### login_screen.dart

```dart
import 'package:flutter/material.dart';
import 'package:k_auth/k_auth.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;

  Future<void> _signIn(AuthProvider provider) async {
    setState(() => _isLoading = true);

    final result = await kAuth.signIn(provider);

    setState(() => _isLoading = false);

    result.when(
      success: (user) {
        // authStateChanges가 자동으로 HomeScreen으로 전환
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('환영합니다, ${user.displayName}!')),
        );
      },
      cancelled: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('로그인이 취소되었습니다')),
        );
      },
      failure: (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(failure.displayMessage),
            backgroundColor: Colors.red,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '로그인',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              SizedBox(height: 48),

              if (_isLoading)
                CircularProgressIndicator()
              else
                LoginButtonGroup(
                  providers: [
                    AuthProvider.kakao,
                    AuthProvider.naver,
                    AuthProvider.google,
                    AuthProvider.apple,
                  ],
                  onPressed: _signIn,
                  spacing: 12,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
```

### home_screen.dart

```dart
import 'package:flutter/material.dart';
import 'package:k_auth/k_auth.dart';

class HomeScreen extends StatelessWidget {
  final KAuthUser user;

  const HomeScreen({required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('홈'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
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
            Text(
              user.displayName,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            if (user.email != null) ...[
              SizedBox(height: 8),
              Text(user.email!),
            ],
            SizedBox(height: 24),
            Text('Provider: ${kAuth.currentProvider?.name}'),
            SizedBox(height: 48),

            // 회원 탈퇴 버튼
            TextButton(
              onPressed: () => _showUnlinkDialog(context),
              child: Text('회원 탈퇴', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }

  void _showUnlinkDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('회원 탈퇴'),
        content: Text('정말 탈퇴하시겠습니까? 이 작업은 되돌릴 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await kAuth.unlink(kAuth.currentProvider!);
            },
            child: Text('탈퇴', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
```

---

## 트러블슈팅

### 카카오

<details>
<summary><b>KOE101: Invalid client</b></summary>

**원인**: 네이티브 앱 키가 잘못되었거나 플랫폼 설정이 없음

**해결**:

1. 카카오 개발자 콘솔에서 **네이티브 앱 키** 확인 (REST API 키 아님!)
2. 플랫폼 설정에서 패키지명/번들 ID 확인
3. Android: 키 해시 등록 확인

</details>

<details>
<summary><b>KOE006: 등록되지 않은 앱</b></summary>

**원인**: 카카오 로그인이 활성화되지 않음

**해결**:

1. 카카오 개발자 콘솔 > 카카오 로그인 > 활성화 설정 ON

</details>

<details>
<summary><b>iOS에서 카카오톡 앱이 열리지 않음</b></summary>

**원인**: LSApplicationQueriesSchemes 미설정

**해결**: Info.plist에 카카오 관련 scheme 추가

```xml
<key>LSApplicationQueriesSchemes</key>
<array>
  <string>kakaokompassauth</string>
  <string>kakaolink</string>
  <string>kakaotalk</string>
</array>
```

</details>

### 네이버

<details>
<summary><b>Android에서 로그인 창이 안 열림</b></summary>

**원인**: MainActivity가 FlutterFragmentActivity를 상속하지 않음

**해결**: MainActivity.kt 수정

```kotlin
import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity: FlutterFragmentActivity()
```

</details>

<details>
<summary><b>인증 실패 (invalid_request)</b></summary>

**원인**: Client ID 또는 Client Secret이 잘못됨

**해결**:

1. 네이버 개발자 센터에서 Client ID/Secret 재확인
2. 앱 이름이 개발자 센터 등록명과 일치하는지 확인

</details>

### 구글

<details>
<summary><b>iOS에서 DEVELOPER_ERROR</b></summary>

**원인**: iOS 클라이언트 ID가 설정되지 않음

**해결**:

```dart
GoogleConfig(
  iosClientId: 'YOUR_IOS_CLIENT_ID.apps.googleusercontent.com',
)
```

</details>

<details>
<summary><b>Android에서 DEVELOPER_ERROR (10)</b></summary>

**원인**: SHA-1 인증서 지문이 등록되지 않음

**해결**:

1. SHA-1 지문 확인: `./gradlew signingReport`
2. Google Cloud Console > 사용자 인증 정보 > Android 클라이언트 > SHA-1 인증서 지문 추가

</details>

<details>
<summary><b>accessToken이 null로 반환됨</b></summary>

**원인**: scopes가 설정되지 않음

**해결**:

```dart
GoogleConfig(
  collect: GoogleCollectOptions(
    email: true,
    profile: true,
  ),
)
```

</details>

### 애플

<details>
<summary><b>Sign in with Apple 버튼이 안 보임</b></summary>

**원인**: iOS 13 미만이거나 Capability가 추가되지 않음

**해결**:

1. Xcode > Signing & Capabilities > Sign in with Apple 추가
2. Apple Developer에서 App ID에 Sign in with Apple 활성화

</details>

<details>
<summary><b>이름/이메일이 null로 반환됨</b></summary>

**원인**: Apple은 최초 로그인 시에만 이름/이메일 제공

**해결**:

- 최초 로그인 시 받은 정보를 서버에 저장
- 테스트 시 Apple ID 설정 > 암호 및 보안 > Apple로 로그인하는 앱 에서 앱 연결 해제 후 재시도

</details>

### 공통

<details>
<summary><b>PlatformException: channel-error</b></summary>

**원인**: SDK가 초기화되지 않음

**해결**: `kAuth.initialize()` 호출 확인

```dart
await kAuth.initialize();  // 로그인 전 필수
```

</details>

<details>
<summary><b>설정 확인 방법</b></summary>

KAuthDiagnostic으로 설정 진단:

```dart
final result = await KAuthDiagnostic.run(kAuth.config);
print(result.prettyPrint());
```

</details>

---

## 에러 코드

| 코드                      | 설명                 |
| ------------------------- | -------------------- |
| `USER_CANCELLED`          | 사용자가 로그인 취소 |
| `NETWORK_ERROR`           | 네트워크 연결 오류   |
| `PROVIDER_NOT_CONFIGURED` | Provider 설정 누락   |
| `PLATFORM_NOT_SUPPORTED`  | 지원하지 않는 플랫폼 |
| `TOKEN_EXPIRED`           | 토큰 만료            |
| `INVALID_CREDENTIALS`     | 잘못된 인증 정보     |
| `KAKAO_*`                 | 카카오 관련 에러     |
| `NAVER_*`                 | 네이버 관련 에러     |
| `GOOGLE_*`                | 구글 관련 에러       |
| `APPLE_*`                 | 애플 관련 에러       |

모든 에러는 한글 메시지와 해결 힌트를 포함합니다.

---

## Contributing

이슈와 PR을 환영합니다! [CONTRIBUTING.md](CONTRIBUTING.md)를 참고해주세요.

## License

MIT License - [LICENSE](LICENSE) 파일 참고

---

<p align="center">
  Made with ❤️ for Korean developers
</p>
