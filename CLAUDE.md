# K-Auth Flutter

한국 앱을 위한 소셜 로그인 SDK. 카카오, 네이버, 구글, 애플 로그인을 통합 API로 제공.

## 프로젝트 구조

```
lib/
├── k_auth.dart           # 메인 엔트리포인트 (KAuth 클래스)
├── errors/
│   └── k_auth_error.dart # 한글 에러 메시지 및 에러 코드
├── models/
│   ├── auth_config.dart  # Provider별 설정 (KAuthConfig, KakaoConfig 등)
│   ├── auth_result.dart  # 로그인 결과 (fold, when 함수형 패턴)
│   └── k_auth_user.dart  # 표준화된 사용자 정보
├── providers/
│   ├── kakao_provider.dart
│   ├── naver_provider.dart
│   ├── google_provider.dart
│   └── apple_provider.dart
├── utils/
│   ├── diagnostic.dart      # 설정 진단 (KAuthDiagnostic)
│   ├── logger.dart          # 디버그 로깅
│   └── session_storage.dart # 세션 저장소 인터페이스
└── widgets/
    └── login_buttons.dart   # 공식 디자인 가이드라인 버튼
```

## 핵심 개념

- **KAuth**: 메인 클래스. initialize(), signIn(), signOut() 제공
- **AuthResult**: 로그인 결과. fold/when 패턴으로 함수형 처리
- **KAuthUser**: Provider별로 다른 응답을 표준화한 사용자 모델
- **KAuthSessionStorage**: 자동 로그인을 위한 세션 저장소 인터페이스

## 개발 명령어

```bash
# 의존성 설치
flutter pub get

# 테스트 실행
flutter test

# 정적 분석
dart analyze

# pub.dev 배포 (dry-run)
flutter pub publish --dry-run
```

## 코드 스타일

- 모든 에러 메시지는 한글로 작성
- 함수형 패턴 (fold, when, mapUser 등) 권장
- 각 Provider의 공식 SDK를 래핑하여 통합 API 제공
- 테스트는 test/ 디렉토리에 위치

## 의존성

- `kakao_flutter_sdk`: 카카오 로그인
- `flutter_naver_login`: 네이버 로그인
- `google_sign_in`: 구글 로그인
- `sign_in_with_apple`: 애플 로그인

## 테스트

```bash
flutter test                    # 전체 테스트
flutter test test/unit/         # 유닛 테스트만
flutter test test/widget/       # 위젯 테스트만
```
