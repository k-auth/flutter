# K-Auth Flutter

한국 앱을 위한 소셜 로그인 SDK (v0.5.6). 카카오, 네이버, 구글, 애플 로그인을 통합 API로 제공.

## 요구사항

| 환경 | 최소 버전 |
|------|----------|
| Flutter | 3.22.0 |
| Dart | 3.4.0 |
| iOS | 13.0 |
| Android | API 21 |

## CLI 도구

```bash
dart run k_auth          # 설정 진단 (기본)
dart run k_auth help     # 도움말
```

## 프로젝트 구조

```
bin/
└── k_auth.dart              # CLI 설정 진단 도구

lib/
├── k_auth.dart              # 메인 엔트리포인트 (KAuth, AuthTokens)
├── assets/
│   └── icons/               # SVG 아이콘 (kakao, naver, google)
├── errors/
│   ├── error_mapper.dart    # Provider별 에러 → 표준 에러 변환
│   └── k_auth_error.dart    # 한글 에러 메시지 및 에러 코드 (ErrorCodes)
├── models/
│   ├── auth_config.dart     # Provider별 설정 및 수집 옵션
│   ├── auth_result.dart     # 로그인 결과 (fold, when 함수형 패턴)
│   ├── k_auth_failure.dart  # 실패 정보 (isCancelled, canRetry, shouldIgnore 등)
│   └── k_auth_user.dart     # 표준화된 사용자 정보
├── providers/
│   ├── kakao_provider.dart  # 카카오 SDK 래퍼
│   ├── naver_provider.dart  # 네이버 SDK 래퍼
│   ├── google_provider.dart # 구글 SDK 래퍼
│   └── apple_provider.dart  # 애플 SDK 래퍼
├── testing/
│   └── mock_k_auth.dart     # 테스트용 MockKAuth
├── utils/
│   ├── diagnostic.dart      # 네이티브 설정 진단 (KAuthDiagnostic)
│   ├── logger.dart          # 디버그 로깅 (KAuthLogger)
│   └── session_storage.dart # 세션 저장소 (SecureSessionStorage)
└── widgets/
    └── login_buttons.dart   # 공식 디자인 버튼 위젯 + KAuthBuilder

docs/
├── SETUP.md                 # iOS/Android 플랫폼 설정 가이드
└── TROUBLESHOOTING.md       # 문제 해결 가이드

test/
├── k_auth_test.dart         # KAuth 유닛 테스트
├── provider_test.dart       # Provider 파싱 테스트
├── error_test.dart          # 에러 처리 테스트
└── widgets_test.dart        # 위젯 테스트
```

## 핵심 개념

### 메인 클래스
- **KAuth**: 메인 클래스. `KAuth.init()` 또는 `initialize()`, `signIn()`, `signOut()`, `refreshToken()` 제공
- **KAuth.init()**: 팩토리 메서드. 초기화 + SecureStorage + 자동 로그인 + 토큰 자동 갱신
- **AuthResult**: 로그인 결과. fold/when/onSuccess/onFailure 함수형 패턴
- **KAuthUser**: Provider별로 다른 응답을 표준화한 사용자 모델
- **AuthProvider**: enum (kakao, naver, google, apple)
- **KAuthBuilder**: 인증 상태에 따른 화면 전환 위젯
- **MockKAuth**: 테스트용 Mock 클래스

### 편의 Getter (KAuth)
- `kAuth.userId` → `currentUser?.id`
- `kAuth.name` → `currentUser?.displayName`
- `kAuth.email` → `currentUser?.email`
- `kAuth.avatar` → `currentUser?.avatar`

### 토큰 관리
- `kAuth.isExpired` → 토큰 만료 여부
- `kAuth.isExpiringSoon()` → 만료 임박 여부 (기본 5분)
- `kAuth.expiresAt` → 토큰 만료 시간
- `kAuth.expiresIn` → 토큰 남은 시간

### 백엔드 연동
- **AuthTokens**: 액세스/리프레시/ID 토큰 및 만료시간
- **OnSignInCallback**: 로그인 성공 후 콜백 (백엔드 JWT 발급용)
- **OnSignOutCallback**: 로그아웃 콜백 (JWT 무효화용)

### 자동 로그인 & 자동 갱신
- **SecureSessionStorage**: 기본 암호화 저장소 (flutter_secure_storage 기반)
- **KAuthSessionStorage**: 세션 저장소 인터페이스 (커스텀 구현용)
- **InMemorySessionStorage**: 테스트용 메모리 저장소
- **autoRefresh**: 앱 포그라운드 복귀 시 토큰 자동 갱신 (v0.5.6+)

### 설정 클래스
- **KAuthConfig**: 전체 설정 컨테이너
- **KakaoConfig** + KakaoCollectOptions
- **NaverConfig** (scope 미지원, 개발자센터에서 설정)
- **GoogleConfig** + GoogleCollectOptions
- **AppleConfig** + AppleCollectOptions

## Provider별 특징

| Provider | 연결해제 | 토큰갱신 | 비고 |
|----------|:-------:|:-------:|------|
| kakao    | O | O | Native App Key 필요 |
| naver    | O | O | scope 미지원, 개발자센터에서 수집항목 설정 |
| google   | O | O | iOS는 iosClientId 필요 |
| apple    | X | X | iOS 13+/macOS만, 첫 로그인시만 이름 제공 |

## 버전 호환성

| k_auth | kakao_flutter_sdk | flutter_naver_login | google_sign_in | sign_in_with_apple |
|--------|-------------------|---------------------|----------------|--------------------|
| 0.5.x  | 1.10.x            | 2.1.x               | 7.2.x          | 7.0.x              |

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
- `flutter_secure_storage`: 암호화된 세션 저장 (자동 로그인)

## 테스트

```bash
flutter test                      # 전체 테스트
flutter test test/k_auth_test.dart   # KAuth 테스트
flutter test test/widgets_test.dart  # 위젯 테스트
```

## AI 코드 생성 가이드

> 이 섹션은 Claude Code, GitHub Copilot 등 AI 코드 생성 도구가 k-auth 코드를 쉽게 생성할 수 있도록 작성되었습니다.

### 가장 많이 사용되는 코드 패턴 (복사해서 사용)

#### 1. 기본 초기화 (권장 - KAuth.init)

```dart
import 'package:flutter/material.dart';
import 'package:k_auth/k_auth.dart';

late final KAuth kAuth;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 한 줄로 초기화 + SecureStorage + 자동 로그인 + 토큰 자동 갱신
  kAuth = await KAuth.init(
    kakao: KakaoConfig(appKey: 'YOUR_KAKAO_APP_KEY'),
    naver: NaverConfig(
      clientId: 'YOUR_NAVER_CLIENT_ID',
      clientSecret: 'YOUR_NAVER_CLIENT_SECRET',
      appName: 'My App',
    ),
    google: GoogleConfig(),
    apple: AppleConfig(),
    autoRestore: true,   // 자동 로그인 (기본값: true)
    autoRefresh: true,   // 토큰 자동 갱신 (기본값: true)
  );

  // 이미 로그인되어 있으면 바로 사용자 정보 접근 가능
  if (kAuth.isSignedIn) {
    print('환영합니다, ${kAuth.name}!');
  }

  runApp(MyApp());
}
```

#### 1-1. 기존 방식 (더 세밀한 제어가 필요할 때)

```dart
final kAuth = KAuth(
  config: KAuthConfig(
    kakao: KakaoConfig(appKey: 'YOUR_KAKAO_APP_KEY'),
  ),
  storage: SecureSessionStorage(),  // 커스텀 저장소
  autoRefresh: true,
);

await kAuth.initialize(autoRestore: true);
```

#### 2. 로그인 처리 (3가지 방법)

**간단한 방법** - 프로토타입, 빠른 구현
```dart
final result = await kAuth.signIn(AuthProvider.kakao);
if (result.success) {
  print('환영합니다, ${result.user?.displayName}!');
} else {
  print('로그인 실패: ${result.errorMessage}');
}
```

**추천 방법** - fold 패턴 (함수형)
```dart
final result = await kAuth.signIn(AuthProvider.kakao);
result.fold(
  onSuccess: (user) => navigateToHome(user),
  onFailure: (failure) => showError(failure.message),
);
```

**프로덕션 방법** - when 패턴 (성공/취소/실패 구분)
```dart
final result = await kAuth.signIn(AuthProvider.kakao);
result.when(
  success: (user) => navigateToHome(user),
  cancelled: () => showSnackBar('로그인이 취소되었습니다'),
  failure: (failure) => showErrorDialog(failure.message),
);
```

**KAuthFailure 편의 메서드**
```dart
result.onFailure((failure) {
  if (failure.shouldIgnore) return;  // 취소 등 무시해도 되는 에러
  if (failure.canRetry) {
    showRetryButton();  // 네트워크 오류 등 재시도 가능
  } else {
    showError(failure.displayMessage);
  }
});
```

#### 3. 화면 전환 (KAuthBuilder 사용 - 권장)

```dart
// KAuthBuilder로 간단하게
KAuthBuilder(
  stream: kAuth.authStateChanges,
  signedIn: (user) => HomeScreen(user: user),
  signedOut: () => LoginScreen(),
  loading: () => SplashScreen(),  // 선택
  error: (e) => ErrorScreen(e),   // 선택
)
```

#### 3-1. StreamBuilder 직접 사용

```dart
StreamBuilder<KAuthUser?>(
  stream: kAuth.authStateChanges,
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return SplashScreen();
    }
    if (snapshot.hasData && snapshot.data != null) {
      return HomeScreen(user: snapshot.data!);
    }
    return LoginScreen();
  },
)
```

#### 4. 버튼 위젯 사용

```dart
// 버튼 그룹 (추천) - 로딩 상태 자동 관리
AuthProvider? _loading;

LoginButtonGroup(
  providers: [AuthProvider.kakao, AuthProvider.naver, AuthProvider.google],
  loading: _loading,  // 로딩 중인 버튼, 나머지는 자동 비활성화
  onPressed: (p) async {
    setState(() => _loading = p);
    await kAuth.signIn(p);
    setState(() => _loading = null);
  },
)

// 개별 버튼
KakaoLoginButton(onPressed: () => kAuth.signIn(AuthProvider.kakao))

// 아이콘만 있는 버튼 (가로 배치용)
Row(children: [
  KakaoLoginButton.icon(onPressed: ...),
  NaverLoginButton.icon(onPressed: ...),
  GoogleLoginButton.icon(onPressed: ...),
  AppleLoginButton.icon(onPressed: ...),
])
```

#### 5. 토큰 자동 갱신 (v0.5.6+)

```dart
// KAuth.init()에서 autoRefresh: true (기본값)
// → 앱이 포그라운드로 돌아올 때 토큰 상태 확인 후 자동 갱신

// 수동 갱신이 필요한 경우
if (kAuth.isExpiringSoon()) {
  final result = await kAuth.refreshToken();
  result.fold(
    onSuccess: (_) => print('토큰 갱신 성공'),
    onFailure: (f) => print('토큰 갱신 실패: ${f.message}'),
  );
}

// 토큰 상태 확인
print('만료됨: ${kAuth.isExpired}');
print('곧 만료: ${kAuth.isExpiringSoon()}');  // 5분 이내
print('만료 시간: ${kAuth.expiresAt}');
print('남은 시간: ${kAuth.expiresIn}');
```

### 참고 파일

AI 코드 생성 시 참고할 파일들:
- **PATTERNS.md** - 모든 주요 패턴과 예제 (AI 전용)
- **example/lib/main.dart** - 프로덕션 예제 (Demo 모드 포함)
- **.vscode/k_auth.code-snippets** - VSCode 스니펫
- **docs/SETUP.md** - 플랫폼별 설정 가이드
- **docs/TROUBLESHOOTING.md** - 문제 해결 가이드

### 주의사항

#### ❌ 이렇게 하지 마세요 (안티패턴)

```dart
// 1. initialize() 전에 signIn() 호출
final kAuth = KAuth(config: config);
await kAuth.signIn(AuthProvider.kakao); // ❌ 에러 발생!

// 2. null 체크 없이 user 접근
final result = await kAuth.signIn(AuthProvider.kakao);
print(result.user.displayName); // ❌ user가 null일 수 있음!

// 3. Apple 토큰 갱신 시도
await kAuth.refreshToken(AuthProvider.apple); // ❌ Apple은 토큰 갱신 미지원!
```

#### ✅ 이렇게 하세요 (베스트 프랙티스)

```dart
// 1. KAuth.init() 사용 (권장) 또는 반드시 initialize() 먼저 호출
final kAuth = await KAuth.init(kakao: KakaoConfig(appKey: 'xxx')); // ✅

// 2. 항상 fold/when 사용 (타입 안전)
final result = await kAuth.signIn(AuthProvider.kakao);
result.fold(
  onSuccess: (user) => print(user.displayName), // ✅
  onFailure: (failure) => print(failure.message),
);

// 3. 토큰 갱신 가능 여부 확인
if (kAuth.currentProvider?.supportsTokenRefresh ?? false) {
  await kAuth.refreshToken(); // ✅
}
```

### 자주 사용하는 메서드 체크리스트

```dart
// 초기화 (권장)
final kAuth = await KAuth.init(
  kakao: KakaoConfig(appKey: 'xxx'),
  autoRestore: true,   // 자동 로그인
  autoRefresh: true,   // 토큰 자동 갱신
);

// 초기화 (기존 방식)
await kAuth.initialize();
await kAuth.initialize(autoRestore: true);

// 로그인
await kAuth.signIn(AuthProvider.kakao);
await kAuth.signIn(AuthProvider.naver);
await kAuth.signIn(AuthProvider.google);
await kAuth.signIn(AuthProvider.apple);

// 로그아웃
await kAuth.signOut();
await kAuth.signOut(AuthProvider.kakao);

// 토큰 갱신
await kAuth.refreshToken();

// 연결 해제
await kAuth.unlink(AuthProvider.kakao);

// 편의 getter (짧고 간결)
kAuth.userId      // 사용자 ID
kAuth.name        // 표시 이름
kAuth.email       // 이메일
kAuth.avatar      // 프로필 이미지

// 상태 확인
kAuth.isSignedIn
kAuth.currentUser
kAuth.currentProvider
kAuth.configuredProviders

// 토큰 상태 (v0.5.6+)
kAuth.isExpired
kAuth.isExpiringSoon()
kAuth.expiresAt
kAuth.expiresIn
```
