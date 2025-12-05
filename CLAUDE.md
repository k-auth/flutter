# K-Auth Flutter

한국 앱을 위한 소셜 로그인 SDK (v0.2.0). 카카오, 네이버, 구글, 애플 로그인을 통합 API로 제공.

## 프로젝트 구조

```
lib/
├── k_auth.dart              # 메인 엔트리포인트 (KAuth, AuthTokens)
├── assets/
│   └── icons/               # SVG 아이콘 (kakao, naver, google)
├── errors/
│   └── k_auth_error.dart    # 한글 에러 메시지 및 에러 코드 (ErrorCodes)
├── models/
│   ├── auth_config.dart     # Provider별 설정 및 수집 옵션
│   ├── auth_result.dart     # 로그인 결과 (fold, when 함수형 패턴)
│   └── k_auth_user.dart     # 표준화된 사용자 정보
├── providers/
│   ├── kakao_provider.dart  # 카카오 SDK 래퍼
│   ├── naver_provider.dart  # 네이버 SDK 래퍼
│   ├── google_provider.dart # 구글 SDK 래퍼
│   └── apple_provider.dart  # 애플 SDK 래퍼
├── utils/
│   ├── diagnostic.dart      # 네이티브 설정 진단 (KAuthDiagnostic)
│   ├── logger.dart          # 디버그 로깅 (KAuthLogger)
│   └── session_storage.dart # 세션 저장소 인터페이스
└── widgets/
    └── login_buttons.dart   # 공식 디자인 버튼 위젯

test/
├── k_auth_test.dart         # KAuth 유닛 테스트
└── widgets_test.dart        # 위젯 테스트
```

## 핵심 개념

### 메인 클래스
- **KAuth**: 메인 클래스. initialize(), signIn(), signOut(), refreshToken() 제공
- **AuthResult**: 로그인 결과. fold/when/onSuccess/onFailure 함수형 패턴
- **KAuthUser**: Provider별로 다른 응답을 표준화한 사용자 모델
- **AuthProvider**: enum (kakao, naver, google, apple)

### 백엔드 연동
- **AuthTokens**: 액세스/리프레시/ID 토큰 및 만료시간
- **OnSignInCallback**: 로그인 성공 후 콜백 (백엔드 JWT 발급용)
- **OnSignOutCallback**: 로그아웃 콜백 (JWT 무효화용)

### 자동 로그인
- **KAuthSessionStorage**: 세션 저장소 인터페이스
- **InMemorySessionStorage**: 테스트용 메모리 저장소
- **KAuthSession**: 저장된 세션 데이터

### 설정 클래스
- **KAuthConfig**: 전체 설정 컨테이너
- **KakaoConfig** + KakaoCollectOptions
- **NaverConfig** + NaverCollectOptions (scope 미지원, 개발자센터에서 설정)
- **GoogleConfig** + GoogleCollectOptions
- **AppleConfig** + AppleCollectOptions

## Provider별 특징

| Provider | 연결해제 | 토큰갱신 | 비고 |
|----------|:-------:|:-------:|------|
| kakao    | O | O | Native App Key 필요 |
| naver    | O | O | scope 미지원, 개발자센터에서 수집항목 설정 |
| google   | O | O | iOS는 iosClientId 필요 |
| apple    | X | X | iOS 13+/macOS만, 첫 로그인시만 이름 제공 |

## 개발 명령어

```bash
flutter pub get              # 의존성 설치
flutter test                 # 테스트 실행
dart analyze                 # 정적 분석
flutter pub publish --dry-run  # 배포 검증
```

## 코드 스타일

- 모든 에러 메시지는 한글로 작성
- 함수형 패턴 (fold, when, mapUser, onSuccess/onFailure 체이닝)
- 각 Provider의 공식 SDK를 래핑하여 통합 API 제공

## 의존성

- `kakao_flutter_sdk`: 카카오 로그인
- `flutter_naver_login`: 네이버 로그인
- `google_sign_in`: 구글 로그인
- `sign_in_with_apple`: 애플 로그인
- `flutter_svg`: SVG 아이콘 렌더링

## 테스트

```bash
flutter test                      # 전체 테스트
flutter test test/k_auth_test.dart   # KAuth 테스트
flutter test test/widgets_test.dart  # 위젯 테스트
```
