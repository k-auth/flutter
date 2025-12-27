#!/usr/bin/env dart
/// K-Auth CLI
///
/// Usage:
///   dart run k_auth        # Interactive setup
///   dart run k_auth doctor # Diagnose configuration

import 'dart:io';

// ═══════════════════════════════════════════════════════════════════════════
// ANSI Colors & Styles
// ═══════════════════════════════════════════════════════════════════════════

const _reset = '\x1B[0m';
const _bold = '\x1B[1m';
const _dim = '\x1B[2m';
const _green = '\x1B[32m';
const _yellow = '\x1B[33m';
const _blue = '\x1B[34m';
const _cyan = '\x1B[36m';
const _red = '\x1B[31m';
const _magenta = '\x1B[35m';

String _success(String s) => '$_green$s$_reset';
String _warning(String s) => '$_yellow$s$_reset';
String _error(String s) => '$_red$s$_reset';
String _info(String s) => '$_cyan$s$_reset';
String _hint(String s) => '$_dim$s$_reset';
String _highlight(String s) => '$_bold$_blue$s$_reset';

// ═══════════════════════════════════════════════════════════════════════════
// Main Entry
// ═══════════════════════════════════════════════════════════════════════════

void main(List<String> args) async {
  final command = args.isEmpty ? 'init' : args[0];

  switch (command) {
    case 'init':
    case 'setup':
      await runInit();
    case 'doctor':
      await runDoctor();
    case 'help':
    case '--help':
    case '-h':
      printUsage();
    case 'version':
    case '--version':
    case '-v':
      print('k_auth 0.5.0');
    default:
      print(_error('Unknown command: $command'));
      printUsage();
      exit(1);
  }
}

void printUsage() {
  print('''

$_bold$_magenta╭─────────────────────────────────────╮$_reset
$_bold$_magenta│$_reset  $_bold🔐 K-Auth CLI$_reset                      $_bold$_magenta│$_reset
$_bold$_magenta╰─────────────────────────────────────╯$_reset

$_bold Usage:$_reset  dart run k_auth [command]

$_bold Commands:$_reset
  ${_highlight('init')}      Set up K-Auth interactively ${_dim}(default)$_reset
  ${_highlight('doctor')}    Check your configuration
  ${_highlight('help')}      Show this help message

$_bold Examples:$_reset
  ${_dim}\$ dart run k_auth$_reset
  ${_dim}\$ dart run k_auth doctor$_reset
''');
}

// ═══════════════════════════════════════════════════════════════════════════
// Init Command
// ═══════════════════════════════════════════════════════════════════════════

Future<void> runInit() async {
  _printBanner();

  // Check Flutter project
  if (!File('pubspec.yaml').existsSync()) {
    print(_error('\n  ✗ Not a Flutter project'));
    print(_hint('    Run this command from your project root.\n'));
    exit(1);
  }

  print('');

  // Select providers
  final providers = await _selectProviders();
  if (providers.isEmpty) {
    print(_warning('\n  No providers selected. Exiting.\n'));
    exit(0);
  }

  print('');

  // Collect credentials
  final config = await _collectCredentials(providers);

  print('');
  print('  ${_bold}Configuring...$_reset');
  print('');

  // Apply configurations
  final results = await _applyConfigurations(config);

  // Print summary
  _printSummary(results);
}

void _printBanner() {
  print('''

$_bold$_cyan  ╦╔═  ╔═╗╦ ╦╔╦╗╦ ╦$_reset
$_bold$_cyan  ╠╩╗  ╠═╣║ ║ ║ ╠═╣$_reset
$_bold$_cyan  ╩ ╩  ╩ ╩╚═╝ ╩ ╩ ╩$_reset
''');
  print('  ${_dim}Interactive Setup$_reset');
}

Future<Set<String>> _selectProviders() async {
  print('  ${_bold}Which login providers do you want to use?$_reset');
  print('  ${_hint('(Enter numbers separated by commas, e.g., 1,2,3)')}');
  print('');
  print('    ${_cyan}1$_reset  Kakao');
  print('    ${_cyan}2$_reset  Naver');
  print('    ${_cyan}3$_reset  Google');
  print('    ${_cyan}4$_reset  Apple');
  print('');

  stdout.write('  ${_bold}›$_reset ');
  final input = stdin.readLineSync()?.trim() ?? '';

  final selected = <String>{};
  for (final part in input.split(',')) {
    final num = part.trim();
    if (num == '1') selected.add('kakao');
    if (num == '2') selected.add('naver');
    if (num == '3') selected.add('google');
    if (num == '4') selected.add('apple');
  }

  return selected;
}

Future<Map<String, String>> _collectCredentials(Set<String> providers) async {
  final config = <String, String>{};

  for (final provider in providers) {
    switch (provider) {
      case 'kakao':
        print('  ${_bold}Kakao$_reset ${_hint('(developers.kakao.com)')}');
        config['kakao_app_key'] = _prompt('Native App Key');

      case 'naver':
        print('  ${_bold}Naver$_reset ${_hint('(developers.naver.com)')}');
        config['naver_client_id'] = _prompt('Client ID');
        config['naver_client_secret'] = _prompt('Client Secret');
        config['naver_app_name'] = _prompt('App Name', required: false);

      case 'google':
        print('  ${_bold}Google$_reset ${_hint('(console.cloud.google.com)')}');
        config['google_ios_client_id'] =
            _prompt('iOS Client ID', required: false);

      case 'apple':
        print('  ${_bold}Apple$_reset');
        print('    ${_hint('No configuration needed.')}');
        print('    ${_hint('Add "Sign in with Apple" capability in Xcode.')}');
        config['apple'] = 'true';
    }
    print('');
  }

  return config;
}

String _prompt(String label, {bool required = true}) {
  stdout.write('    $label: ');
  final value = stdin.readLineSync()?.trim() ?? '';

  if (required && value.isEmpty) {
    print(_error('    ✗ This field is required'));
    return _prompt(label, required: required);
  }

  return value;
}

Future<List<_ConfigResult>> _applyConfigurations(
    Map<String, String> config) async {
  final results = <_ConfigResult>[];

  // Generate Dart config file
  final dartResult = await _generateDartConfig(config);
  results.add(dartResult);

  // Modify Android files
  if (config.containsKey('kakao_app_key') ||
      config.containsKey('naver_client_id')) {
    final androidResult = await _modifyAndroid(config);
    results.add(androidResult);
  }

  // Modify iOS files
  if (config.containsKey('kakao_app_key') ||
      config.containsKey('naver_client_id') ||
      config.containsKey('google_ios_client_id')) {
    final iosResult = await _modifyIos(config);
    results.add(iosResult);
  }

  return results;
}

void _printSummary(List<_ConfigResult> results) {
  final succeeded = results.where((r) => r.success).toList();
  final failed = results.where((r) => !r.success).toList();

  if (failed.isEmpty) {
    print('  ${_success('✓')} ${_bold}Setup complete!$_reset');
  } else {
    print('  ${_warning('!')} ${_bold}Setup completed with warnings$_reset');
  }

  print('');

  // Files modified
  if (succeeded.isNotEmpty) {
    print('  ${_dim}Modified files:$_reset');
    for (final result in succeeded) {
      print('    ${_success('✓')} ${result.file}');
    }
  }

  // Warnings
  if (failed.isNotEmpty) {
    print('');
    print('  ${_dim}Skipped:$_reset');
    for (final result in failed) {
      print('    ${_warning('!')} ${result.file}: ${result.message}');
    }
  }

  // Next steps
  print('');
  print('  ${_bold}Next steps:$_reset');
  print('');
  print('    ${_cyan}1$_reset  Review ${_highlight('lib/k_auth_config.dart')}');
  print('    ${_cyan}2$_reset  Add it to ${_highlight('.gitignore')} ${_hint('(contains API keys)')}');
  print('    ${_cyan}3$_reset  Run ${_highlight('flutter pub get')}');
  print('    ${_cyan}4$_reset  Test your app!');
  print('');
}

// ═══════════════════════════════════════════════════════════════════════════
// Doctor Command
// ═══════════════════════════════════════════════════════════════════════════

Future<void> runDoctor() async {
  print('');
  print('  ${_bold}🔍 K-Auth Doctor$_reset');
  print('');

  var issues = 0;

  // Check pubspec.yaml
  print('  ${_bold}Dependencies$_reset');
  final pubspec = File('pubspec.yaml');
  if (!pubspec.existsSync()) {
    print('    ${_error('✗')} pubspec.yaml not found');
    issues++;
  } else {
    final content = pubspec.readAsStringSync();
    if (content.contains('k_auth:')) {
      print('    ${_success('✓')} k_auth dependency found');
    } else {
      print('    ${_error('✗')} k_auth not in dependencies');
      print('      ${_hint('Run: flutter pub add k_auth')}');
      issues++;
    }
  }

  print('');

  // Check Android
  print('  ${_bold}Android$_reset');
  final androidManifest = File('android/app/src/main/AndroidManifest.xml');
  if (!androidManifest.existsSync()) {
    print('    ${_warning('!')} AndroidManifest.xml not found');
    print('      ${_hint('Run: flutter create . --platforms=android')}');
  } else {
    final content = androidManifest.readAsStringSync();
    _checkAndPrint('Kakao', content.contains('kakao'));
    _checkAndPrint('Naver', content.contains('naver'));
  }

  print('');

  // Check iOS
  print('  ${_bold}iOS$_reset');
  final infoPlist = File('ios/Runner/Info.plist');
  if (!infoPlist.existsSync()) {
    print('    ${_warning('!')} Info.plist not found');
    print('      ${_hint('Run: flutter create . --platforms=ios')}');
  } else {
    final content = infoPlist.readAsStringSync();
    _checkAndPrint('Kakao', content.contains('kakao'));
    _checkAndPrint('Naver', content.contains('naversearchapp'));
    _checkAndPrint('Google', content.contains('com.googleusercontent.apps'));
  }

  print('');

  // Check config file
  print('  ${_bold}Config$_reset');
  final configFile = File('lib/k_auth_config.dart');
  if (configFile.existsSync()) {
    print('    ${_success('✓')} lib/k_auth_config.dart found');
  } else {
    print('    ${_dim}○$_reset lib/k_auth_config.dart not found ${_hint('(optional)')}');
  }

  print('');

  // Summary
  if (issues == 0) {
    print('  ${_success('✓')} ${_bold}No issues found!$_reset');
  } else {
    print('  ${_warning('!')} ${_bold}Found $issues issue(s)$_reset');
    print('    ${_hint('Run: dart run k_auth')}');
  }

  print('');
}

void _checkAndPrint(String name, bool found) {
  if (found) {
    print('    ${_success('✓')} $name configured');
  } else {
    print('    ${_dim}○$_reset $name not configured');
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// File Modifications
// ═══════════════════════════════════════════════════════════════════════════

class _ConfigResult {
  final String file;
  final bool success;
  final String? message;

  _ConfigResult(this.file, {this.success = true, this.message});
}

Future<_ConfigResult> _generateDartConfig(Map<String, String> config) async {
  final buffer = StringBuffer();

  buffer.writeln('// Generated by: dart run k_auth');
  buffer.writeln('// Add this file to .gitignore (contains API keys)');
  buffer.writeln('');
  buffer.writeln("import 'package:k_auth/k_auth.dart';");
  buffer.writeln('');
  buffer.writeln('Future<KAuth> createKAuth() async {');
  buffer.writeln('  return await KAuth.init(');

  if (config.containsKey('kakao_app_key')) {
    buffer.writeln("    kakao: KakaoConfig(appKey: '${config['kakao_app_key']}'),");
  }

  if (config.containsKey('naver_client_id')) {
    buffer.writeln('    naver: NaverConfig(');
    buffer.writeln("      clientId: '${config['naver_client_id']}',");
    buffer.writeln("      clientSecret: '${config['naver_client_secret'] ?? ''}',");
    buffer.writeln("      appName: '${config['naver_app_name'] ?? ''}',");
    buffer.writeln('    ),');
  }

  if (config.containsKey('google_ios_client_id')) {
    final clientId = config['google_ios_client_id'];
    if (clientId != null && clientId.isNotEmpty) {
      buffer.writeln("    google: GoogleConfig(iosClientId: '$clientId'),");
    } else {
      buffer.writeln('    google: GoogleConfig(),');
    }
  }

  if (config.containsKey('apple')) {
    buffer.writeln('    apple: AppleConfig(),');
  }

  buffer.writeln('  );');
  buffer.writeln('}');

  try {
    final dir = Directory('lib');
    if (!dir.existsSync()) {
      return _ConfigResult('lib/k_auth_config.dart',
          success: false, message: 'lib/ directory not found');
    }

    File('lib/k_auth_config.dart').writeAsStringSync(buffer.toString());
    return _ConfigResult('lib/k_auth_config.dart');
  } catch (e) {
    return _ConfigResult('lib/k_auth_config.dart',
        success: false, message: e.toString());
  }
}

Future<_ConfigResult> _modifyAndroid(Map<String, String> config) async {
  final file = File('android/app/src/main/AndroidManifest.xml');
  if (!file.existsSync()) {
    return _ConfigResult('android/app/src/main/AndroidManifest.xml',
        success: false, message: 'File not found');
  }

  try {
    var content = file.readAsStringSync();
    var modified = false;

    // Add Kakao activity
    final kakaoKey = config['kakao_app_key'];
    if (kakaoKey != null && !content.contains('kakao$kakaoKey')) {
      final activity = '''
        <!-- K-Auth: Kakao Login -->
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
        '</application>',
        '$activity\n    </application>',
      );
      modified = true;
    }

    if (modified) {
      file.writeAsStringSync(content);
      return _ConfigResult('android/app/src/main/AndroidManifest.xml');
    } else {
      return _ConfigResult('android/app/src/main/AndroidManifest.xml',
          success: false, message: 'Already configured');
    }
  } catch (e) {
    return _ConfigResult('android/app/src/main/AndroidManifest.xml',
        success: false, message: e.toString());
  }
}

Future<_ConfigResult> _modifyIos(Map<String, String> config) async {
  final file = File('ios/Runner/Info.plist');
  if (!file.existsSync()) {
    return _ConfigResult('ios/Runner/Info.plist',
        success: false, message: 'File not found');
  }

  try {
    var content = file.readAsStringSync();
    var modified = false;

    // Build URL schemes
    final schemes = <String>[];
    final kakaoKey = config['kakao_app_key'];
    if (kakaoKey != null) schemes.add('kakao$kakaoKey');

    final googleClientId = config['google_ios_client_id'];
    if (googleClientId != null && googleClientId.isNotEmpty) {
      final reversed = googleClientId.split('.').reversed.join('.');
      schemes.add(reversed);
    }

    // Add URL schemes
    if (schemes.isNotEmpty && !content.contains('CFBundleURLSchemes')) {
      final urlTypes = '''
	<key>CFBundleURLTypes</key>
	<array>
		<dict>
			<key>CFBundleURLSchemes</key>
			<array>
${schemes.map((s) => '\t\t\t\t<string>$s</string>').join('\n')}
			</array>
		</dict>
	</array>''';

      final insertIndex = content.lastIndexOf('</dict>');
      if (insertIndex != -1) {
        content = '${content.substring(0, insertIndex)}$urlTypes\n${content.substring(insertIndex)}';
        modified = true;
      }
    }

    // Add LSApplicationQueriesSchemes
    if (kakaoKey != null && !content.contains('LSApplicationQueriesSchemes')) {
      final querySchemes = '''
	<key>LSApplicationQueriesSchemes</key>
	<array>
		<string>kakaokompassauth</string>
		<string>kakaolink</string>
		<string>kakaoplus</string>
		<string>naversearchapp</string>
	</array>''';

      final insertIndex = content.lastIndexOf('</dict>');
      if (insertIndex != -1) {
        content = '${content.substring(0, insertIndex)}$querySchemes\n${content.substring(insertIndex)}';
        modified = true;
      }
    }

    if (modified) {
      file.writeAsStringSync(content);
      return _ConfigResult('ios/Runner/Info.plist');
    } else {
      return _ConfigResult('ios/Runner/Info.plist',
          success: false, message: 'Already configured');
    }
  } catch (e) {
    return _ConfigResult('ios/Runner/Info.plist',
        success: false, message: e.toString());
  }
}
