<p align="center">
  <h1 align="center">K-Auth</h1>
  <p align="center">
    <strong>한국 앱을 위한 소셜 로그인 SDK</strong>
  </p>
  <p align="center">
    카카오, 네이버, 구글, 애플 로그인을 하나의 통합 API로
  </p>
</p>

<p align="center">
  <a href="https://pub.dev/packages/k_auth"><img src="https://img.shields.io/pub/v/k_auth.svg" alt="pub package"></a>
  <a href="https://pub.dev/packages/k_auth/score"><img src="https://img.shields.io/pub/points/k_auth" alt="pub points"></a>
  <a href="https://opensource.org/licenses/MIT"><img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="License: MIT"></a>
</p>

<p align="center">
  <a href="#설치">설치</a> •
  <a href="#빠른-시작">빠른 시작</a> •
  <a href="#features">Features</a> •
  <a href="#api">API</a> •
  <a href="#플랫폼-설정">플랫폼 설정</a>
</p>

---

## Features

| | K-Auth | 기존 방식 |
|---|:---:|:---:|
| **통합 API** | `signIn(provider)` 하나로 끝 | Provider마다 다른 메서드 |
| **표준화된 응답** | `KAuthUser`로 통일 | Provider마다 다른 응답 형식 |
| **한글 에러** | 한글 메시지 + 해결 힌트 | 영어 에러 메시지 |
| **함수형 패턴** | `fold`, `when` 지원 | if-else 분기 처리 |
| **공식 UI** | 디자인 가이드라인 준수 버튼 | 직접 구현 필요 |

## 설치

```bash
flutter pub add k_auth
```

## 빠른 시작

### 1. 초기화

```dart
import 'package:k_auth/k_auth.dart';

final kAuth = KAuth(
  config: KAuthConfig(
    kakao: KakaoConfig(appKey: 'YOUR_APP_KEY'),
    naver: NaverConfig(
      clientId: 'YOUR_CLIENT_ID',
      clientSecret: 'YOUR_CLIENT_SECRET',
      appName: 'Your App',
    ),
    google: GoogleConfig(),
    apple: AppleConfig(),
  ),
);

await kAuth.initialize();
```

### 2. 로그인

```dart
final result = await kAuth.signIn(AuthProvider.kakao);

result.fold(
  onSuccess: (user) => print('환영합니다, ${user.displayName}!'),
  onFailure: (error) => print('로그인 실패: $error'),
);
```

### 3. UI 버튼

```dart
// 개별 버튼
KakaoLoginButton(onPressed: () => kAuth.signIn(AuthProvider.kakao))

// 버튼 그룹
LoginButtonGroup(
  providers: [AuthProvider.kakao, AuthProvider.naver, AuthProvider.google],
  onPressed: (provider) => kAuth.signIn(provider),
)
```

## API

### 함수형 결과 처리

```dart
// fold: 성공/실패 분기
result.fold(
  onSuccess: (user) => navigateToHome(user),
  onFailure: (error) => showError(error),
);

// when: 성공/취소/실패 세분화
result.when(
  success: (user) => navigateToHome(user),
  cancelled: () => showToast('취소됨'),
  failure: (code, msg) => showError(msg),
);

// 체이닝
result
  .onSuccess((user) => saveUser(user))
  .onFailure((code, msg) => logError(msg));
```

### 자동 로그인

```dart
final kAuth = KAuth(
  config: config,
  storage: SecureSessionStorage(), // 직접 구현
);

await kAuth.initialize(autoRestore: true);

if (kAuth.isSignedIn) {
  print('자동 로그인: ${kAuth.currentUser?.displayName}');
}
```

### 백엔드 연동

```dart
final kAuth = KAuth(
  config: config,
  onSignIn: (provider, tokens, user) async {
    final jwt = await myApi.socialLogin(
      provider: provider.name,
      accessToken: tokens.accessToken,
    );
    return jwt; // serverToken에 저장됨
  },
);
```

### 토큰 갱신

```dart
final result = await kAuth.refreshToken();
```

> Apple은 토큰 갱신을 지원하지 않습니다.

## Provider별 지원

| Provider | 연결해제 | 토큰갱신 | 비고 |
|:--------:|:-------:|:-------:|------|
| Kakao | ✅ | ✅ | Native App Key 필요 |
| Naver | ✅ | ✅ | scope 미지원 |
| Google | ✅ | ✅ | iOS는 clientId 필요 |
| Apple | ❌ | ❌ | iOS 13+/macOS만 |

## KAuth 메서드

| 메서드 | 설명 |
|--------|------|
| `initialize()` | SDK 초기화 |
| `signIn(provider)` | 소셜 로그인 |
| `signOut()` | 로그아웃 |
| `refreshToken()` | 토큰 갱신 |
| `unlink(provider)` | 연결 해제 |

| 프로퍼티 | 설명 |
|----------|------|
| `currentUser` | 현재 사용자 |
| `currentProvider` | 현재 Provider |
| `isSignedIn` | 로그인 여부 |
| `authStateChanges` | 인증 상태 Stream |

## KAuthUser

| 프로퍼티 | 타입 | 설명 |
|---------|------|------|
| `id` | `String` | 고유 ID |
| `email` | `String?` | 이메일 |
| `name` | `String?` | 이름 |
| `image` | `String?` | 프로필 이미지 |
| `phone` | `String?` | 전화번호 |
| `gender` | `String?` | 성별 |
| `birthday` | `String?` | 생일 |
| `displayName` | `String` | 표시 이름 |

## 플랫폼 설정

<details>
<summary><b>iOS 설정</b></summary>

`ios/Runner/Info.plist`:

```xml
<!-- 카카오 -->
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>kakao{YOUR_APP_KEY}</string>
    </array>
  </dict>
</array>
<key>LSApplicationQueriesSchemes</key>
<array>
  <string>kakaokompassauth</string>
  <string>kakaolink</string>
  <string>kakaotalk</string>
</array>

<!-- 네이버 -->
<key>LSApplicationQueriesSchemes</key>
<array>
  <string>naversearchapp</string>
  <string>naversearchthirdlogin</string>
</array>

<!-- 애플: Xcode > Signing & Capabilities > Sign in with Apple -->
```

</details>

<details>
<summary><b>Android 설정</b></summary>

`android/app/src/main/AndroidManifest.xml`:

```xml
<!-- 카카오 -->
<activity
    android:name="com.kakao.sdk.flutter.AuthCodeCustomTabsActivity"
    android:exported="true">
    <intent-filter>
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />
        <data android:host="oauth"
              android:scheme="kakao{YOUR_APP_KEY}" />
    </intent-filter>
</activity>
```

네이버는 `MainActivity`가 `FlutterFragmentActivity`를 상속해야 합니다.

</details>

## 설정 진단

```dart
final result = await KAuthDiagnostic.run(kAuth.config);

if (result.hasErrors) {
  print(result.prettyPrint());
}
```

## 에러 처리

모든 에러는 한글 메시지와 해결 힌트를 포함합니다:

```dart
result.when(
  success: (user) => ...,
  cancelled: () => showToast('취소됨'),
  failure: (code, message) {
    // code: USER_CANCELLED, NETWORK_ERROR, PROVIDER_NOT_CONFIGURED 등
    showError(message);
  },
);
```

## Contributing

이슈와 PR을 환영합니다! [CONTRIBUTING.md](CONTRIBUTING.md)를 참고해주세요.

## License

MIT License - 자세한 내용은 [LICENSE](LICENSE) 파일을 참고하세요.

---

<p align="center">
  Made with ❤️ for Korean developers
</p>
