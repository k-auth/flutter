## 0.2.0

### Added
- 함수형 API: `fold`, `when`, `onSuccess`, `onFailure`, `mapUser`
- 상태 관리: `authStateChanges` Stream, `currentUser`, `isSignedIn`
- 디버그 로깅: `KAuthLogger`

### Changed
- `signOut()` provider 인자 생략 가능

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
