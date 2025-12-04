# Contributing to K-Auth

K-Auth에 기여해 주셔서 감사합니다!

## 개발 환경 설정

```bash
# 저장소 클론
git clone https://github.com/k-auth/flutter.git
cd flutter

# 의존성 설치
flutter pub get

# 테스트 실행
flutter test

# 분석 실행
dart analyze
```

## Pull Request 가이드

1. 이슈를 먼저 생성해 주세요
2. `main` 브랜치에서 새 브랜치를 생성하세요
3. 변경사항을 커밋하세요
4. 테스트를 추가/수정하세요
5. `flutter test`와 `dart analyze`가 통과하는지 확인하세요
6. Pull Request를 생성하세요

## 커밋 메시지

[Conventional Commits](https://www.conventionalcommits.org/) 형식을 따릅니다:

```
feat: 새 기능 추가
fix: 버그 수정
docs: 문서 수정
test: 테스트 추가/수정
refactor: 리팩토링
chore: 기타 변경
```

## 코드 스타일

- `dart format .`으로 포맷팅
- `dart analyze`에서 경고 없어야 함
- 모든 public API에 dartdoc 주석 필수

## 테스트

새 기능 추가 시 테스트도 함께 추가해 주세요:

```bash
flutter test
```

## 질문

질문이 있으시면 [이슈](https://github.com/k-auth/flutter/issues)를 등록해 주세요.
