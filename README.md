<p align="center">
  <h1 align="center">K-Auth</h1>
  <p align="center">
    <strong>한국 앱을 위한 소셜 로그인 SDK</strong>
  </p>
  <p align="center">
카카오, 네이버, 구글, 애플 로그인을 통합 API로 제공합니다.
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
  <a href="#요구사항">요구사항</a> •
  <a href="#설치">설치</a> •
  <a href="#빠른-시작">빠른 시작</a> •
  <a href="#provider-설정">Provider 설정</a> •
  <a href="docs/SETUP.md">플랫폼 설정</a> •
  <a href="docs/TROUBLESHOOTING.md">트러블슈팅</a>
</p>

<p align="center">
  <a href="https://pub.dev/documentation/k_auth/latest/">📚 API 문서</a>
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
| **자동 로그인**   | SecureStorage 기본 내장      |       직접 구현 필요        |

### Provider별 지원 기능

| Provider | 연결해제 | 토큰갱신 | 비고                |
| :------: | :------: | :------: | ------------------- |
|  Kakao   |    ✅    |    ✅    | Native App Key 필요 |
|  Naver   |    ✅    |    ✅    | scope 미지원        |
|  Google  |    ✅    |    ✅    | iOS는 clientId 필요 |
|  Apple   |    ❌    |    ❌    | iOS 13+/macOS만     |

---

## 요구사항

| 환경 | 최소 버전 |
|------|----------|
| Flutter | 3.22.0 |
| Dart | 3.4.0 |
| iOS | 13.0 |
| Android | API 21 (5.0) |

---

## 설치

```bash
flutter pub add k_auth
```

### 설정 진단

```bash
dart run k_auth
```

현재 프로젝트의 설정 상태를 확인하고, 누락된 설정이 있으면 해결 방법을 안내합니다.

---

## 빠른 시작

### TL;DR (복사해서 바로 사용)

```dart
import 'package:flutter/material.dart';
import 'package:k_auth/k_auth.dart';

late final KAuth kAuth;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  kAuth = await KAuth.init(kakao: KakaoConfig(appKey: 'YOUR_APP_KEY'));

  if (kAuth.isSignedIn) print('자동 로그인됨: ${kAuth.name}');

  runApp(MyApp());
}
```

### 1. 초기화

```dart
import 'package:k_auth/k_auth.dart';

// 권장: KAuth.init() - 초기화 + SecureStorage + 자동 로그인
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
```

### 2. 로그인

```dart
final result = await kAuth.signIn(AuthProvider.kakao);

// 방법 1: fold (성공/실패)
result.fold(
  onSuccess: (user) => print('환영합니다, ${user.displayName}!'),
  onFailure: (failure) => print('실패: ${failure.message}'),
);

// 방법 2: when (성공/취소/실패)
result.when(
  success: (user) => navigateToHome(user),
  cancelled: () => showToast('로그인이 취소되었습니다'),
  failure: (failure) => showError(failure.displayMessage),
);

// 방법 3: KAuthFailure 활용
result.onFailure((failure) {
  if (failure.shouldIgnore) return;     // 취소 등 무시
  if (failure.canRetry) showRetryButton(); // 네트워크 오류 등 재시도 가능
  else showError(failure.displayMessage);
});
```

### 3. 화면 전환 (KAuthBuilder)

```dart
KAuthBuilder(
  stream: kAuth.authStateChanges,
  signedIn: (user) => HomeScreen(user: user),
  signedOut: () => LoginScreen(),
  loading: () => SplashScreen(),  // 선택
)
```

### 4. UI 버튼

```dart
// 개별 버튼
KakaoLoginButton(onPressed: () => kAuth.signIn(AuthProvider.kakao))
NaverLoginButton(onPressed: () => kAuth.signIn(AuthProvider.naver))
GoogleLoginButton(onPressed: () => kAuth.signIn(AuthProvider.google))
AppleLoginButton(onPressed: () => kAuth.signIn(AuthProvider.apple))

// 버튼 그룹 (로딩 상태 자동 관리)
LoginButtonGroup(
  providers: kAuth.configuredProviders,
  loading: _loadingProvider,  // 로딩 중인 버튼
  onPressed: (provider) async {
    setState(() => _loadingProvider = provider);
    await kAuth.signIn(provider);
    setState(() => _loadingProvider = null);
  },
)

// 아이콘만 있는 버튼 (가로 배치용)
Row(children: [
  KakaoLoginButton.icon(onPressed: ...),
  NaverLoginButton.icon(onPressed: ...),
  GoogleLoginButton.icon(onPressed: ...),
  AppleLoginButton.icon(onPressed: ...),
])
```

---

## Provider 설정

각 Provider를 사용하려면 해당 개발자 콘솔에서 앱을 등록해야 합니다.

### 카카오 (Kakao)

1. [Kakao Developers](https://developers.kakao.com/)에서 애플리케이션 등록
2. **앱 키** > **네이티브 앱 키** 복사
3. **플랫폼** > Android/iOS 플랫폼 등록
4. **카카오 로그인** > 활성화 설정 ON

```dart
KakaoConfig(
  appKey: 'YOUR_NATIVE_APP_KEY',
  collect: KakaoCollectOptions(email: true, profile: true),
)
```

### 네이버 (Naver)

1. [네이버 개발자 센터](https://developers.naver.com/)에서 애플리케이션 등록
2. **사용 API**: 네아로 선택
3. **Client ID**와 **Client Secret** 복사

```dart
NaverConfig(
  clientId: 'YOUR_CLIENT_ID',
  clientSecret: 'YOUR_CLIENT_SECRET',
  appName: 'Your App Name',
)
```

> **참고**: 네이버는 코드에서 scope 설정을 지원하지 않습니다. 개발자 센터에서 수집 항목을 설정하세요.

### 구글 (Google)

1. [Google Cloud Console](https://console.cloud.google.com/)에서 프로젝트 생성
2. **OAuth 클라이언트 ID** 생성 (Android/iOS 각각)
3. **OAuth 동의 화면** 설정

```dart
GoogleConfig(
  iosClientId: 'YOUR_IOS_CLIENT_ID',  // iOS 필수
  serverClientId: 'YOUR_SERVER_CLIENT_ID',  // 백엔드 연동 시
)
```

### 애플 (Apple)

1. [Apple Developer](https://developer.apple.com/)에서 App ID 생성
2. **Sign in with Apple** Capability 활성화
3. Xcode에서 Capability 추가

```dart
AppleConfig()  // 별도 설정 불필요
```

> **플랫폼별 상세 설정**: [docs/SETUP.md](docs/SETUP.md)

---

## 고급 사용법

### 자동 로그인

`KAuth.init()`을 사용하면 자동으로 SecureStorage가 설정되어 앱 재시작 시 세션이 복원됩니다.

```dart
final kAuth = await KAuth.init(
  kakao: KakaoConfig(appKey: 'YOUR_APP_KEY'),
  autoRestore: true,   // 기본값: true
  autoRefresh: true,   // 토큰 자동 갱신 (기본값: true)
);

if (kAuth.isSignedIn) {
  print('자동 로그인 성공: ${kAuth.name}');
}
```

커스텀 저장소가 필요한 경우:

```dart
final kAuth = KAuth(
  config: KAuthConfig(kakao: KakaoConfig(appKey: 'YOUR_APP_KEY')),
  storage: MyCustomStorage(),  // KAuthSessionStorage 구현
);
await kAuth.initialize(autoRestore: true);
```

### 백엔드 연동

```dart
final kAuth = await KAuth.init(
  kakao: KakaoConfig(appKey: 'YOUR_APP_KEY'),
  onSignIn: (provider, tokens, user) async {
    final jwt = await myApi.socialLogin(
      provider: provider.name,
      accessToken: tokens.accessToken,
    );
    return jwt;  // serverToken에 저장됨
  },
  onSignOut: (provider) async {
    await myApi.logout();
  },
);

// 로그인 후
print(kAuth.serverToken);  // 백엔드에서 받은 JWT
```

### 토큰 갱신

```dart
if (kAuth.isExpiringSoon()) {
  final result = await kAuth.refreshToken();
  result.fold(
    onSuccess: (user) => print('토큰 갱신 성공'),
    onFailure: (failure) => print('토큰 갱신 실패'),
  );
}
```

### 편의 Getter

```dart
kAuth.userId      // currentUser?.id
kAuth.name        // currentUser?.displayName
kAuth.email       // currentUser?.email
kAuth.avatar      // currentUser?.avatar
kAuth.isSignedIn  // 로그인 여부
```

---

## API 레퍼런스

### KAuth 메서드

| 메서드 | 설명 |
|--------|------|
| `KAuth.init(...)` | 초기화 + SecureStorage + 자동 로그인 (권장) |
| `initialize()` | SDK 초기화 (기존 방식) |
| `signIn(provider)` | 소셜 로그인 |
| `signOut()` | 로그아웃 |
| `refreshToken()` | 토큰 갱신 (Apple 미지원) |
| `unlink(provider)` | 연결 해제 (회원 탈퇴) |

### AuthResult 패턴

```dart
// fold: 성공/실패 분기
result.fold(
  onSuccess: (user) => ...,
  onFailure: (failure) => ...,
);

// when: 성공/취소/실패 분기
result.when(
  success: (user) => ...,
  cancelled: () => ...,
  failure: (failure) => ...,
);

// 체이닝
result
  .onSuccess((user) => ...)
  .onFailure((failure) => ...);

// 사용자 정보 변환
final myUser = result.mapUser((user) => MyUser.from(user));
```

### KAuthUser 속성

| 속성 | 타입 | 설명 |
|------|------|------|
| `id` | `String` | Provider 고유 ID |
| `provider` | `AuthProvider` | 로그인 Provider |
| `email` | `String?` | 이메일 |
| `name` | `String?` | 이름 |
| `avatar` | `String?` | 프로필 이미지 URL |
| `displayName` | `String` | 표시용 이름 |

> **전체 API 문서**: [pub.dev/documentation/k_auth](https://pub.dev/documentation/k_auth/latest/)

---

## 버전 호환성

| k_auth | kakao_flutter_sdk | flutter_naver_login | google_sign_in | sign_in_with_apple |
|--------|-------------------|---------------------|----------------|--------------------|
| 0.5.x  | 1.10.x            | 2.1.x               | 7.2.x          | 7.0.x              |

> **업그레이드 가이드**: [CHANGELOG.md](CHANGELOG.md)

---

## 보안

### 앱 키 관리

앱 키는 절대 Git에 커밋하지 마세요. 다음 방법 중 하나를 사용하세요:

**1. 환경 변수 (권장)**

```dart
KakaoConfig(appKey: String.fromEnvironment('KAKAO_APP_KEY'))
```

```bash
flutter run --dart-define=KAKAO_APP_KEY=your_key
```

**2. .env 파일 + flutter_dotenv**

```dart
KakaoConfig(appKey: dotenv.env['KAKAO_APP_KEY']!)
```

**3. 빌드 설정 분리**

`lib/config/dev.dart`, `lib/config/prod.dart` 등으로 분리

### 토큰 저장

- K-Auth는 `flutter_secure_storage`를 사용하여 토큰을 암호화 저장합니다
- iOS: Keychain
- Android: EncryptedSharedPreferences

---

## 테스트

`MockKAuth`를 사용하면 실제 SDK 없이 테스트할 수 있습니다.

```dart
final mockKAuth = MockKAuth.signedIn(
  user: KAuthUser(id: 'test_123', provider: AuthProvider.kakao, name: 'Test'),
);

expect(mockKAuth.isSignedIn, true);
expect(mockKAuth.name, 'Test');
```

```dart
// 실패 시뮬레이션
mockKAuth.setCancelled();      // 취소
mockKAuth.setNetworkError();   // 네트워크 오류
```

> **자세한 예제**: [example/](example/) 폴더 참고

---

## 예제

📂 [example/](example/) 폴더에서 전체 예제 확인

```bash
cd example && flutter run
```

### Widgetbook (버튼 UI 프리뷰)

```bash
flutter run -t widgetbook/main.dart -d chrome
```

---

## 문서

| 문서 | 설명 |
|------|------|
| [PATTERNS.md](PATTERNS.md) | AI 코드 생성용 패턴 가이드 |
| [docs/SETUP.md](docs/SETUP.md) | 플랫폼별 상세 설정 |
| [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) | 문제 해결 가이드 |
| [CHANGELOG.md](CHANGELOG.md) | 버전별 변경사항 |
| [CONTRIBUTING.md](CONTRIBUTING.md) | 기여 가이드 |

---

## Contributing

이슈와 PR을 환영합니다!

```bash
git clone https://github.com/k-auth/flutter.git
cd flutter
flutter pub get
flutter test
```

자세한 내용은 [CONTRIBUTING.md](CONTRIBUTING.md)를 참고해주세요.

## License

MIT License - [LICENSE](LICENSE) 파일 참고

---

<p align="center">
  Made with ❤️ for Korean developers
</p>
