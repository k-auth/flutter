# K-Auth Flutter

한국형 소셜 로그인 Flutter 라이브러리. 카카오/네이버/구글/애플 OAuth를 Flutter에서 쉽게 구현할 수 있습니다.

> Next.js 버전: [k-auth](https://github.com/k-auth/next) (예정)

## 설치

```yaml
dependencies:
  k_auth: ^0.0.1
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
        clientId: 'YOUR_NAVER_CLIENT_ID',
        clientSecret: 'YOUR_NAVER_CLIENT_SECRET',
        appName: 'Your App Name',
      ),
      google: GoogleConfig(),
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
  print('로그인 성공!');
  print('이름: ${result.name}');
  print('이메일: ${result.email}');
} else {
  print('로그인 실패: ${result.errorMessage}');
}
```

### 3. UI 버튼 사용

```dart
import 'package:k_auth/k_auth.dart';

// 개별 버튼
KakaoLoginButton(
  onPressed: () => kAuth.signInWithKakao(),
)

NaverLoginButton(
  onPressed: () => kAuth.signInWithNaver(),
)

GoogleLoginButton(
  onPressed: () => kAuth.signInWithGoogle(),
)

AppleLoginButton(
  onPressed: () => kAuth.signInWithApple(),
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
)
```

## Provider 설정

### 카카오

```dart
KakaoConfig(
  appKey: 'YOUR_KAKAO_NATIVE_APP_KEY',
  collectPhone: true,  // 전화번호 수집 시
  scopes: ['friends'], // 추가 scope
)
```

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
)
```

**플랫폼 설정**:
- iOS: `Info.plist`에 URL Scheme 추가
- Android: `AndroidManifest.xml`에 네이버 설정 추가

[네이버 공식 문서](https://developers.naver.com/docs/login/flutter/)

### 구글

```dart
GoogleConfig(
  iosClientId: 'YOUR_IOS_CLIENT_ID',  // iOS만
  serverClientId: 'YOUR_SERVER_CLIENT_ID',  // 백엔드 연동 시
)
```

### 애플

```dart
AppleConfig()
```

> 애플 로그인은 iOS 13+, macOS에서만 지원됩니다.

## API 레퍼런스

### AuthResult

| 프로퍼티 | 타입 | 설명 |
|---------|------|------|
| `success` | `bool` | 로그인 성공 여부 |
| `provider` | `AuthProvider` | 로그인한 Provider |
| `userId` | `String?` | 사용자 고유 ID |
| `email` | `String?` | 이메일 |
| `name` | `String?` | 이름 |
| `profileImageUrl` | `String?` | 프로필 이미지 URL |
| `accessToken` | `String?` | 액세스 토큰 |
| `refreshToken` | `String?` | 리프레시 토큰 |
| `errorMessage` | `String?` | 에러 메시지 (실패 시) |
| `errorCode` | `String?` | 에러 코드 (실패 시) |
| `rawData` | `Map?` | 원본 응답 데이터 |

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
| `unlink(provider)` | 연결 해제 (탈퇴) |

## 에러 처리

모든 에러 메시지는 한국어로 제공됩니다.

```dart
final result = await kAuth.signIn(AuthProvider.kakao);

if (!result.success) {
  switch (result.errorCode) {
    case ErrorCodes.userCancelled:
      // 사용자가 로그인을 취소했습니다.
      break;
    case ErrorCodes.networkError:
      // 네트워크 오류가 발생했습니다.
      break;
    case ErrorCodes.providerNotConfigured:
      // 해당 Provider가 설정되지 않았습니다.
      break;
    default:
      print(result.errorMessage);
  }
}
```

## 라이선스

MIT License
