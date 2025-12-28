#!/usr/bin/env dart

/// K-Auth CLI - 한국 앱을 위한 소셜 로그인 설정 도구

import 'dart:async';
import 'dart:io';

// ═══════════════════════════════════════════════════════════════════════════
// ANSI
// ═══════════════════════════════════════════════════════════════════════════

const _reset = '\x1B[0m';
const _bold = '\x1B[1m';
const _dim = '\x1B[2m';
const _green = '\x1B[32m';
const _yellow = '\x1B[33m';
const _cyan = '\x1B[36m';
const _red = '\x1B[31m';
const _magenta = '\x1B[35m';

// Cursor
const _cursorUp = '\x1B[A';
const _cursorDown = '\x1B[B';
const _cursorHide = '\x1B[?25l';
const _cursorShow = '\x1B[?25h';
const _clearLine = '\x1B[2K';

String _cursorTo(int row) => '\x1B[${row}G';
String _moveUp(int n) => '\x1B[${n}A';

// ═══════════════════════════════════════════════════════════════════════════
// Main
// ═══════════════════════════════════════════════════════════════════════════

void main(List<String> args) async {
  final cmd = args.isEmpty ? 'init' : args[0];

  switch (cmd) {
    case 'init' || 'setup':
      await _runInit();
    case 'doctor' || 'check':
      await _runDoctor();
    case 'help' || '--help' || '-h':
      _printHelp();
    case 'version' || '--version' || '-v':
      print('${_dim}k_auth $_reset${_bold}0.5.3$_reset');
    default:
      _log('error', '알 수 없는 명령어: $cmd');
      exit(1);
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Init
// ═══════════════════════════════════════════════════════════════════════════

Future<void> _runInit() async {
  print('');
  print('  $_cyan$_bold K-Auth$_reset $_dim·$_reset 소셜 로그인 설정');
  print('');

  // 프로젝트 확인
  if (!File('pubspec.yaml').existsSync()) {
    _log('error', 'Flutter 프로젝트를 찾을 수 없습니다');
    _log('hint', '프로젝트 루트 디렉토리에서 실행해주세요');
    print('');
    exit(1);
  }

  // Provider 선택 (인터랙티브)
  final providers = ['카카오', '네이버', '구글', '애플'];
  final selected = await _multiSelect(
    '로그인 방식을 선택하세요',
    providers,
  );

  if (selected.isEmpty) {
    print('');
    _log('warn', '선택된 항목이 없습니다');
    print('');
    exit(0);
  }

  print('');

  // 설정 수집
  final config = <String, String>{};

  if (selected.contains(0)) {
    _section('카카오');
    _hint('developers.kakao.com → 내 애플리케이션 → 앱 키');
    config['kakao_app_key'] = _prompt('Native App Key');
    print('');
  }

  if (selected.contains(1)) {
    _section('네이버');
    _hint('developers.naver.com → 애플리케이션 → 개요');
    config['naver_client_id'] = _prompt('Client ID');
    config['naver_client_secret'] = _prompt('Client Secret');
    config['naver_app_name'] = _prompt('앱 이름', required: false);
    print('');
  }

  if (selected.contains(2)) {
    _section('구글');
    _hint('console.cloud.google.com → OAuth 2.0 클라이언트');
    config['google_ios_client_id'] = _prompt('iOS Client ID', required: false);
    print('');
  }

  if (selected.contains(3)) {
    _section('애플');
    _hint('Xcode → Signing & Capabilities → + Sign in with Apple');
    config['apple'] = 'true';
    print('');
  }

  // 적용
  final spinner = _Spinner('설정 적용 중');
  spinner.start();

  final results = await _applyConfig(config);

  spinner.stop();

  // 결과
  final success = results.where((r) => r.ok).toList();
  final skipped = results.where((r) => !r.ok).toList();

  if (success.isNotEmpty) {
    _log('success', '완료');
    print('');
    for (final r in success) {
      print('  $_dim│$_reset  $_green●$_reset ${r.file}');
    }
  }

  if (skipped.isNotEmpty) {
    print('');
    for (final r in skipped) {
      print(
          '  $_dim│$_reset  $_dim○$_reset ${r.file} $_dim(${r.reason})$_reset');
    }
  }

  print('');
  print('  $_dim┌$_reset  다음 단계');
  print('  $_dim│$_reset');
  print(
      '  $_dim│$_reset  ${_dim}1.$_reset $_bold.gitignore$_reset에 k_auth_config.dart 추가');
  print('  $_dim│$_reset  ${_dim}2.$_reset flutter pub get');
  print('  $_dim│$_reset  ${_dim}3.$_reset 앱 실행 및 테스트');
  print('  $_dim│$_reset');
  print('  $_dim└$_reset');
  print('');
}

// ═══════════════════════════════════════════════════════════════════════════
// Interactive Multi-Select
// ═══════════════════════════════════════════════════════════════════════════

Future<Set<int>> _multiSelect(String title, List<String> options) async {
  final selected = <int>{};
  var cursor = 0;

  void render({bool final_ = false}) {
    // Move cursor up to redraw
    if (!final_) {
      stdout.write(_cursorHide);
    }

    for (var i = 0; i < options.length; i++) {
      stdout.write(_clearLine);
      final isSelected = selected.contains(i);
      final isCursor = cursor == i;

      if (final_) {
        // 최종 결과 표시
        if (isSelected) {
          print('  $_green◼$_reset  ${options[i]}');
        }
      } else {
        // 선택 중
        final checkbox = isSelected ? '$_green◼$_reset' : '$_dim◻$_reset';
        final label = isCursor ? '$_cyan${options[i]}$_reset' : options[i];
        final pointer = isCursor ? '$_cyan❯$_reset' : ' ';
        print('  $pointer $checkbox  $label');
      }
    }

    if (!final_) {
      // 안내 메시지
      stdout.write(_clearLine);
      print('');
      stdout.write(_clearLine);
      print('  $_dim↑↓ 이동  space 선택  enter 완료$_reset');

      // 커서를 다시 위로
      stdout.write(_moveUp(options.length + 2));
    }
  }

  print('  $_dim┌$_reset  $title');
  print('  $_dim│$_reset');

  // 초기 렌더링
  render();

  // Raw mode로 키 입력 받기
  stdin.echoMode = false;
  stdin.lineMode = false;

  try {
    while (true) {
      final byte = stdin.readByteSync();

      if (byte == 27) {
        // Escape sequence (화살표 키)
        final next1 = stdin.readByteSync();
        final next2 = stdin.readByteSync();

        if (next1 == 91) {
          if (next2 == 65) {
            // Up
            cursor = (cursor - 1 + options.length) % options.length;
          } else if (next2 == 66) {
            // Down
            cursor = (cursor + 1) % options.length;
          }
        }
      } else if (byte == 32) {
        // Space - 토글
        if (selected.contains(cursor)) {
          selected.remove(cursor);
        } else {
          selected.add(cursor);
        }
      } else if (byte == 13 || byte == 10) {
        // Enter - 완료
        break;
      } else if (byte == 3) {
        // Ctrl+C
        stdout.write(_cursorShow);
        exit(0);
      }

      render();
    }
  } finally {
    stdin.echoMode = true;
    stdin.lineMode = true;
    stdout.write(_cursorShow);
  }

  // 최종 결과로 다시 그리기
  for (var i = 0; i < options.length + 2; i++) {
    stdout.write(_clearLine);
    if (i < options.length + 1) stdout.write('$_cursorDown');
  }
  stdout.write(_moveUp(options.length + 2));

  render(final_: true);

  // 선택 안된 항목 수만큼 줄 정리
  final unselectedCount = options.length - selected.length;
  if (unselectedCount > 0 && selected.isNotEmpty) {
    // 이미 선택된 것만 출력됨
  } else if (selected.isEmpty) {
    stdout.write(_moveUp(options.length));
  }

  print('  $_dim└$_reset');

  return selected;
}

// ═══════════════════════════════════════════════════════════════════════════
// Doctor
// ═══════════════════════════════════════════════════════════════════════════

Future<void> _runDoctor() async {
  print('');
  print('  $_cyan$_bold K-Auth$_reset $_dim·$_reset 설정 진단');
  print('');

  var issues = 0;

  // Dependencies
  print('  $_dim┌$_reset  의존성');
  final pubspec = File('pubspec.yaml');
  if (!pubspec.existsSync()) {
    print('  $_dim│$_reset  $_red✗$_reset pubspec.yaml 없음');
    issues++;
  } else {
    final content = pubspec.readAsStringSync();
    if (content.contains('k_auth:')) {
      print('  $_dim│$_reset  $_green✓$_reset k_auth');
    } else {
      print('  $_dim│$_reset  $_red✗$_reset k_auth 미설치');
      print('  $_dim│$_reset    $_dim→ flutter pub add k_auth$_reset');
      issues++;
    }
  }
  print('  $_dim└$_reset');
  print('');

  // Android
  print('  $_dim┌$_reset  Android');
  final manifest = File('android/app/src/main/AndroidManifest.xml');
  if (!manifest.existsSync()) {
    print('  $_dim│$_reset  $_dim○$_reset AndroidManifest.xml 없음');
  } else {
    final content = manifest.readAsStringSync();
    _checkItem('카카오', content.contains('kakao'));
    _checkItem('네이버', content.contains('naver'));
  }
  print('  $_dim└$_reset');
  print('');

  // iOS
  print('  $_dim┌$_reset  iOS');
  final plist = File('ios/Runner/Info.plist');
  if (!plist.existsSync()) {
    print('  $_dim│$_reset  $_dim○$_reset Info.plist 없음');
  } else {
    final content = plist.readAsStringSync();
    _checkItem('카카오', content.contains('kakao'));
    _checkItem('네이버', content.contains('naversearchapp'));
    _checkItem('구글', content.contains('com.googleusercontent.apps'));
  }
  print('  $_dim└$_reset');
  print('');

  // Config
  print('  $_dim┌$_reset  설정 파일');
  final configFile = File('lib/k_auth_config.dart');
  if (configFile.existsSync()) {
    print('  $_dim│$_reset  $_green✓$_reset k_auth_config.dart');
  } else {
    print('  $_dim│$_reset  $_dim○$_reset k_auth_config.dart $_dim(선택)$_reset');
  }
  print('  $_dim└$_reset');
  print('');

  if (issues == 0) {
    _log('success', '문제 없음');
  } else {
    _log('warn', '$issues개 문제 발견');
    print('  $_dim│$_reset  $_dim→ dart run k_auth$_reset');
  }
  print('');
}

void _checkItem(String name, bool ok) {
  if (ok) {
    print('  $_dim│$_reset  $_green✓$_reset $name');
  } else {
    print('  $_dim│$_reset  $_dim○$_reset $name');
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Help
// ═══════════════════════════════════════════════════════════════════════════

void _printHelp() {
  print('''

  $_cyan$_bold K-Auth CLI$_reset

  ${_bold}사용법$_reset
    dart run k_auth ${_dim}[명령어]$_reset

  ${_bold}명령어$_reset
    ${_cyan}init$_reset     대화형 설정 가이드 ${_dim}(기본)$_reset
    ${_cyan}doctor$_reset   프로젝트 설정 진단
    ${_cyan}help$_reset     도움말

  ${_bold}예시$_reset
    ${_dim}\$ dart run k_auth$_reset
    ${_dim}\$ dart run k_auth doctor$_reset

''');
}

// ═══════════════════════════════════════════════════════════════════════════
// UI Helpers
// ═══════════════════════════════════════════════════════════════════════════

void _log(String type, String msg) {
  final icon = switch (type) {
    'success' => '$_green✓$_reset',
    'error' => '$_red✗$_reset',
    'warn' => '$_yellow!$_reset',
    'hint' => '$_dim→$_reset',
    _ => ' ',
  };
  print('  $icon  $msg');
}

void _section(String title) {
  print('  $_dim┌$_reset  $_bold$title$_reset');
}

void _hint(String text) {
  print('  $_dim│$_reset  $_dim$text$_reset');
}

String _prompt(String label, {bool required = true}) {
  stdout.write('  $_dim│$_reset  $label: ');
  final value = stdin.readLineSync()?.trim() ?? '';

  if (required && value.isEmpty) {
    print('  $_dim│$_reset  $_red↑ 필수 항목입니다$_reset');
    return _prompt(label, required: required);
  }

  return value;
}

// ═══════════════════════════════════════════════════════════════════════════
// Spinner
// ═══════════════════════════════════════════════════════════════════════════

class _Spinner {
  final String message;
  Timer? _timer;
  int _index = 0;
  static const _frames = ['⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏'];

  _Spinner(this.message);

  void start() {
    _timer = Timer.periodic(Duration(milliseconds: 80), (_) {
      stdout.write('\r  $_magenta${_frames[_index]}$_reset  $message');
      _index = (_index + 1) % _frames.length;
    });
  }

  void stop() {
    _timer?.cancel();
    stdout.write('\r${' ' * (message.length + 10)}\r');
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Config Generation
// ═══════════════════════════════════════════════════════════════════════════

class _Result {
  final String file;
  final bool ok;
  final String? reason;
  _Result(this.file, {this.ok = true, this.reason});
}

Future<List<_Result>> _applyConfig(Map<String, String> config) async {
  final results = <_Result>[];

  results.add(await _generateConfigFile(config));

  if (config.containsKey('kakao_app_key')) {
    results.add(await _modifyAndroid(config));
  }

  if (config.containsKey('kakao_app_key') ||
      config.containsKey('google_ios_client_id')) {
    results.add(await _modifyIos(config));
  }

  return results;
}

Future<_Result> _generateConfigFile(Map<String, String> config) async {
  final buf = StringBuffer();

  buf.writeln('// K-Auth 설정');
  buf.writeln('// 생성: dart run k_auth');
  buf.writeln('// ⚠️ .gitignore에 추가하세요');
  buf.writeln('');
  buf.writeln("import 'package:k_auth/k_auth.dart';");
  buf.writeln('');
  buf.writeln('Future<KAuth> createKAuth() async {');
  buf.writeln('  return await KAuth.init(');

  if (config.containsKey('kakao_app_key')) {
    buf.writeln(
        "    kakao: KakaoConfig(appKey: '${config['kakao_app_key']}'),");
  }
  if (config.containsKey('naver_client_id')) {
    buf.writeln('    naver: NaverConfig(');
    buf.writeln("      clientId: '${config['naver_client_id']}',");
    buf.writeln(
        "      clientSecret: '${config['naver_client_secret'] ?? ''}',");
    if (config['naver_app_name']?.isNotEmpty ?? false) {
      buf.writeln("      appName: '${config['naver_app_name']}',");
    }
    buf.writeln('    ),');
  }
  if (config.containsKey('google_ios_client_id')) {
    final id = config['google_ios_client_id'];
    if (id != null && id.isNotEmpty) {
      buf.writeln("    google: GoogleConfig(iosClientId: '$id'),");
    } else {
      buf.writeln('    google: GoogleConfig(),');
    }
  }
  if (config.containsKey('apple')) {
    buf.writeln('    apple: AppleConfig(),');
  }

  buf.writeln('  );');
  buf.writeln('}');

  try {
    if (!Directory('lib').existsSync()) {
      return _Result('lib/k_auth_config.dart', ok: false, reason: 'lib 폴더 없음');
    }
    File('lib/k_auth_config.dart').writeAsStringSync(buf.toString());
    return _Result('lib/k_auth_config.dart');
  } catch (e) {
    return _Result('lib/k_auth_config.dart', ok: false, reason: '$e');
  }
}

Future<_Result> _modifyAndroid(Map<String, String> config) async {
  final file = File('android/app/src/main/AndroidManifest.xml');
  if (!file.existsSync()) {
    return _Result('AndroidManifest.xml', ok: false, reason: '파일 없음');
  }

  try {
    var content = file.readAsStringSync();
    final kakaoKey = config['kakao_app_key'];

    if (kakaoKey != null && !content.contains('kakao$kakaoKey')) {
      final activity = '''
        <!-- K-Auth: 카카오 -->
        <activity
            android:name="com.kakao.sdk.flutter.AuthCodeHandlerActivity"
            android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.VIEW" />
                <category android:name="android.intent.category.DEFAULT" />
                <category android:name="android.intent.category.BROWSABLE" />
                <data android:scheme="kakao$kakaoKey" android:host="oauth" />
            </intent-filter>
        </activity>''';

      content = content.replaceFirst(
          '</application>', '$activity\n    </application>');
      file.writeAsStringSync(content);
      return _Result('AndroidManifest.xml');
    }

    return _Result('AndroidManifest.xml', ok: false, reason: '이미 설정됨');
  } catch (e) {
    return _Result('AndroidManifest.xml', ok: false, reason: '$e');
  }
}

Future<_Result> _modifyIos(Map<String, String> config) async {
  final file = File('ios/Runner/Info.plist');
  if (!file.existsSync()) {
    return _Result('Info.plist', ok: false, reason: '파일 없음');
  }

  try {
    var content = file.readAsStringSync();
    var modified = false;

    // URL Schemes
    final schemes = <String>[];
    final kakaoKey = config['kakao_app_key'];
    if (kakaoKey != null) schemes.add('kakao$kakaoKey');

    final googleId = config['google_ios_client_id'];
    if (googleId != null && googleId.isNotEmpty) {
      schemes.add(googleId.split('.').reversed.join('.'));
    }

    if (schemes.isNotEmpty && !content.contains('CFBundleURLSchemes')) {
      final xml = '''
	<key>CFBundleURLTypes</key>
	<array>
		<dict>
			<key>CFBundleURLSchemes</key>
			<array>
${schemes.map((s) => '\t\t\t\t<string>$s</string>').join('\n')}
			</array>
		</dict>
	</array>''';

      final i = content.lastIndexOf('</dict>');
      if (i != -1) {
        content = '${content.substring(0, i)}$xml\n${content.substring(i)}';
        modified = true;
      }
    }

    // Query Schemes
    if (kakaoKey != null && !content.contains('LSApplicationQueriesSchemes')) {
      final xml = '''
	<key>LSApplicationQueriesSchemes</key>
	<array>
		<string>kakaokompassauth</string>
		<string>kakaolink</string>
		<string>kakaoplus</string>
		<string>naversearchapp</string>
	</array>''';

      final i = content.lastIndexOf('</dict>');
      if (i != -1) {
        content = '${content.substring(0, i)}$xml\n${content.substring(i)}';
        modified = true;
      }
    }

    if (modified) {
      file.writeAsStringSync(content);
      return _Result('Info.plist');
    }

    return _Result('Info.plist', ok: false, reason: '이미 설정됨');
  } catch (e) {
    return _Result('Info.plist', ok: false, reason: '$e');
  }
}
