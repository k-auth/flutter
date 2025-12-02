# K-Auth Flutter

한국형 소셜 로그인 Flutter 라이브러리. 카카오/네이버/구글/애플 OAuth를 Flutter에서 쉽게 구현할 수 있습니다.

[![pub package](https://img.shields.io/pub/v/k_auth.svg)](https://pub.dev/packages/k_auth)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

> Next.js 버전: [k-auth/next](https://github.com/k-auth/next)

## 특징

- **통합 API**: 모든 Provider를 동일한 인터페이스로 사용
- **표준화된 사용자 정보**: `KAuthUser` 모델로 Provider별 응답 통합
- **상세한 에러 처리**: 한글 에러 메시지, 힌트, 문서 링크 제공
- **UI 컴포넌트**: 공식 디자인 가이드라인 준수 버튼
- **타입 안전**: 완전한 Dart 타입 지원

## 설치

```yaml
dependencies:
  k_auth: ^0.1.0
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
      kakao: KakaoConfig(
        appKey: 'YOUR_KAKAO_APP_KEY',
        collect: KakaoCollectOptions(
          email: true,
          profile: true,
          phone: true,  // 전화번호 수집
        ),
      ),
      naver: NaverConfig(
        clientId: 'YOUR_NAVER_CLIENT_ID',
        clientSecret: 'YOUR_NAVER_CLIENT_SECRET',
        appName: 'Your App Name',
      ),
      google: GoogleConfig(
        iosClientId: 'YOUR_IOS_CLIENT_ID',
        forceConsent: true,  // refresh token 획득
      ),
      apple: AppleConfig(),
    ),
  );

  kAuth.initialize();
  runApp(MyApp());
}
```

### 2. 로그인 실행

```dart
// 통합 API 사용
final result = await kAuth.signIn(AuthProvider.kakao);

// 또는 개별 메서드 사용
final result = await kAuth.signInWithKakao();
final result = await kAuth.signInWithNaver();
final result = await kAuth.signInWithGoogle();
final result = await kAuth.signInWithApple();

// 결과 처리
if (result.success) {
  final user = result.user!;
  print('로그인 성공!');
  print('이름: ${user.name}');
  print('이메일: ${user.email}');
  print('프로필: ${user.image}');

  // 토큰 확인
  if (result.isExpiringSoon()) {
    print('토큰이 곧 만료됩니다');
  }
} else {
  print('로그인 실패: ${result.errorMessage}');
  if (result.errorHint != null) {
    print('힌트: ${result.errorHint}');
  }
}
```

### 3. UI 버튼 사용

```dart
import 'package:k_auth/k_auth.dart';

// 개별 버튼
KakaoLoginButton(
  onPressed: () => kAuth.signInWithKakao(),
  size: ButtonSize.large,
)

NaverLoginButton(
  onPressed: () => kAuth.signInWithNaver(),
  size: ButtonSize.medium,
)

GoogleLoginButton(
  onPressed: () => kAuth.signInWithGoogle(),
  size: ButtonSize.small,
)

AppleLoginButton(
  onPressed: () => kAuth.signInWithApple(),
  isDark: true,
)

// 아이콘만 표시
KakaoLoginButton(
  onPressed: () => kAuth.signInWithKakao(),
  size: ButtonSize.icon,
)

// 버튼 그룹
LoginButtonGroup(
  providers: [
    AuthProvider.kakao,
    AuthProvider.naver,
    AuthProvider.google,
    AuthProvider.apple,
  ],
  onPressed: (provider) => kAuth.signIn(provider),
  buttonSize: ButtonSize.large,
  direction: ButtonGroupDirection.vertical,
)

// 가로 배치 아이콘 버튼
LoginButtonGroup(
  providers: kAuth.configuredProviders,
  onPressed: (provider) => kAuth.signIn(provider),
  buttonSize: ButtonSize.icon,
  direction: ButtonGroupDirection.horizontal,
)
```

## Provider 설정

### 카카오

```dart
KakaoConfig(
  appKey: 'YOUR_KAKAO_NATIVE_APP_KEY',
  collect: KakaoCollectOptions(
    email: true,      // 이메일
    profile: true,    // 닉네임, 프로필 이미지
    phone: false,     // 전화번호 (개발자센터 활성화 필요)
    birthday: false,  // 생일
    gender: false,    // 성별
    ageRange: false,  // 연령대
    ci: false,        // CI (비즈니스용)
  ),
)
```

**중요**: Native App Key를 사용하세요 (REST API Key 아님)

**플랫폼 설정**:
- iOS: `Info.plist`에 URL Scheme 추가
- Android: `AndroidManifest.xml`에 카카오 설정 추가

[카카오 공식 문서](https://developers.kakao.com/docs/latest/ko/kakaologin/flutter)

### 네이버

```dart
NaverConfig(
  clientId: 'YOUR_CLIENT_ID',
  clientSecret: 'YOUR_CLIENT_SECRET',
  appName: 'Your App Name',
  collect: NaverCollectOptions(
    email: true,
    nickname: true,
    profileImage: true,
    name: false,
    birthday: false,
    mobile: false,
  ),
)
```

> **주의**: 네이버는 OAuth scope 파라미터를 지원하지 않습니다.
> 수집 항목은 [네이버 개발자센터](https://developers.naver.com/apps)에서 직접 설정해야 합니다.
> `collect` 옵션은 문서화 목적으로만 제공됩니다.

**플랫폼 설정**:
- iOS: `Info.plist`에 URL Scheme 추가
- Android: `AndroidManifest.xml`에 네이버 설정 추가

[네이버 공식 문서](https://developers.naver.com/docs/login/flutter/)

### 구글

```dart
GoogleConfig(
  iosClientId: 'YOUR_IOS_CLIENT_ID',      // iOS 필수
  serverClientId: 'YOUR_SERVER_CLIENT_ID', // 백엔드 연동 시
  forceConsent: true,                      // refresh token 획득
  collect: GoogleCollectOptions(
    email: true,
    profile: true,
    openid: true,
  ),
)
```

[Google Cloud Console](https://console.cloud.google.com/apis/credentials)

### 애플

```dart
AppleConfig(
  collect: AppleCollectOptions(
    email: true,
    fullName: true,
  ),
)
```

> **주의**: 애플은 첫 로그인 시에만 이름을 제공합니다.

> 애플 로그인은 iOS 13+, macOS에서만 지원됩니다.

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
| `ageRange` | `String?` | 연령대 |
| `provider` | `String` | 로그인 Provider |
| `rawData` | `Map?` | 원본 응답 데이터 |

**헬퍼 메서드**:
- `displayName`: 표시할 이름 (없으면 이메일에서 추출)
- `age`: 만 나이 (birthyear 기반)

### AuthResult

| 프로퍼티 | 타입 | 설명 |
|---------|------|------|
| `success` | `bool` | 로그인 성공 여부 |
| `user` | `KAuthUser?` | 표준화된 사용자 정보 |
| `provider` | `AuthProvider` | 로그인한 Provider |
| `accessToken` | `String?` | 액세스 토큰 |
| `refreshToken` | `String?` | 리프레시 토큰 |
| `idToken` | `String?` | ID 토큰 (OIDC) |
| `expiresAt` | `DateTime?` | 토큰 만료 시간 |
| `errorMessage` | `String?` | 에러 메시지 (실패 시) |
| `errorCode` | `String?` | 에러 코드 (실패 시) |
| `errorHint` | `String?` | 에러 힌트 (실패 시) |

**헬퍼 메서드**:
- `isExpired`: 토큰 만료 여부
- `isExpiringSoon([Duration])`: 곧 만료되는지 확인
- `timeUntilExpiry`: 만료까지 남은 시간
- `toJson()` / `fromJson()`: JSON 직렬화

### KAuth 메서드

| 메서드 | 설명 |
|--------|------|
| `initialize()` | SDK 초기화 |
| `signIn(provider)` | 소셜 로그인 |
| `signInWithKakao()` | 카카오 로그인 |
| `signInWithNaver()` | 네이버 로그인 |
| `signInWithGoogle()` | 구글 로그인 |
| `signInWithApple()` | 애플 로그인 |
| `signOut(provider)` | 로그아웃 |
| `signOutAll()` | 전체 로그아웃 |
| `unlink(provider)` | 연결 해제 (탈퇴) |
| `isConfigured(provider)` | Provider 설정 여부 |
| `configuredProviders` | 설정된 Provider 목록 |

### 버튼 사이즈

```dart
ButtonSize.small   // 높이 36
ButtonSize.medium  // 높이 48 (기본)
ButtonSize.large   // 높이 56
ButtonSize.icon    // 아이콘만 (정사각형)
```

## 에러 처리

모든 에러는 한글 메시지, 힌트, 문서 링크를 포함합니다.

```dart
final result = await kAuth.signIn(AuthProvider.kakao);

if (!result.success) {
  // 에러 정보 접근
  print('에러: ${result.errorMessage}');
  print('힌트: ${result.errorHint}');

  // 에러 코드별 처리
  switch (result.errorCode) {
    case ErrorCodes.userCancelled:
      // 사용자가 로그인을 취소했습니다.
      break;
    case ErrorCodes.networkError:
      // 네트워크 오류가 발생했습니다.
      break;
    case ErrorCodes.kakaoPhoneNotEnabled:
      // 전화번호 수집 권한이 활성화되지 않았습니다.
      // 힌트: 카카오 개발자센터에서 활성화하세요.
      break;
    case ErrorCodes.providerNotConfigured:
      // 해당 Provider가 설정되지 않았습니다.
      break;
    default:
      print(result.errorMessage);
  }
}

// KAuthError 직접 사용
try {
  kAuth.initialize();
} on KAuthError catch (e) {
  e.log();  // 콘솔에 포맷된 에러 출력
  print(e.toUserMessage());  // 사용자에게 표시할 메시지
}
```

### 에러 코드

| 코드 | 설명 |
|------|------|
| `USER_CANCELLED` | 사용자가 로그인을 취소했습니다 |
| `NETWORK_ERROR` | 네트워크 오류가 발생했습니다 |
| `TOKEN_EXPIRED` | 토큰이 만료되었습니다 |
| `PROVIDER_NOT_CONFIGURED` | Provider가 설정되지 않았습니다 |
| `KAKAO_PHONE_NOT_ENABLED` | 카카오 전화번호 수집 권한 비활성화 |
| `KAKAO_APP_KEY_INVALID` | 카카오 앱 키가 유효하지 않습니다 |
| `NAVER_CLIENT_INFO_INVALID` | 네이버 클라이언트 정보 오류 |
| `GOOGLE_SIGN_IN_FAILED` | 구글 로그인 실패 |
| `APPLE_NOT_SUPPORTED` | 애플 로그인 미지원 기기 |

전체 에러 코드는 [ErrorCodes](lib/errors/k_auth_error.dart)를 참조하세요.

## 플랫폼별 설정

### iOS

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
</array>

<!-- 네이버 -->
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>naver-login</string>
    </array>
  </dict>
</array>

<!-- 애플 -->
<!-- Signing & Capabilities에서 "Sign in with Apple" 추가 -->
```

### Android

`android/app/src/main/AndroidManifest.xml`:

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

## 라이선스

MIT License

## 관련 링크

- [GitHub](https://github.com/k-auth/k-auth)
- [pub.dev](https://pub.dev/packages/k_auth)
- [이슈 등록](https://github.com/k-auth/k-auth/issues)
