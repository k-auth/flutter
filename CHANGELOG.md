# Changelog

All notable changes to this project will be documented in this file.

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
