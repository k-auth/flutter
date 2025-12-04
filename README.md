# K-Auth Flutter

한국 앱을 위한 소셜 로그인 SDK. 카카오, 네이버, 구글, 애플을 하나의 API로 구현하세요.

[![pub package](https://img.shields.io/pub/v/k_auth.svg)](https://pub.dev/packages/k_auth)
[![pub points](https://img.shields.io/pub/points/k_auth)](https://pub.dev/packages/k_auth/score)
[![pub likes](https://img.shields.io/pub/likes/k_auth)](https://pub.dev/packages/k_auth)
[![pub popularity](https://img.shields.io/pub/popularity/k_auth)](https://pub.dev/packages/k_auth)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

> **Next.js 버전**: [k-auth/next](https://github.com/k-auth/next)

<p align="center">
  <img src="https://raw.githubusercontent.com/k-auth/flutter/main/.github/assets/demo.gif" width="300" alt="K-Auth Demo" />
</p>

## 왜 K-Auth인가요?

| 기존 방식 | K-Auth |
|----------|--------|
| Provider마다 다른 API | 통합 API로 모든 Provider 처리 |
| Provider마다 다른 응답 형식 | `KAuthUser`로 표준화된 사용자 정보 |
| 영어 에러 메시지 | 한글 에러 메시지 + 해결 힌트 |
| if-else 분기 처리 | `fold`, `when` 함수형 패턴 |
| 버튼 직접 구현 | 공식 디자인 가이드라인 준수 버튼 제공 |

## 설치

```yaml
dependencies:
  k_auth: ^0.2.0
```

```bash
flutter pub add k_auth
```

## 빠른 시작

### 1. 초기화

```dart
import 'package:k_auth/k_auth.dart';

void main() {
  final kAuth = KAuth(
    config: KAuthConfig(
      kakao: KakaoConfig(appKey: 'YOUR_KAKAO_APP_KEY'),
      naver: NaverConfig(
        clientId: 'YOUR_CLIENT_ID',
        clientSecret: 'YOUR_CLIENT_SECRET',
        appName: 'Your App',
      ),
      google: GoogleConfig(),
      apple: AppleConfig(),
    ),
  );

  kAuth.initialize();
  runApp(MyApp());
}
```

### 2. 로그인 (함수형 스타일 권장)

```dart
final result = await kAuth.signIn(AuthProvider.kakao);

// ✅ fold: 성공/실패 분기
result.fold(
  onSuccess: (user) => print('환영합니다, ${user.displayName}!'),
  onFailure: (error) => print('로그인 실패: $error'),
);

// ✅ when: 성공/취소/실패 세분화
result.when(
  success: (user) => navigateToHome(user),
  cancelled: () => showToast('로그인을 취소했습니다'),
  failure: (code, msg) => showError(msg),
);

// ✅ 체이닝
result
  .onSuccess((user) => saveUser(user))
  .onFailure((code, msg) => logError(msg));

// ✅ 값 추출
final name = result.mapUserOr((u) => u.displayName, 'Guest');
```

### 3. 인증 상태 감지

```dart
// Firebase Auth 스타일의 Stream
kAuth.authStateChanges.listen((user) {
  if (user != null) {
    print('로그인됨: ${user.displayName}');
  } else {
    print('로그아웃됨');
  }
});
```

### 4. 로그아웃

```dart
// 현재 로그인된 Provider로 자동 로그아웃
await kAuth.signOut();

// 또는 특정 Provider 지정
await kAuth.signOut(AuthProvider.kakao);
```

### 5. UI 버튼

```dart
// 개별 버튼
KakaoLoginButton(
  onPressed: () => kAuth.signInWithKakao(),
)

// 버튼 그룹
LoginButtonGroup(
  providers: kAuth.configuredProviders,
  onPressed: (provider) => kAuth.signIn(provider),
)
```

## 디버그 로깅

개발 중 디버깅을 위해 로그를 활성화할 수 있습니다:

```dart
// 개발 환경에서 로그 활성화
KAuthLogger.level = KAuthLogLevel.debug;

// 프로덕션에서는 비활성화 (기본값)
KAuthLogger.level = KAuthLogLevel.none;

// 커스텀 로거 (Firebase Crashlytics 등)
KAuthLogger.onLog = (event) {
  if (event.level == KAuthLogLevel.error) {
    FirebaseCrashlytics.instance.recordError(
      event.error,
      event.stackTrace,
      reason: event.message,
    );
  }
};
```

## Provider 설정

### 카카오

```dart
KakaoConfig(
  appKey: 'YOUR_KAKAO_NATIVE_APP_KEY',  // Native App Key (REST API Key 아님!)
  collect: KakaoCollectOptions(
    email: true,      // 이메일
    profile: true,    // 닉네임, 프로필 이미지
    phone: false,     // 전화번호 (개발자센터 활성화 필요)
    birthday: false,  // 생일
    gender: false,    // 성별
  ),
)
```

📖 [카카오 공식 문서](https://developers.kakao.com/docs/latest/ko/kakaologin/flutter)

### 네이버

```dart
NaverConfig(
  clientId: 'YOUR_CLIENT_ID',
  clientSecret: 'YOUR_CLIENT_SECRET',
  appName: 'Your App Name',
)
```

> ⚠️ 네이버는 scope 파라미터를 지원하지 않습니다.
> 수집 항목은 [네이버 개발자센터](https://developers.naver.com/apps)에서 직접 설정하세요.

### 구글

```dart
GoogleConfig(
  iosClientId: 'YOUR_IOS_CLIENT_ID',      // iOS 필수
  serverClientId: 'YOUR_SERVER_CLIENT_ID', // 백엔드 연동 시
  forceConsent: true,                      // refresh token 획득
)
```

📖 [Google Cloud Console](https://console.cloud.google.com/apis/credentials)

### 애플

```dart
AppleConfig(
  collect: AppleCollectOptions(
    email: true,
    fullName: true,  // 첫 로그인 시에만 제공
  ),
)
```

> ⚠️ iOS 13+, macOS에서만 지원됩니다.

## API 레퍼런스

### KAuthUser (표준화된 사용자 정보)

| 프로퍼티 | 타입 | 설명 |
|---------|------|------|
| `id` | `String` | Provider별 고유 ID |
| `name` | `String?` | 이름 |
| `email` | `String?` | 이메일 |
| `image` | `String?` | 프로필 이미지 URL |
| `phone` | `String?` | 전화번호 |
| `birthday` | `String?` | 생일 (MM-DD) |
| `birthyear` | `String?` | 출생연도 (YYYY) |
| `gender` | `String?` | 성별 (male/female) |
| `displayName` | `String?` | 표시할 이름 (헬퍼) |
| `age` | `int?` | 만 나이 (헬퍼) |

### AuthResult

| 메서드 | 설명 |
|--------|------|
| `fold(onSuccess, onFailure)` | 성공/실패 분기 처리 |
| `when(success, cancelled, failure)` | 성공/취소/실패 세분화 |
| `onSuccess(callback)` | 성공 시 콜백 (체이닝 지원) |
| `onFailure(callback)` | 실패 시 콜백 (체이닝 지원) |
| `mapUser(mapper)` | 사용자 정보 변환 |
| `mapUserOr(mapper, defaultValue)` | 변환 또는 기본값 |
| `isExpired` | 토큰 만료 여부 |
| `isExpiringSoon([threshold])` | 곧 만료되는지 확인 |

### KAuth

| 메서드 | 설명 |
|--------|------|
| `initialize()` | SDK 초기화 |
| `signIn(provider)` | 소셜 로그인 |
| `signOut([provider])` | 로그아웃 (생략 시 현재 Provider) |
| `signOutAll()` | 전체 로그아웃 |
| `unlink(provider)` | 연결 해제 (탈퇴) |
| `authStateChanges` | 인증 상태 Stream |
| `currentUser` | 현재 로그인된 사용자 |
| `isSignedIn` | 로그인 여부 |
| `dispose()` | 리소스 해제 |

## 에러 처리

모든 에러는 한글 메시지와 해결 힌트를 포함합니다:

```dart
result.when(
  success: (user) => ...,
  cancelled: () => showToast('로그인을 취소했습니다'),
  failure: (code, message) {
    switch (code) {
      case ErrorCodes.networkError:
        showRetryDialog();
        break;
      case ErrorCodes.kakaoPhoneNotEnabled:
        // 힌트: 카카오 개발자센터에서 전화번호 수집을 활성화하세요
        showSettingsGuide();
        break;
      default:
        showError(message);
    }
  },
);
```

### 주요 에러 코드

| 코드 | 설명 |
|------|------|
| `USER_CANCELLED` | 사용자가 로그인을 취소 |
| `NETWORK_ERROR` | 네트워크 오류 |
| `PROVIDER_NOT_CONFIGURED` | Provider 미설정 |
| `KAKAO_PHONE_NOT_ENABLED` | 카카오 전화번호 권한 미활성화 |
| `GOOGLE_MISSING_IOS_CLIENT_ID` | iOS Client ID 미설정 |
| `APPLE_NOT_SUPPORTED` | 애플 로그인 미지원 기기 |

## 설정 진단

네이티브 설정이 잘 되어있는지 확인할 수 있습니다:

```dart
// 진단 실행
final result = await KAuthDiagnostic.run(kAuth.config);

// 결과 확인
if (result.hasErrors) {
  print(result.prettyPrint());
  // ═══════════════════════════════════════
  //   K-Auth 진단 결과
  // ═══════════════════════════════════════
  // 플랫폼: ios
  //
  // 발견된 문제: 2개
  //   - 에러: 1개
  //   - 경고: 1개
  //
  // ❌ [카카오] URL Scheme이 Info.plist에 등록되지 않았습니다
  //    💡 해결: Info.plist에 kakao{APP_KEY} URL Scheme 추가
  //    📖 문서: https://developers.kakao.com/docs/...
}

// 개별 이슈 처리
for (final issue in result.errors) {
  print('${issue.provider}: ${issue.message}');
  if (issue.solution != null) {
    print('해결: ${issue.solution}');
  }
}
```

앱 개발 중 설정 문제로 로그인이 안 될 때 유용합니다!

## 플랫폼 설정

### iOS (`ios/Runner/Info.plist`)

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
</array>

<!-- 애플: Signing & Capabilities에서 "Sign in with Apple" 추가 -->
```

### Android (`android/app/src/main/AndroidManifest.xml`)

```xml
<!-- 카카오 -->
<activity android:name="com.kakao.sdk.auth.AuthCodeHandlerActivity"
    android:exported="true">
    <intent-filter>
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />
        <data android:host="oauth" android:scheme="kakao{YOUR_APP_KEY}" />
    </intent-filter>
</activity>
```

## 마이그레이션

### 0.1.x → 0.2.0

```dart
// Before
if (result.success) {
  print(result.user!.name);
} else {
  print(result.errorMessage);
}

// After (권장)
result.fold(
  onSuccess: (user) => print(user.name),
  onFailure: (error) => print(error),
);

// Before
await kAuth.signOut(AuthProvider.kakao);

// After (현재 Provider로 자동)
await kAuth.signOut();
```

## 라이선스

MIT License

## 관련 링크

- [GitHub](https://github.com/k-auth/flutter)
- [pub.dev](https://pub.dev/packages/k_auth)
- [이슈 등록](https://github.com/k-auth/flutter/issues)
- [Contributing](CONTRIBUTING.md)
