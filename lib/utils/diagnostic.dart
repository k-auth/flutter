import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/auth_config.dart';
import '../models/auth_result.dart';

/// 진단 결과 심각도
enum DiagnosticSeverity {
  /// 에러 - 반드시 수정 필요
  error,

  /// 경고 - 권장 수정
  warning,

  /// 정보 - 참고용
  info,
}

/// 진단 결과 항목
class DiagnosticIssue {
  /// Provider
  final AuthProvider? provider;

  /// 심각도
  final DiagnosticSeverity severity;

  /// 문제 설명
  final String message;

  /// 해결 방법
  final String? solution;

  /// 관련 문서 링크
  final String? docUrl;

  const DiagnosticIssue({
    this.provider,
    required this.severity,
    required this.message,
    this.solution,
    this.docUrl,
  });

  @override
  String toString() {
    final prefix = switch (severity) {
      DiagnosticSeverity.error => '❌',
      DiagnosticSeverity.warning => '⚠️',
      DiagnosticSeverity.info => 'ℹ️',
    };
    final providerStr = provider != null ? '[${provider!.displayName}] ' : '';
    return '$prefix $providerStr$message';
  }
}

/// 진단 결과
class DiagnosticResult {
  /// 발견된 문제들
  final List<DiagnosticIssue> issues;

  /// 진단 시간
  final DateTime timestamp;

  /// 플랫폼 정보
  final String platform;

  const DiagnosticResult({
    required this.issues,
    required this.timestamp,
    required this.platform,
  });

  /// 에러가 있는지 확인
  bool get hasErrors =>
      issues.any((i) => i.severity == DiagnosticSeverity.error);

  /// 경고가 있는지 확인
  bool get hasWarnings =>
      issues.any((i) => i.severity == DiagnosticSeverity.warning);

  /// 모든 검사 통과
  bool get isHealthy => !hasErrors;

  /// 에러만 필터링
  List<DiagnosticIssue> get errors =>
      issues.where((i) => i.severity == DiagnosticSeverity.error).toList();

  /// 경고만 필터링
  List<DiagnosticIssue> get warnings =>
      issues.where((i) => i.severity == DiagnosticSeverity.warning).toList();

  /// 보기 좋게 출력
  String prettyPrint() {
    final buffer = StringBuffer();
    buffer.writeln('═══════════════════════════════════════');
    buffer.writeln('  K-Auth 진단 결과');
    buffer.writeln('═══════════════════════════════════════');
    buffer.writeln('플랫폼: $platform');
    buffer.writeln('시간: $timestamp');
    buffer.writeln('');

    if (issues.isEmpty) {
      buffer.writeln('✅ 모든 설정이 정상입니다!');
    } else {
      buffer.writeln('발견된 문제: ${issues.length}개');
      buffer.writeln('  - 에러: ${errors.length}개');
      buffer.writeln('  - 경고: ${warnings.length}개');
      buffer.writeln('');

      for (final issue in issues) {
        buffer.writeln(issue.toString());
        if (issue.solution != null) {
          buffer.writeln('   💡 해결: ${issue.solution}');
        }
        if (issue.docUrl != null) {
          buffer.writeln('   📖 문서: ${issue.docUrl}');
        }
        buffer.writeln('');
      }
    }

    buffer.writeln('═══════════════════════════════════════');
    return buffer.toString();
  }
}

/// K-Auth 설정 진단 도구
///
/// 네이티브 설정이 올바른지 검증합니다.
///
/// ```dart
/// final result = await KAuthDiagnostic.run(kAuth.config);
/// if (result.hasErrors) {
///   print(result.prettyPrint());
/// }
/// ```
class KAuthDiagnostic {
  KAuthDiagnostic._();

  /// 진단 실행
  ///
  /// [config]: KAuth 설정
  /// [verbose]: 상세 정보 포함 여부
  static Future<DiagnosticResult> run(
    KAuthConfig config, {
    bool verbose = false,
  }) async {
    final issues = <DiagnosticIssue>[];

    // 플랫폼 확인
    final platform = _getPlatform();

    // 기본 설정 검증
    if (config.configuredProviders.isEmpty) {
      issues.add(const DiagnosticIssue(
        severity: DiagnosticSeverity.error,
        message: 'Provider가 하나도 설정되지 않았습니다',
        solution: 'KAuthConfig에 최소 하나의 Provider를 설정하세요',
      ));
    }

    // 카카오 검증
    if (config.kakao != null) {
      issues.addAll(await _checkKakao(config.kakao!, platform, verbose));
    }

    // 네이버 검증
    if (config.naver != null) {
      issues.addAll(await _checkNaver(config.naver!, platform, verbose));
    }

    // 구글 검증
    if (config.google != null) {
      issues.addAll(await _checkGoogle(config.google!, platform, verbose));
    }

    // 애플 검증
    if (config.apple != null) {
      issues.addAll(await _checkApple(config.apple!, platform, verbose));
    }

    return DiagnosticResult(
      issues: issues,
      timestamp: DateTime.now(),
      platform: platform,
    );
  }

  static String _getPlatform() {
    if (kIsWeb) return 'web';
    if (Platform.isIOS) return 'ios';
    if (Platform.isAndroid) return 'android';
    if (Platform.isMacOS) return 'macos';
    return 'unknown';
  }

  // ============================================
  // 카카오 검증
  // ============================================
  static Future<List<DiagnosticIssue>> _checkKakao(
    KakaoConfig config,
    String platform,
    bool verbose,
  ) async {
    final issues = <DiagnosticIssue>[];

    // 앱 키 검증
    if (config.appKey.isEmpty) {
      issues.add(const DiagnosticIssue(
        provider: AuthProvider.kakao,
        severity: DiagnosticSeverity.error,
        message: 'appKey가 비어있습니다',
        solution: 'KakaoConfig(appKey: "YOUR_NATIVE_APP_KEY")로 설정하세요',
        docUrl: 'https://developers.kakao.com/docs/latest/ko/getting-started/app',
      ));
      return issues;
    }

    // 앱 키 형식 검증
    if (config.appKey.length < 20) {
      issues.add(const DiagnosticIssue(
        provider: AuthProvider.kakao,
        severity: DiagnosticSeverity.warning,
        message: 'appKey가 너무 짧습니다. 올바른 키인지 확인하세요',
        solution: 'Kakao Developers에서 네이티브 앱 키를 복사하세요',
      ));
    }

    // iOS 전용 검증
    if (platform == 'ios') {
      issues.addAll(await _checkKakaoIOS(config));
    }

    // Android 전용 검증
    if (platform == 'android') {
      issues.addAll(await _checkKakaoAndroid(config));
    }

    if (verbose && issues.isEmpty) {
      issues.add(const DiagnosticIssue(
        provider: AuthProvider.kakao,
        severity: DiagnosticSeverity.info,
        message: '설정이 정상입니다',
      ));
    }

    return issues;
  }

  static Future<List<DiagnosticIssue>> _checkKakaoIOS(KakaoConfig config) async {
    final issues = <DiagnosticIssue>[];

    // Info.plist URL Scheme 검증
    try {
      // URL Scheme이 등록되어 있는지 확인 (kakao{APP_KEY})
      final canLaunch = await _canHandleUrlScheme('kakao${config.appKey}://');
      if (!canLaunch) {
        issues.add(DiagnosticIssue(
          provider: AuthProvider.kakao,
          severity: DiagnosticSeverity.error,
          message: 'URL Scheme이 Info.plist에 등록되지 않았습니다',
          solution: '''Info.plist에 다음을 추가하세요:
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>kakao${config.appKey}</string>
    </array>
  </dict>
</array>''',
          docUrl: 'https://developers.kakao.com/docs/latest/ko/getting-started/sdk-ios',
        ));
      }
    } catch (_) {
      issues.add(const DiagnosticIssue(
        provider: AuthProvider.kakao,
        severity: DiagnosticSeverity.warning,
        message: 'URL Scheme 검증을 수행할 수 없습니다',
        solution: 'Info.plist에 kakao{APP_KEY} URL Scheme이 등록되어 있는지 확인하세요',
      ));
    }

    // LSApplicationQueriesSchemes 검증
    issues.add(const DiagnosticIssue(
      provider: AuthProvider.kakao,
      severity: DiagnosticSeverity.info,
      message: 'Info.plist에 LSApplicationQueriesSchemes 설정을 확인하세요',
      solution: '''<key>LSApplicationQueriesSchemes</key>
<array>
  <string>kakaokompassauth</string>
  <string>kakaolink</string>
  <string>kakaoplus</string>
  <string>kakaotalk</string>
</array>''',
    ));

    return issues;
  }

  static Future<List<DiagnosticIssue>> _checkKakaoAndroid(
      KakaoConfig config) async {
    final issues = <DiagnosticIssue>[];

    // AndroidManifest.xml 검증은 런타임에 어려우므로 가이드 제공
    issues.add(const DiagnosticIssue(
      provider: AuthProvider.kakao,
      severity: DiagnosticSeverity.info,
      message: 'AndroidManifest.xml 설정을 확인하세요',
      solution: '''<activity
    android:name="com.kakao.sdk.flutter.AuthCodeCustomTabsActivity"
    android:exported="true">
    <intent-filter>
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />
        <data android:host="oauth"
              android:scheme="kakao{YOUR_NATIVE_APP_KEY}" />
    </intent-filter>
</activity>''',
      docUrl: 'https://developers.kakao.com/docs/latest/ko/flutter/getting-started',
    ));

    return issues;
  }

  // ============================================
  // 네이버 검증
  // ============================================
  static Future<List<DiagnosticIssue>> _checkNaver(
    NaverConfig config,
    String platform,
    bool verbose,
  ) async {
    final issues = <DiagnosticIssue>[];

    // Client ID 검증
    if (config.clientId.isEmpty) {
      issues.add(const DiagnosticIssue(
        provider: AuthProvider.naver,
        severity: DiagnosticSeverity.error,
        message: 'clientId가 비어있습니다',
        solution: 'NaverConfig(clientId: "YOUR_CLIENT_ID", ...)로 설정하세요',
        docUrl: 'https://developers.naver.com/docs/login/api/api.md',
      ));
    }

    // Client Secret 검증
    if (config.clientSecret.isEmpty) {
      issues.add(const DiagnosticIssue(
        provider: AuthProvider.naver,
        severity: DiagnosticSeverity.error,
        message: 'clientSecret이 비어있습니다',
        solution: 'NaverConfig(clientSecret: "YOUR_CLIENT_SECRET", ...)로 설정하세요',
      ));
    }

    // App Name 검증
    if (config.appName.isEmpty) {
      issues.add(const DiagnosticIssue(
        provider: AuthProvider.naver,
        severity: DiagnosticSeverity.error,
        message: 'appName이 비어있습니다',
        solution: 'NaverConfig(appName: "앱 이름", ...)로 설정하세요',
      ));
    }

    // iOS 설정 검증
    if (platform == 'ios') {
      issues.add(const DiagnosticIssue(
        provider: AuthProvider.naver,
        severity: DiagnosticSeverity.info,
        message: 'Info.plist에 네이버 설정을 확인하세요',
        solution: '''<!-- 네이버 SDK 필수 키 -->
<key>NidClientID</key>
<string>YOUR_CLIENT_ID</string>
<key>NidClientSecret</key>
<string>YOUR_CLIENT_SECRET</string>
<key>NidAppName</key>
<string>YOUR_APP_NAME</string>
<key>NidUrlScheme</key>
<string>your-app-url-scheme</string>

<!-- URL Scheme -->
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>your-app-url-scheme</string>
    </array>
  </dict>
</array>

<!-- 앱 실행 허용 -->
<key>LSApplicationQueriesSchemes</key>
<array>
  <string>naversearchapp</string>
  <string>naversearchthirdlogin</string>
</array>''',
        docUrl: 'https://pub.dev/packages/flutter_naver_login',
      ));
    }

    // Android 설정 검증
    if (platform == 'android') {
      issues.add(const DiagnosticIssue(
        provider: AuthProvider.naver,
        severity: DiagnosticSeverity.info,
        message: 'Android 설정을 확인하세요',
        solution: '''1. MainActivity가 FlutterFragmentActivity를 상속하는지 확인:
   class MainActivity: FlutterFragmentActivity()

2. AndroidManifest.xml에 메타데이터 추가:
   <application>
     <meta-data android:name="com.naver.sdk.clientId"
                android:value="@string/client_id" />
     <meta-data android:name="com.naver.sdk.clientSecret"
                android:value="@string/client_secret" />
     <meta-data android:name="com.naver.sdk.clientName"
                android:value="@string/client_name" />
   </application>

3. res/values/strings.xml에 값 추가:
   <string name="client_id">YOUR_CLIENT_ID</string>
   <string name="client_secret">YOUR_CLIENT_SECRET</string>
   <string name="client_name">YOUR_APP_NAME</string>''',
        docUrl: 'https://pub.dev/packages/flutter_naver_login',
      ));
    }

    if (verbose && issues.isEmpty) {
      issues.add(const DiagnosticIssue(
        provider: AuthProvider.naver,
        severity: DiagnosticSeverity.info,
        message: '설정이 정상입니다',
      ));
    }

    return issues;
  }

  // ============================================
  // 구글 검증
  // ============================================
  static Future<List<DiagnosticIssue>> _checkGoogle(
    GoogleConfig config,
    String platform,
    bool verbose,
  ) async {
    final issues = <DiagnosticIssue>[];

    // iOS 전용 검증
    if (platform == 'ios') {
      if (config.iosClientId == null) {
        issues.add(const DiagnosticIssue(
          provider: AuthProvider.google,
          severity: DiagnosticSeverity.warning,
          message: 'iosClientId가 설정되지 않았습니다',
          solution: 'GoogleConfig(iosClientId: "YOUR_IOS_CLIENT_ID")로 설정하거나 '
              'GoogleService-Info.plist를 프로젝트에 추가하세요',
          docUrl: 'https://pub.dev/packages/google_sign_in',
        ));
      }

      issues.add(const DiagnosticIssue(
        provider: AuthProvider.google,
        severity: DiagnosticSeverity.info,
        message: 'Info.plist에 구글 로그인 설정을 확인하세요',
        solution: '''<!-- 1. GIDClientID 추가 (GoogleService-Info.plist의 CLIENT_ID) -->
<key>GIDClientID</key>
<string>YOUR_IOS_CLIENT_ID.apps.googleusercontent.com</string>

<!-- 2. (선택) 백엔드 연동 시 서버 클라이언트 ID -->
<key>GIDServerClientID</key>
<string>YOUR_SERVER_CLIENT_ID.apps.googleusercontent.com</string>

<!-- 3. URL Scheme 등록 (REVERSED_CLIENT_ID) -->
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleTypeRole</key>
    <string>Editor</string>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>com.googleusercontent.apps.YOUR_CLIENT_ID</string>
    </array>
  </dict>
</array>''',
        docUrl: 'https://pub.dev/packages/google_sign_in',
      ));
    }

    // Android 검증
    if (platform == 'android') {
      issues.add(const DiagnosticIssue(
        provider: AuthProvider.google,
        severity: DiagnosticSeverity.info,
        message: 'google-services.json이 android/app/에 있는지 확인하세요',
        solution: 'Firebase Console 또는 Google Cloud Console에서 다운로드',
        docUrl: 'https://pub.dev/packages/google_sign_in',
      ));
    }

    if (verbose && issues.isEmpty) {
      issues.add(const DiagnosticIssue(
        provider: AuthProvider.google,
        severity: DiagnosticSeverity.info,
        message: '설정이 정상입니다',
      ));
    }

    return issues;
  }

  // ============================================
  // 애플 검증
  // ============================================
  static Future<List<DiagnosticIssue>> _checkApple(
    AppleConfig config,
    String platform,
    bool verbose,
  ) async {
    final issues = <DiagnosticIssue>[];

    // iOS/macOS만 지원
    if (platform != 'ios' && platform != 'macos') {
      issues.add(DiagnosticIssue(
        provider: AuthProvider.apple,
        severity: DiagnosticSeverity.warning,
        message: 'Apple 로그인은 $platform에서 지원되지 않습니다',
        solution: 'iOS 또는 macOS에서만 사용 가능합니다',
      ));
      return issues;
    }

    // Capability 검증
    issues.add(const DiagnosticIssue(
      provider: AuthProvider.apple,
      severity: DiagnosticSeverity.info,
      message: 'Xcode에서 Sign in with Apple capability를 확인하세요',
      solution: '''1. Xcode에서 프로젝트 열기
2. Signing & Capabilities 탭
3. + Capability 클릭
4. Sign in with Apple 추가

또한 Apple Developer에서 App ID에
Sign in with Apple이 활성화되어 있어야 합니다.''',
      docUrl: 'https://developer.apple.com/sign-in-with-apple/',
    ));

    if (verbose && issues.isEmpty) {
      issues.add(const DiagnosticIssue(
        provider: AuthProvider.apple,
        severity: DiagnosticSeverity.info,
        message: '설정이 정상입니다',
      ));
    }

    return issues;
  }

  // ============================================
  // 유틸리티
  // ============================================
  static Future<bool> _canHandleUrlScheme(String url) async {
    try {
      final result = await const MethodChannel('k_auth/diagnostic')
          .invokeMethod<bool>('canOpenURL', {'url': url});
      return result ?? false;
    } catch (_) {
      return false;
    }
  }
}
