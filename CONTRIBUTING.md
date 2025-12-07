# Contributing to K-Auth

K-Auth에 기여해 주셔서 감사합니다!

## 시작하기 전에

- 기존 [이슈](https://github.com/k-auth/flutter/issues)를 확인해서 중복된 이슈가 있는지 확인해주세요
- 큰 변경사항은 먼저 이슈를 생성해서 논의해주세요

## 개발 환경 설정

```bash
# 저장소 클론
git clone https://github.com/k-auth/flutter.git
cd flutter

# 의존성 설치
flutter pub get

# 테스트 실행
flutter test

# 정적 분석
dart analyze

# 포맷팅
dart format .
```

## 이슈 등록

### 버그 리포트
- 재현 가능한 최소한의 코드 예시를 포함해주세요
- Flutter/Dart 버전, OS, Provider 종류를 명시해주세요
- 에러 메시지 전체를 포함해주세요

### 기능 제안
- 왜 이 기능이 필요한지 설명해주세요
- 가능하다면 API 디자인 예시를 포함해주세요

## Pull Request 가이드

### 1. 브랜치 생성

```bash
git checkout -b feat/your-feature
# 또는
git checkout -b fix/your-bugfix
```

### 2. 개발

- 코드 스타일 가이드를 따라주세요
- 테스트를 추가해주세요
- dartdoc 주석을 작성해주세요

### 3. 커밋

[Conventional Commits](https://www.conventionalcommits.org/) 형식을 따릅니다:

```bash
feat: 새 기능 추가
fix: 버그 수정
docs: 문서 수정
test: 테스트 추가/수정
refactor: 리팩토링
chore: 기타 변경
```

예시:
```bash
git commit -m "feat: Apple 로그인에 nonce 지원 추가"
git commit -m "fix: 카카오 로그인 취소 시 에러 처리"
git commit -m "docs: README에 트러블슈팅 섹션 추가"
```

### 4. PR 생성 전 체크리스트

- [ ] `flutter test` 통과
- [ ] `dart analyze` 경고 없음
- [ ] `dart format .` 적용
- [ ] 새 public API에 dartdoc 주석 작성
- [ ] CHANGELOG.md 업데이트 (필요한 경우)

### 5. PR 생성

- PR 템플릿을 따라 작성해주세요
- 관련 이슈를 링크해주세요 (`Fixes #123`)
- 스크린샷이나 GIF가 있으면 좋습니다

## 코드 스타일

### Dart 스타일
- [Effective Dart](https://dart.dev/guides/language/effective-dart) 가이드 준수
- `dart format .`으로 포맷팅
- `dart analyze`에서 경고 없어야 함

### 주석
- 모든 public API에 dartdoc 주석 필수
- 한글 주석 사용 권장

```dart
/// 카카오 로그인을 실행합니다.
///
/// [scopes]에 추가 scope를 지정할 수 있습니다.
///
/// ```dart
/// final result = await kAuth.signInWithKakao();
/// ```
Future<AuthResult> signInWithKakao() async {
  // ...
}
```

### 네이밍
- 클래스: `PascalCase`
- 함수/변수: `camelCase`
- 상수: `camelCase` (Dart 권장)
- 파일: `snake_case.dart`

## 테스트 작성

```bash
# 전체 테스트
flutter test

# 특정 파일
flutter test test/k_auth_test.dart

# 커버리지 리포트 생성
flutter test --coverage

# 커버리지 HTML 보기 (macOS)
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

테스트 파일은 `test/` 디렉토리에 위치하며, `_test.dart` 접미사를 사용합니다.

### 테스트 구조

```
test/
├── k_auth_test.dart      # KAuth 메인 클래스 및 AuthResult 테스트
├── provider_test.dart    # KAuthUser.fromXxx 파싱 테스트
├── error_test.dart       # 에러 시나리오 테스트
└── widgets_test.dart     # 로그인 버튼 위젯 테스트
```

## CI/CD

### GitHub Actions

PR을 생성하면 자동으로 다음이 실행됩니다:

1. **Analyze & Test**: `dart format`, `dart analyze`, `flutter test`
2. **Build Example**: Android APK 빌드 테스트
3. **Coverage**: Codecov로 커버리지 리포트 업로드

### Codecov 설정 (메인테이너용)

커버리지 배지가 동작하려면 GitHub Secrets에 `CODECOV_TOKEN`을 추가해야 합니다:

1. [Codecov](https://codecov.io)에서 GitHub으로 로그인
2. `k-auth/flutter` 저장소 추가
3. Settings > Repository Upload Token 복사
4. GitHub 저장소 > Settings > Secrets and variables > Actions
5. `CODECOV_TOKEN` 시크릿 추가

```yaml
# .github/workflows/ci.yml 에서 사용됨
- name: Upload coverage to Codecov
  uses: codecov/codecov-action@v4
  with:
    files: coverage/lcov.info
  env:
    CODECOV_TOKEN: ${{ secrets.CODECOV_TOKEN }}
```

### 자동 배포 (pub.dev)

`v*` 태그를 push하면 자동으로 pub.dev에 배포됩니다:

```bash
# 버전 업데이트 후
git tag v0.5.0
git push --tags
```

**주의**: pub.dev 자동 배포를 위해 OIDC 인증 설정이 필요합니다:
1. https://pub.dev 에서 패키지 관리 페이지 이동
2. "Automated publishing" 활성화
3. GitHub 저장소 연결

## 문서 작성

- README.md: 사용자를 위한 빠른 시작 가이드
- dartdoc: API 레퍼런스 (코드 내 주석)
- example/: 동작하는 예제 코드

## Good First Issues

처음 기여하시는 분은 [`good first issue`](https://github.com/k-auth/flutter/labels/good%20first%20issue) 라벨이 붙은 이슈를 확인해주세요.

## 질문

- [GitHub Issues](https://github.com/k-auth/flutter/issues)에 질문을 남겨주세요
- `question` 라벨을 사용해주세요

## 라이선스

기여하신 코드는 [MIT License](LICENSE)로 배포됩니다.
