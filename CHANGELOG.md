## 0.2.0

### Added
- 함수형 API: `fold`, `when`, `onSuccess`, `onFailure`, `mapUser`, `mapUserOr`
- 상태 관리: `authStateChanges` Stream, `currentUser`, `currentProvider`, `isSignedIn`
- 자동 로그인: `KAuthSessionStorage` 인터페이스, `initialize(autoRestore: true)`
- 백엔드 연동: `onSignIn`, `onSignOut` 콜백, `serverToken`
- 토큰 갱신: `refreshToken()`, `isExpired`, `isExpiringSoon()`
- 설정 진단: `KAuthDiagnostic.run()` - 네이티브 설정 검증
- 디버그 로깅: `KAuthLogger`
- SVG 아이콘: 카카오, 네이버, 구글 로고

### Changed
- `signOut()` provider 인자 생략 가능 (현재 Provider로 자동)
- `AuthResult` JSON 직렬화 지원

### Removed (Breaking)
- `AuthResult.userId`, `email`, `name`, `profileImageUrl` 제거 → `user.*` 사용
- deprecated API 제거 (`collectPhone`, `withScopes()` 등)

## 0.1.0

### Added
- 카카오/네이버/구글/애플 OAuth 통합 API
- `KAuthUser` 표준화된 사용자 정보
- 한글 에러 메시지 + 힌트
- 로그인 버튼 UI 컴포넌트

## 0.0.1

- 초기 릴리즈
