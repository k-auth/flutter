#!/usr/bin/env dart
// ignore_for_file: avoid_print

/// K-Auth CLI - 설정 진단 도구
library;

import 'dart:io';

// ═══════════════════════════════════════════════════════════════════════════
// ANSI Colors
// ═══════════════════════════════════════════════════════════════════════════

const _reset = '\x1B[0m';
const _bold = '\x1B[1m';
const _dim = '\x1B[2m';
const _green = '\x1B[32m';
const _yellow = '\x1B[33m';
const _red = '\x1B[31m';
const _cyan = '\x1B[36m';

// ═══════════════════════════════════════════════════════════════════════════
// Main
// ═══════════════════════════════════════════════════════════════════════════

void main(List<String> args) {
  final cmd = args.isEmpty ? 'doctor' : args[0];

  switch (cmd) {
    case 'doctor' || 'check' || '':
      _runDoctor();
    case 'help' || '--help' || '-h':
      _printHelp();
    case 'version' || '--version' || '-v':
      _printVersion();
    default:
      print('');
      print('  $_red✗$_reset  알 수 없는 명령어: $cmd');
      print('     $_dim→ dart run k_auth help$_reset');
      print('');
      exit(1);
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Doctor
// ═══════════════════════════════════════════════════════════════════════════

void _runDoctor() {
  print('');
  print('  $_bold$_cyan K-Auth$_reset 설정 진단');
  print('');

  // 프로젝트 확인
  if (!File('pubspec.yaml').existsSync()) {
    print('  $_red✗$_reset  Flutter 프로젝트 폴더에서 실행해주세요');
    print('');
    print('     ${_dim}cd your_flutter_project$_reset');
    print('     ${_dim}dart run k_auth$_reset');
    print('');
    exit(1);
  }

  final results = <_CheckResult>[];

  // 패키지 체크
  results.add(_checkPackage());

  // 플랫폼 파일 읽기
  final androidManifest = _readFile('android/app/src/main/AndroidManifest.xml');
  final infoPlist = _readFile('ios/Runner/Info.plist');

  // 플랫폼 폴더 존재 여부
  final hasAndroid = androidManifest != null;
  final hasIos = infoPlist != null;

  if (!hasAndroid && !hasIos) {
    results.add(_CheckResult(
      category: '플랫폼',
      name: 'Android / iOS',
      ok: false,
      guide: _Guide(
        what: 'Android, iOS 폴더가 없습니다',
        how: '터미널에서 다음 명령어를 실행하세요',
        code: 'flutter create .',
      ),
    ));
  }

  // Provider별 체크
  if (hasAndroid || hasIos) {
    results.addAll(_checkKakao(androidManifest, infoPlist));
    results.addAll(_checkNaver(androidManifest, infoPlist));
    results.addAll(_checkGoogle(androidManifest, infoPlist));
    results.addAll(_checkApple(infoPlist));
  }

  // 결과 출력
  _printResults(results);
}

// ═══════════════════════════════════════════════════════════════════════════
// Checks
// ═══════════════════════════════════════════════════════════════════════════

_CheckResult _checkPackage() {
  final pubspec = File('pubspec.yaml');
  final content = pubspec.readAsStringSync();

  if (content.contains('k_auth:')) {
    return _CheckResult(
      category: '패키지',
      name: 'k_auth',
      ok: true,
    );
  }

  return _CheckResult(
    category: '패키지',
    name: 'k_auth',
    ok: false,
    guide: _Guide(
      what: 'k_auth 패키지가 설치되지 않았습니다',
      how: '터미널에서 다음 명령어를 실행하세요',
      code: 'flutter pub add k_auth',
    ),
  );
}

List<_CheckResult> _checkKakao(String? android, String? ios) {
  final results = <_CheckResult>[];

  // Android
  if (android != null) {
    final hasKakao = android.contains('kakao') &&
        android.contains('AuthCodeHandlerActivity');

    results.add(_CheckResult(
      category: '카카오',
      name: 'Android',
      ok: hasKakao,
      guide: hasKakao
          ? null
          : _Guide(
              what: '카카오 로그인을 위한 Android 설정이 필요합니다',
              where: 'android/app/src/main/AndroidManifest.xml',
              how: '<application> 태그 안에 아래 코드를 붙여넣기',
              code: '''
<activity
    android:name="com.kakao.sdk.flutter.AuthCodeHandlerActivity"
    android:exported="true">
    <intent-filter>
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />
        <data android:scheme="kakao{앱키}" android:host="oauth" />
    </intent-filter>
</activity>''',
              tip: '{앱키} 부분을 카카오 Native App Key로 교체하세요\n'
                  '      앱키 확인: developers.kakao.com → 내 애플리케이션 → 앱 키',
            ),
    ));
  }

  // iOS
  if (ios != null) {
    final hasUrlScheme = ios.contains('kakao');
    final hasQueryScheme = ios.contains('kakaokompassauth');
    final ok = hasUrlScheme && hasQueryScheme;

    results.add(_CheckResult(
      category: '카카오',
      name: 'iOS',
      ok: ok,
      guide: ok
          ? null
          : _Guide(
              what: '카카오 로그인을 위한 iOS 설정이 필요합니다',
              where: 'ios/Runner/Info.plist',
              how: '</dict> 바로 위에 아래 코드를 붙여넣기',
              code: '''
<key>LSApplicationQueriesSchemes</key>
<array>
    <string>kakaokompassauth</string>
    <string>kakaolink</string>
</array>
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>kakao{앱키}</string>
        </array>
    </dict>
</array>''',
              tip: '{앱키} 부분을 카카오 Native App Key로 교체하세요',
            ),
    ));
  }

  return results;
}

List<_CheckResult> _checkNaver(String? android, String? ios) {
  final results = <_CheckResult>[];

  // Android
  if (android != null) {
    results.add(_CheckResult(
      category: '네이버',
      name: 'Android',
      ok: true,
    ));
  }

  // iOS
  if (ios != null) {
    final hasQueryScheme = ios.contains('naversearchapp');

    results.add(_CheckResult(
      category: '네이버',
      name: 'iOS',
      ok: hasQueryScheme,
      guide: hasQueryScheme
          ? null
          : _Guide(
              what: '네이버 로그인을 위한 iOS 설정이 필요합니다',
              where: 'ios/Runner/Info.plist',
              how: '</dict> 바로 위에 아래 코드를 붙여넣기',
              code: '''
<key>LSApplicationQueriesSchemes</key>
<array>
    <string>naversearchapp</string>
    <string>naversearchthirdlogin</string>
</array>
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>{URL스킴}</string>
        </array>
    </dict>
</array>''',
              tip: '{URL스킴}은 네이버 개발자센터에서 설정한 값입니다\n'
                  '      확인: developers.naver.com → 애플리케이션 → API 설정',
            ),
    ));
  }

  return results;
}

List<_CheckResult> _checkGoogle(String? android, String? ios) {
  final results = <_CheckResult>[];

  // Android
  if (android != null) {
    final hasGoogleServices =
        File('android/app/google-services.json').existsSync();

    results.add(_CheckResult(
      category: '구글',
      name: 'Android',
      ok: hasGoogleServices,
      guide: hasGoogleServices
          ? null
          : _Guide(
              what: '구글 로그인을 위한 설정 파일이 필요합니다',
              where: 'android/app/google-services.json',
              how: '파일을 다운로드하여 위 경로에 저장하세요',
              tip: '다운로드: console.firebase.google.com\n'
                  '      → 프로젝트 설정 → Android 앱 → google-services.json',
            ),
    ));
  }

  // iOS
  if (ios != null) {
    final hasGoogleScheme = ios.contains('com.googleusercontent.apps');

    results.add(_CheckResult(
      category: '구글',
      name: 'iOS',
      ok: hasGoogleScheme,
      guide: hasGoogleScheme
          ? null
          : _Guide(
              what: '구글 로그인을 위한 iOS 설정이 필요합니다',
              where: 'ios/Runner/Info.plist',
              how: '</dict> 바로 위에 아래 코드를 붙여넣기',
              code: '''
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>com.googleusercontent.apps.{클라이언트ID}</string>
        </array>
    </dict>
</array>''',
              tip: '{클라이언트ID}는 Firebase/GCP 콘솔에서 확인하세요\n'
                  '      iOS 클라이언트 ID의 앞부분 (숫자-문자.apps... 형식)',
            ),
    ));
  }

  return results;
}

List<_CheckResult> _checkApple(String? ios) {
  final results = <_CheckResult>[];

  if (ios == null) return results;

  final entitlements = _readFile('ios/Runner/Runner.entitlements');
  final hasApple =
      entitlements?.contains('com.apple.developer.applesignin') ?? false;

  results.add(_CheckResult(
    category: '애플',
    name: 'iOS',
    ok: hasApple,
    guide: hasApple
        ? null
        : _Guide(
            what: '애플 로그인을 위한 설정이 필요합니다',
            how: 'Xcode에서 설정해야 합니다 (코드 수정 아님)',
            code: '''
1. Xcode로 ios/Runner.xcworkspace 열기
2. 왼쪽에서 Runner 선택
3. Signing & Capabilities 탭 클릭
4. + Capability 버튼 클릭
5. "Sign in with Apple" 검색 후 추가''',
            tip: '시뮬레이터에서는 테스트 불가, 실제 기기 필요',
          ),
  ));

  return results;
}

// ═══════════════════════════════════════════════════════════════════════════
// Output
// ═══════════════════════════════════════════════════════════════════════════

void _printResults(List<_CheckResult> results) {
  final grouped = <String, List<_CheckResult>>{};
  for (final r in results) {
    grouped.putIfAbsent(r.category, () => []).add(r);
  }

  var hasIssues = false;
  final issues = <_CheckResult>[];

  // 상태 출력
  for (final category in grouped.keys) {
    final items = grouped[category]!;
    print('  $_bold$category$_reset');

    for (final item in items) {
      if (item.ok) {
        print('    $_green✓$_reset ${item.name}');
      } else {
        print('    $_red✗$_reset ${item.name}');
        hasIssues = true;
        if (item.guide != null) issues.add(item);
      }
    }
    print('');
  }

  // 해결 가이드 출력
  if (issues.isNotEmpty) {
    print('  $_cyan$_bold━━━ 해결 방법 ━━━$_reset');
    print('');

    for (var i = 0; i < issues.length; i++) {
      final issue = issues[i];
      final guide = issue.guide!;
      final num = i + 1;

      print('  $_yellow$num. ${issue.category} ${issue.name}$_reset');
      print('');
      print('     ${guide.what}');
      if (guide.where != null) {
        print('');
        print('     $_dim파일:$_reset ${guide.where}');
      }
      print('');
      print('     $_dim방법:$_reset ${guide.how}');

      if (guide.code != null) {
        print('');
        print('     $_dim┌──────────────────────────────────────$_reset');
        for (final line in guide.code!.split('\n')) {
          print('     $_dim│$_reset $line');
        }
        print('     $_dim└──────────────────────────────────────$_reset');
      }

      if (guide.tip != null) {
        print('');
        print('     $_dim💡 ${guide.tip}$_reset');
      }

      if (i < issues.length - 1) {
        print('');
        print('  $_dim───────────────────────────────────────────$_reset');
      }
      print('');
    }
  }

  // 요약
  print('  ─────────────────────────────────────────');
  if (hasIssues) {
    final count = issues.length;
    print('  $_yellow⚠$_reset  $count개 설정이 필요합니다');
    print('     $_dim위 가이드를 따라 설정해주세요$_reset');
  } else {
    print('  $_green✓$_reset  모든 설정이 완료되었습니다!');
  }
  print('');
}

// ═══════════════════════════════════════════════════════════════════════════
// Help
// ═══════════════════════════════════════════════════════════════════════════

void _printHelp() {
  print('''

  $_bold$_cyan K-Auth CLI$_reset - 소셜 로그인 설정 도우미

  $_bold사용법$_reset
    dart run k_auth

  $_bold명령어$_reset
    ${_cyan}doctor$_reset    현재 설정 상태 확인 $_dim(기본)$_reset
    ${_cyan}help$_reset      이 도움말 보기
    ${_cyan}version$_reset   버전 확인

  $_bold문제가 있나요?$_reset
    $_dim→ https://github.com/user/k-auth/issues$_reset

''');
}

void _printVersion() {
  final version = _getVersion();
  print('');
  print('  $_bold$_cyan K-Auth$_reset ${_dim}v$_reset$_bold$version$_reset');
  print('');
}

String _getVersion() {
  final content = _readFile('pubspec.yaml');
  if (content != null) {
    final match =
        RegExp(r'^version:\s*(.+)$', multiLine: true).firstMatch(content);
    if (match != null) return match.group(1)!.trim();
  }
  return '0.8.2'; // fallback
}

// ═══════════════════════════════════════════════════════════════════════════
// Helpers
// ═══════════════════════════════════════════════════════════════════════════

String? _readFile(String path) {
  final file = File(path);
  if (!file.existsSync()) return null;
  return file.readAsStringSync();
}

class _Guide {
  final String what;
  final String? where;
  final String how;
  final String? code;
  final String? tip;

  _Guide({
    required this.what,
    this.where,
    required this.how,
    this.code,
    this.tip,
  });
}

class _CheckResult {
  final String category;
  final String name;
  final bool ok;
  final _Guide? guide;

  _CheckResult({
    required this.category,
    required this.name,
    required this.ok,
    this.guide,
  });
}
