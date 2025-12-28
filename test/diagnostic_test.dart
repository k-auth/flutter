import 'package:flutter_test/flutter_test.dart';
import 'package:k_auth/k_auth.dart';

void main() {
  // ============================================
  // DiagnosticSeverity 테스트
  // ============================================
  group('DiagnosticSeverity', () {
    test('모든 심각도가 존재한다', () {
      expect(DiagnosticSeverity.values, contains(DiagnosticSeverity.error));
      expect(DiagnosticSeverity.values, contains(DiagnosticSeverity.warning));
      expect(DiagnosticSeverity.values, contains(DiagnosticSeverity.info));
      expect(DiagnosticSeverity.values.length, 3);
    });
  });

  // ============================================
  // DiagnosticIssue 테스트
  // ============================================
  group('DiagnosticIssue', () {
    group('toString', () {
      test('error 심각도', () {
        const issue = DiagnosticIssue(
          severity: DiagnosticSeverity.error,
          message: '에러 메시지',
        );

        final str = issue.toString();
        expect(str, contains('❌'));
        expect(str, contains('에러 메시지'));
      });

      test('warning 심각도', () {
        const issue = DiagnosticIssue(
          severity: DiagnosticSeverity.warning,
          message: '경고 메시지',
        );

        final str = issue.toString();
        expect(str, contains('⚠️'));
        expect(str, contains('경고 메시지'));
      });

      test('info 심각도', () {
        const issue = DiagnosticIssue(
          severity: DiagnosticSeverity.info,
          message: '정보 메시지',
        );

        final str = issue.toString();
        expect(str, contains('ℹ️'));
        expect(str, contains('정보 메시지'));
      });

      test('provider가 있는 경우', () {
        const issue = DiagnosticIssue(
          provider: AuthProvider.kakao,
          severity: DiagnosticSeverity.error,
          message: '에러',
        );

        final str = issue.toString();
        expect(str, contains('[카카오]'));
      });

      test('provider가 없는 경우', () {
        const issue = DiagnosticIssue(
          severity: DiagnosticSeverity.info,
          message: '정보 메시지',
        );

        final str = issue.toString();
        expect(str, isNot(contains('[')));
      });
    });

    test('solution 저장', () {
      const issue = DiagnosticIssue(
        severity: DiagnosticSeverity.error,
        message: '에러',
        solution: '이렇게 해결하세요',
      );

      expect(issue.solution, '이렇게 해결하세요');
    });

    test('docUrl 저장', () {
      const issue = DiagnosticIssue(
        severity: DiagnosticSeverity.error,
        message: '에러 메시지',
        docUrl: 'https://docs.example.com',
      );

      expect(issue.docUrl, 'https://docs.example.com');
    });
  });

  // ============================================
  // DiagnosticResult 테스트
  // ============================================
  group('DiagnosticResult', () {
    group('hasErrors', () {
      test('에러가 있으면 true', () {
        final result = DiagnosticResult(
          issues: const [
            DiagnosticIssue(
              severity: DiagnosticSeverity.error,
              message: '에러',
            ),
          ],
          timestamp: DateTime.now(),
          platform: 'ios',
        );

        expect(result.hasErrors, true);
      });

      test('에러가 없으면 false', () {
        final result = DiagnosticResult(
          issues: const [
            DiagnosticIssue(
              severity: DiagnosticSeverity.warning,
              message: '경고',
            ),
          ],
          timestamp: DateTime.now(),
          platform: 'ios',
        );

        expect(result.hasErrors, false);
      });
    });

    group('hasWarnings', () {
      test('경고가 있으면 true', () {
        final result = DiagnosticResult(
          issues: const [
            DiagnosticIssue(
              severity: DiagnosticSeverity.warning,
              message: '경고',
            ),
          ],
          timestamp: DateTime.now(),
          platform: 'ios',
        );

        expect(result.hasWarnings, true);
      });

      test('경고가 없으면 false', () {
        final result = DiagnosticResult(
          issues: const [
            DiagnosticIssue(
              severity: DiagnosticSeverity.info,
              message: '정보',
            ),
          ],
          timestamp: DateTime.now(),
          platform: 'ios',
        );

        expect(result.hasWarnings, false);
      });
    });

    group('isHealthy', () {
      test('에러가 없으면 true', () {
        final result = DiagnosticResult(
          issues: const [
            DiagnosticIssue(
              severity: DiagnosticSeverity.info,
              message: '정보',
            ),
          ],
          timestamp: DateTime.now(),
          platform: 'ios',
        );

        expect(result.isHealthy, true);
      });

      test('에러가 있으면 false', () {
        final result = DiagnosticResult(
          issues: const [
            DiagnosticIssue(
              severity: DiagnosticSeverity.error,
              message: '에러',
            ),
          ],
          timestamp: DateTime.now(),
          platform: 'ios',
        );

        expect(result.isHealthy, false);
      });

      test('이슈가 없으면 true', () {
        final result = DiagnosticResult(
          issues: const [],
          timestamp: DateTime.now(),
          platform: 'ios',
        );

        expect(result.isHealthy, true);
      });
    });

    group('errors/warnings 필터링', () {
      test('errors가 에러만 필터링', () {
        final result = DiagnosticResult(
          issues: const [
            DiagnosticIssue(
              severity: DiagnosticSeverity.error,
              message: '에러1',
            ),
            DiagnosticIssue(
              severity: DiagnosticSeverity.warning,
              message: '경고',
            ),
            DiagnosticIssue(
              severity: DiagnosticSeverity.error,
              message: '에러2',
            ),
          ],
          timestamp: DateTime.now(),
          platform: 'ios',
        );

        expect(result.errors.length, 2);
        expect(
            result.errors.every((i) => i.severity == DiagnosticSeverity.error),
            true);
      });

      test('warnings가 경고만 필터링', () {
        final result = DiagnosticResult(
          issues: const [
            DiagnosticIssue(
              severity: DiagnosticSeverity.error,
              message: '에러',
            ),
            DiagnosticIssue(
              severity: DiagnosticSeverity.warning,
              message: '경고1',
            ),
            DiagnosticIssue(
              severity: DiagnosticSeverity.warning,
              message: '경고2',
            ),
          ],
          timestamp: DateTime.now(),
          platform: 'ios',
        );

        expect(result.warnings.length, 2);
        expect(
            result.warnings
                .every((i) => i.severity == DiagnosticSeverity.warning),
            true);
      });
    });

    group('prettyPrint', () {
      test('이슈가 없을 때', () {
        final result = DiagnosticResult(
          issues: const [],
          timestamp: DateTime.now(),
          platform: 'ios',
        );

        final output = result.prettyPrint();
        expect(output, contains('모든 설정이 정상입니다'));
      });

      test('solution을 포함한다', () {
        final result = DiagnosticResult(
          issues: const [
            DiagnosticIssue(
              severity: DiagnosticSeverity.warning,
              message: '경고 메시지',
              solution: '이렇게 해결하세요',
            ),
          ],
          timestamp: DateTime.now(),
          platform: 'android',
        );

        final output = result.prettyPrint();
        expect(output, contains('이렇게 해결하세요'));
        expect(output, contains('💡 해결:'));
      });

      test('docUrl을 포함한다', () {
        final result = DiagnosticResult(
          issues: const [
            DiagnosticIssue(
              severity: DiagnosticSeverity.error,
              message: '에러',
              docUrl: 'https://example.com/docs',
            ),
          ],
          timestamp: DateTime.now(),
          platform: 'ios',
        );

        final output = result.prettyPrint();
        expect(output, contains('📖 문서:'));
        expect(output, contains('https://example.com/docs'));
      });

      test('플랫폼 정보를 포함한다', () {
        final result = DiagnosticResult(
          issues: const [],
          timestamp: DateTime.now(),
          platform: 'android',
        );

        final output = result.prettyPrint();
        expect(output, contains('플랫폼: android'));
      });

      test('이슈 개수를 표시한다', () {
        final result = DiagnosticResult(
          issues: const [
            DiagnosticIssue(
              severity: DiagnosticSeverity.error,
              message: '에러',
            ),
            DiagnosticIssue(
              severity: DiagnosticSeverity.warning,
              message: '경고',
            ),
          ],
          timestamp: DateTime.now(),
          platform: 'ios',
        );

        final output = result.prettyPrint();
        expect(output, contains('발견된 문제: 2개'));
        expect(output, contains('에러: 1개'));
        expect(output, contains('경고: 1개'));
      });
    });
  });
}
