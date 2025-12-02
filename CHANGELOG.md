## 0.1.0

### Added

- **KAuthUser 모델**: Provider별 응답을 표준화된 형식으로 통합
  - `id`, `name`, `email`, `image`, `phone`, `birthday`, `birthyear`, `gender`, `ageRange` 필드
  - `displayName`, `age` 헬퍼 메서드
  - `fromKakao()`, `fromNaver()`, `fromGoogle()`, `fromApple()` 팩토리 메서드
  - `toJson()`, `fromJson()` 직렬화 지원

- **향상된 에러 시스템**
  - `hint`: 문제 해결 힌트 제공
  - `docs`: 관련 문서 링크 제공
  - `log()`: 콘솔에 포맷된 에러 출력
  - `toUserMessage()`: 사용자에게 표시할 메시지
  - `KAuthError.fromCode()`: 에러 코드로 KAuthError 생성
  - Provider별 상세 에러 코드 추가 (KAKAO_PHONE_NOT_ENABLED, NAVER_INVALID_CALLBACK 등)

- **Collection Options**: Provider별 수집 옵션 클래스
  - `KakaoCollectOptions`: 이메일, 프로필, 전화번호, 생일, 성별, 연령대, CI
  - `NaverCollectOptions`: 이메일, 닉네임, 프로필 이미지, 이름, 생일, 연령대, 성별, 휴대전화
  - `GoogleCollectOptions`: 이메일, 프로필, OpenID
  - `AppleCollectOptions`: 이메일, 이름

- **설정 검증**
  - `KAuthConfig.validate()`: 설정 유효성 검증
  - `KAuthConfig.isValid`: 설정이 유효한지 확인
  - `KAuthConfig.configuredProviders`: 설정된 Provider 목록
  - 초기화 시 자동 검증 (`validateOnInitialize` 옵션)

- **버튼 사이즈 variants**
  - `ButtonSize.small`: 높이 36
  - `ButtonSize.medium`: 높이 48 (기본)
  - `ButtonSize.large`: 높이 56
  - `ButtonSize.icon`: 아이콘만 표시

- **버튼 상태**
  - `isLoading`: 로딩 상태 표시
  - `disabled`: 비활성화 상태

- **ButtonGroup 개선**
  - `ButtonGroupDirection.horizontal`: 가로 배치
  - `ButtonGroupDirection.vertical`: 세로 배치
  - `loadingStates`: Provider별 로딩 상태
  - `disabledStates`: Provider별 비활성화 상태

- **AuthResult 개선**
  - `user`: KAuthUser 타입의 표준화된 사용자 정보
  - `idToken`: OIDC ID 토큰 필드
  - `errorHint`: 에러 힌트
  - `isExpired`: 토큰 만료 여부
  - `isExpiringSoon()`: 곧 만료되는지 확인
  - `timeUntilExpiry`: 만료까지 남은 시간
  - `toJson()`, `fromJson()`: JSON 직렬화

- **AuthProvider 확장**
  - `displayName`: 표시용 이름 (카카오, 네이버, Google, Apple)
  - `englishName`: 영문 이름
  - `supportsUnlink`: 연결 해제 지원 여부
  - `supportsTokenRefresh`: 토큰 갱신 지원 여부

- **KAuth 클래스 개선**
  - `isInitialized`: 초기화 여부
  - `configuredProviders`: 설정된 Provider 목록
  - `signOutAll()`: 모든 Provider 로그아웃
  - `isConfigured()`: Provider 설정 여부 확인
  - `validateOnInitialize`: 초기화 시 설정 검증 여부

### Changed

- `KakaoConfig`: `collect` 파라미터 추가, `scopes`와 `collectPhone`은 deprecated
- `NaverConfig`: `collect` 파라미터 추가 (문서화 목적)
- `GoogleConfig`: `collect`와 `forceConsent` 파라미터 추가
- `AppleConfig`: `collect` 파라미터 추가
- 에러 반환 시 `errorHint` 포함
- 버튼 높이가 `size` 파라미터로 제어 (`height`는 오버라이드용)

### Deprecated

- `ErrorMessages` 클래스: `ErrorCodes.getErrorInfo()` 사용 권장
- `KakaoConfig.scopes`: `collect` 파라미터 사용 권장
- `KakaoConfig.collectPhone`: `collect.phone` 사용 권장
- `GoogleConfig.withScopes()`: 기본 생성자의 `collect` 파라미터 사용 권장

## 0.0.1

### Added

- 초기 릴리즈
- 카카오 로그인 지원
- 네이버 로그인 지원
- 구글 로그인 지원
- 애플 로그인 지원
- 통합 API (`KAuth.signIn()`)
- 로그인 버튼 UI 위젯
- 한글 에러 메시지
