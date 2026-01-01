# 트러블슈팅

K-Auth 사용 시 발생할 수 있는 문제와 해결 방법입니다.

## 목차

- [공통](#공통)
- [카카오](#카카오)
- [네이버](#네이버)
- [구글](#구글)
- [애플](#애플)
- [에러 코드 레퍼런스](#에러-코드-레퍼런스)

---

## 공통

### PlatformException: channel-error

**원인**: SDK가 초기화되지 않음

**해결**: `kAuth.initialize()` 호출 확인

```dart
await kAuth.initialize();  // 로그인 전 필수
```

### 설정 확인 방법

KAuthDiagnostic으로 설정 진단:

```dart
final result = await KAuthDiagnostic.run(kAuth.config);
print(result.prettyPrint());
```

CLI로 진단:

```bash
dart run k_auth
```

---

## 카카오

### KOE101: Invalid client

**원인**: 네이티브 앱 키가 잘못되었거나 플랫폼 설정이 없음

**해결**:

1. 카카오 개발자 콘솔에서 **네이티브 앱 키** 확인 (REST API 키 아님!)
2. 플랫폼 설정에서 패키지명/번들 ID 확인
3. Android: 키 해시 등록 확인

### KOE006: 등록되지 않은 앱

**원인**: 카카오 로그인이 활성화되지 않음

**해결**:

1. 카카오 개발자 콘솔 > 카카오 로그인 > 활성화 설정 ON

### iOS에서 카카오톡 앱이 열리지 않음

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

---

## 네이버

### Android에서 로그인 창이 안 열림

**원인**: MainActivity가 FlutterFragmentActivity를 상속하지 않음

**해결**: MainActivity.kt 수정

```kotlin
import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity: FlutterFragmentActivity()
```

### 인증 실패 (invalid_request)

**원인**: Client ID 또는 Client Secret이 잘못됨

**해결**:

1. 네이버 개발자 센터에서 Client ID/Secret 재확인
2. 앱 이름이 개발자 센터 등록명과 일치하는지 확인

---

## 구글

### iOS에서 DEVELOPER_ERROR

**원인**: iOS 클라이언트 ID가 설정되지 않음

**해결**:

```dart
GoogleConfig(
  iosClientId: 'YOUR_IOS_CLIENT_ID.apps.googleusercontent.com',
)
```

### Android에서 DEVELOPER_ERROR (10)

**원인**: SHA-1 인증서 지문이 등록되지 않음

**해결**:

1. SHA-1 지문 확인: `./gradlew signingReport`
2. Google Cloud Console > 사용자 인증 정보 > Android 클라이언트 > SHA-1 인증서 지문 추가

### accessToken이 null로 반환됨

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

---

## 애플

### Sign in with Apple 버튼이 안 보임

**원인**: iOS 13 미만이거나 Capability가 추가되지 않음

**해결**:

1. Xcode > Signing & Capabilities > Sign in with Apple 추가
2. Apple Developer에서 App ID에 Sign in with Apple 활성화

### 이름/이메일이 null로 반환됨

**원인**: Apple은 최초 로그인 시에만 이름/이메일 제공

**해결**:

- 최초 로그인 시 받은 정보를 서버에 저장
- 테스트 시 Apple ID 설정 > 암호 및 보안 > Apple로 로그인하는 앱 에서 앱 연결 해제 후 재시도

---

## 에러 코드 레퍼런스

| 코드                      | 설명                 | 재시도 가능 |
| ------------------------- | -------------------- | :--------: |
| `USER_CANCELLED`          | 사용자가 로그인 취소 | - |
| `NETWORK_ERROR`           | 네트워크 연결 오류   | O |
| `TIMEOUT`                 | 요청 시간 초과       | O |
| `PROVIDER_NOT_CONFIGURED` | Provider 설정 누락   | X |
| `PLATFORM_NOT_SUPPORTED`  | 지원하지 않는 플랫폼 | X |
| `TOKEN_EXPIRED`           | 토큰 만료            | O (갱신) |
| `INVALID_CREDENTIALS`     | 잘못된 인증 정보     | X |
| `KAKAO_*`                 | 카카오 관련 에러     | - |
| `NAVER_*`                 | 네이버 관련 에러     | - |
| `GOOGLE_*`                | 구글 관련 에러       | - |
| `APPLE_*`                 | 애플 관련 에러       | - |

### KAuthFailure 활용

```dart
result.onFailure((failure) {
  // 무시해도 되는 에러 (사용자 취소)
  if (failure.shouldIgnore) return;

  // 재시도 가능한 에러 (네트워크, 타임아웃)
  if (failure.canRetry) {
    showRetryDialog(failure.displayMessage);
    return;
  }

  // 그 외 에러
  showErrorDialog(failure.displayMessage);
});
```

---

[← README로 돌아가기](../README.md)
