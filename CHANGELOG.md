# Changelog

All notable changes to this project will be documented in this file.

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
