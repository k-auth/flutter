# Changelog

All notable changes to this project will be documented in this file.

## [0.5.3] - 2025-12

### Fixed

- **Documentation**: API 문서 콜백 시그니처 수정
  - `onFailure((error) => ...)` → `onFailure((failure) => ...)`
  - `when(failure: (code, message) => ...)` → `when(failure: (failure) => ...)`
- **Documentation**: 에러 코드 docs 링크 404 방지 (트러블슈팅 섹션으로 연결)
- **Documentation**: PATTERNS.md `displayName` null 처리 예제 수정
- **Diagnostic**: 네이버 Info.plist 키 이름 수정 (`NidConsumerKey`, `NidConsumerSecret`)
- **CLI**: 버전 표시 수정

### Added

- **Widget**: `KAuthBuilder`에 `error` 콜백 추가 - 스트림 에러 처리 지원

### Improved

- **VSCode Snippets**: 콜백 시그니처 최신 API 반영

### Removed

- **Config**: `NaverCollectOptions` 클래스 제거 - 네이버는 scope 미지원 (개발자센터에서 설정)

## [0.5.2] - 2025-12

### Added

- **Testing**: `MockKAuth` 클래스 추가 - 테스트에서 실제 SDK 없이 인증 시뮬레이션
  - `MockKAuth.signedIn()` - 이미 로그인된 상태로 생성
  - `setCancelled()`, `setNetworkError()` - 실패 시뮬레이션
  - Widget 테스트, 유닛 테스트 지원

### Improved

- **Error**: 에러 문서 링크 개선 - README 트러블슈팅 섹션 직접 연결
  - `KAuthError.docs` → `https://github.com/k-auth/flutter#에러코드`

## [0.5.1] - 2025-12

### Changed

- **Breaking**: `KAuthUser.provider` 타입 변경: `String` → `AuthProvider` enum
  - 타입 안전성 향상
  - `user.provider == AuthProvider.kakao` 비교 가능
- **Refactor**: Provider 코드 개선 - `_buildResult` 헬퍼 메서드로 중복 제거
- **Refactor**: 버튼 위젯 리팩토링 - `_SocialButton` 베이스 클래스로 745→589 라인
- **Dependencies**: 의존성 업그레이드
  - `flutter_secure_storage`: 9.2.0 → 10.0.0 (보안 개선)
  - `flutter_lints`: 5.0.0 → 6.0.0
- **Environment**: SDK 버전 요구사항 명확화
  - Dart SDK: ^3.4.0 (기존 ^3.0.0)
  - Flutter: >=3.22.0 (기존 >=3.0.0)

### Added

- **API**: `signIn()` 동시성 제어 - 중복 호출 시 동일 Future 반환
- **Error**: Naver ErrorMapper 개선 - 더 많은 에러 패턴 지원
  - 한글 키워드: `거부`, `연결`, `시간 초과`, `만료`, `세션`, `권한`
  - 영문 키워드: `denied`, `timeout`, `oauth`, `permission`, `redirect`

### Fixed

- **Storage**: `SecureSessionStorage`에서 deprecated된 `encryptedSharedPreferences` 옵션 제거

### Migration Guide (0.5.0 → 0.5.1)

**KAuthUser.provider 타입 변경**
```dart
// Before (0.5.0)
if (user.provider == 'kakao') { ... }
print(user.provider.toUpperCase());

// After (0.5.1)
if (user.provider == AuthProvider.kakao) { ... }
print(user.provider.name.toUpperCase());
```

## [0.5.0] - 2024-12

### Added

- **CLI**: `dart run k_auth` - 대화형 설정 도우미
  - Provider 선택 및 앱 키 입력
  - `AndroidManifest.xml`, `Info.plist` 자동 수정
  - `lib/k_auth_config.dart` 설정 파일 생성
  - `dart run k_auth doctor` - 설정 진단
- **API**: `KAuth.init()` 팩토리 메서드 - 한 줄 초기화 + 자동 세션 복원
- **API**: 편의 getter 추가 - `userId`, `name`, `email`, `avatar`
- **Model**: `KAuthFailure` 클래스 - 실패 정보를 담는 데이터 클래스
  - `isCancelled`, `isNetworkError`, `isTokenExpired` 등 편의 getter
  - `displayMessage` - 기본 메시지 fallback
- **Widget**: `KAuthBuilder` - StreamBuilder 래퍼 위젯
- **Storage**: `SecureSessionStorage` - flutter_secure_storage 기반 기본 저장소

### Changed

- **Breaking**: `KAuthUser.image` → `avatar`로 필드명 변경
- **Breaking**: `fold`, `when`, `onFailure` 콜백 시그니처 변경
  - `onFailure((error) => ...)` → `onFailure((failure) => ...)`
  - `when(failure: (code, message) => ...)` → `when(failure: (failure) => ...)`

### Removed

- `llms.txt` 삭제 (CLAUDE.md로 대체)

### Migration Guide (0.4.x → 0.5.0)

**1. avatar 필드명 변경**
```dart
// Before
user.image

// After
user.avatar
```

**2. 콜백 시그니처 변경**
```dart
// Before
result.fold(
  onSuccess: (user) => ...,
  onFailure: (error) => print(error),
);
result.onFailure((code, message) => print(message));

// After
result.fold(
  onSuccess: (user) => ...,
  onFailure: (failure) => print(failure.message),
);
result.onFailure((failure) {
  if (failure.isCancelled) return;  // 취소 처리 간편화
  print(failure.displayMessage);
});
```

## [0.4.3] - 2024-12

### Added

- **Error**: `ErrorMapper` 클래스 추가 - Provider별 네이티브 에러를 한글 메시지로 변환
  - Kakao: `KakaoAuthException`, `KakaoApiException` 에러 매핑
  - Google: `GoogleSignInException` 에러 매핑
  - Naver: 에러 메시지 키워드 기반 매핑
- **Validation**: `GoogleConfig.validate()` - iOS에서 `iosClientId` 필수 검증 추가
- **Test**: `ErrorMapper` 테스트 42개 추가

### Changed

- **Refactor**: Provider별 에러 매핑 로직을 `ErrorMapper` 클래스로 분리
- **Error**: 에러 메시지에 해결 방법(hint)과 문서 링크(docs) 포함

## [0.4.2] - 2024-12

### Fixed

- **Documentation**: README에서 `scopes` 파라미터를 `collect` 옵션으로 수정 (실제 API와 일치)

## [0.4.1] - 2024-12

### Fixed

- **Documentation**: iOS Info.plist `CFBundleURLTypes` 중복 선언 문제 수정
- **Documentation**: 네이버 iOS 설정 추가 (Info.plist 키, AppDelegate URL 핸들링)
- **Documentation**: 네이버 Android 설정 추가 (strings.xml, AndroidManifest.xml 메타데이터)

## [0.4.0] - 2024-12

### Changed

- **API**: `signOut()`, `unlink()` 반환 타입을 `Future<AuthResult>`로 변경 (Result 패턴 통일)
- **API**: `signOutAll()` 반환 타입을 `Future<List<AuthResult>>`로 변경
- **Error**: 에러 메시지 kDebugMode 분기 (개발: 상세, 릴리즈: 간결)
- **Error**: `tokenRefreshFailed` → `refreshFailed`로 간결화

### Added

- **Error**: `signOutFailed`, `unlinkFailed`, `refreshFailed` 에러 코드 추가
- **CI/CD**: GitHub Actions 워크플로우 추가 (테스트, 분석, 자동 배포)
- **Test**: Provider별 테스트, 에러 케이스 테스트 추가

### Fixed

- **API**: `isConfigured()` 초기화 전에도 동작하도록 수정
- **API**: `refreshToken()` 기본 provider를 configuredProviders에서 선택
- **UI**: `.withOpacity()` deprecated API를 `.withValues(alpha:)`로 수정
- **Error**: Apple `unlink()` 명확한 에러 메시지 및 문서 링크 추가

### Migration Guide (0.3.x → 0.4.0)

#### Breaking Changes

**1. `signOut()` 반환 타입 변경**

```dart
// Before (0.3.x)
await kAuth.signOut();  // Future<void>

// After (0.4.0)
final result = await kAuth.signOut();  // Future<AuthResult>
if (result.success) {
  print('로그아웃 성공');
} else {
  print('로그아웃 실패: ${result.errorMessage}');
}
```

**2. `unlink()` 반환 타입 변경**

```dart
// Before (0.3.x)
await kAuth.unlink(AuthProvider.kakao);  // Future<void>

// After (0.4.0)
final result = await kAuth.unlink(AuthProvider.kakao);  // Future<AuthResult>
result.fold(
  onSuccess: (_) => print('연결 해제 완료'),
  onFailure: (error) => print('실패: $error'),
);
```

**3. `signOutAll()` 반환 타입 변경**

```dart
// Before (0.3.x)
await kAuth.signOutAll();  // Future<void>

// After (0.4.0)
final results = await kAuth.signOutAll();  // Future<List<AuthResult>>
for (final result in results) {
  print('${result.provider}: ${result.success ? '성공' : '실패'}');
}
```

#### 권장 마이그레이션

기존 코드가 단순히 `signOut()`을 호출만 하고 결과를 사용하지 않았다면, 코드 변경 없이 동작합니다. 하지만 에러 처리를 추가하는 것을 권장합니다:

```dart
// 최소 변경 (기존 코드 호환)
await kAuth.signOut();  // 여전히 동작함

// 권장 (에러 처리 추가)
final result = await kAuth.signOut();
if (!result.success) {
  // 에러 처리
}
```

## [0.3.3] - 2024-12

### Fixed

- **UI**: Google login button font weight consistency (w500 → w600)

## [0.3.2] - 2024-12

### Added

- **Documentation**: Comprehensive setup guides for all providers
- **Documentation**: Detailed platform configuration (iOS/Android)
- **Documentation**: Advanced usage examples (auto-login, backend integration)
- **Documentation**: Full app example (main, login, home screens)
- **Documentation**: Troubleshooting section with common errors

## [0.3.1] - 2024-12

### Changed

- **Documentation**: Complete overhaul of README and CHANGELOG

## [0.3.0] - 2024-12

### Changed

- **Dependencies**: Updated all dependencies to latest versions
  - `kakao_flutter_sdk`: ^1.10.0
  - `flutter_naver_login`: ^2.1.0
  - `google_sign_in`: ^7.2.0
  - `sign_in_with_apple`: ^7.0.0
  - `flutter_svg`: ^2.2.0
- **pub.dev**: Improved package score (English description, code formatting)

## [0.2.0] - 2024-12

### Added

- **Functional API**: `fold`, `when`, `onSuccess`, `onFailure`, `mapUser`, `mapUserOr`
- **State Management**: `authStateChanges` Stream, `currentUser`, `currentProvider`, `isSignedIn`
- **Auto Login**: `KAuthSessionStorage` interface, `initialize(autoRestore: true)`
- **Backend Integration**: `onSignIn`, `onSignOut` callbacks, `serverToken`
- **Token Refresh**: `refreshToken()`, `isExpired`, `isExpiringSoon()`
- **Diagnostics**: `KAuthDiagnostic.run()` for native configuration validation
- **Debug Logging**: `KAuthLogger`
- **SVG Icons**: Kakao, Naver, Google logos

### Changed

- `signOut()` provider argument now optional (uses current provider)
- `AuthResult` now supports JSON serialization

### Removed (Breaking)

- `AuthResult.userId`, `email`, `name`, `profileImageUrl` - use `user.*` instead
- Deprecated APIs (`collectPhone`, `withScopes()`, etc.)

## [0.1.0] - 2024-11

### Added

- Unified OAuth API for Kakao, Naver, Google, Apple
- `KAuthUser` standardized user model
- Korean error messages with hints
- Login button UI components

## [0.0.1] - 2024-11

- Initial release
