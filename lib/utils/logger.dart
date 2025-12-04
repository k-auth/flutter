import 'dart:developer' as developer;

/// K-Auth 로그 레벨
///
/// 로그 출력 수준을 제어합니다.
enum KAuthLogLevel {
  /// 모든 로그 비활성화
  none,

  /// 에러만 출력
  error,

  /// 경고 이상 출력
  warning,

  /// 정보 이상 출력
  info,

  /// 모든 로그 출력 (개발용)
  debug,
}

/// 로그 이벤트 정보
class KAuthLogEvent {
  /// 로그 레벨
  final KAuthLogLevel level;

  /// 로그 메시지
  final String message;

  /// 로그 발생 시간
  final DateTime timestamp;

  /// 관련 Provider (있는 경우)
  final String? provider;

  /// 추가 데이터
  final Map<String, dynamic>? data;

  /// 관련 에러 (있는 경우)
  final Object? error;

  /// 스택 트레이스 (있는 경우)
  final StackTrace? stackTrace;

  const KAuthLogEvent({
    required this.level,
    required this.message,
    required this.timestamp,
    this.provider,
    this.data,
    this.error,
    this.stackTrace,
  });

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.write('[K-Auth] ');
    buffer.write(_levelEmoji);
    buffer.write(' ');
    if (provider != null) {
      buffer.write('[$provider] ');
    }
    buffer.write(message);
    if (data != null && data!.isNotEmpty) {
      buffer.write(' $data');
    }
    return buffer.toString();
  }

  String get _levelEmoji => switch (level) {
        KAuthLogLevel.none => '',
        KAuthLogLevel.error => '❌',
        KAuthLogLevel.warning => '⚠️',
        KAuthLogLevel.info => 'ℹ️',
        KAuthLogLevel.debug => '🔍',
      };
}

/// 커스텀 로거 함수 타입
typedef KAuthLoggerFunction = void Function(KAuthLogEvent event);

/// K-Auth 로거
///
/// 라이브러리의 모든 로그를 관리합니다.
///
/// ## 기본 사용법
///
/// ```dart
/// // 로그 레벨 설정
/// KAuthLogger.level = KAuthLogLevel.debug;
///
/// // 프로덕션에서는 비활성화
/// KAuthLogger.level = KAuthLogLevel.none;
/// ```
///
/// ## 커스텀 로거
///
/// ```dart
/// // 커스텀 로거 설정 (Firebase Crashlytics 등)
/// KAuthLogger.onLog = (event) {
///   if (event.level == KAuthLogLevel.error) {
///     FirebaseCrashlytics.instance.recordError(
///       event.error,
///       event.stackTrace,
///       reason: event.message,
///     );
///   }
/// };
/// ```
class KAuthLogger {
  KAuthLogger._();

  /// 현재 로그 레벨
  ///
  /// 기본값: [KAuthLogLevel.none] (프로덕션 안전)
  ///
  /// 개발 중에는 [KAuthLogLevel.debug]로 설정하세요.
  static KAuthLogLevel level = KAuthLogLevel.none;

  /// 커스텀 로거 함수
  ///
  /// 설정하면 기본 로거 대신 이 함수가 호출됩니다.
  /// Firebase Crashlytics, Sentry 등과 연동할 때 유용합니다.
  static KAuthLoggerFunction? onLog;

  /// 디버그 로그
  static void debug(
    String message, {
    String? provider,
    Map<String, dynamic>? data,
  }) {
    _log(KAuthLogLevel.debug, message, provider: provider, data: data);
  }

  /// 정보 로그
  static void info(
    String message, {
    String? provider,
    Map<String, dynamic>? data,
  }) {
    _log(KAuthLogLevel.info, message, provider: provider, data: data);
  }

  /// 경고 로그
  static void warning(
    String message, {
    String? provider,
    Map<String, dynamic>? data,
  }) {
    _log(KAuthLogLevel.warning, message, provider: provider, data: data);
  }

  /// 에러 로그
  static void error(
    String message, {
    String? provider,
    Map<String, dynamic>? data,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log(
      KAuthLogLevel.error,
      message,
      provider: provider,
      data: data,
      error: error,
      stackTrace: stackTrace,
    );
  }

  static void _log(
    KAuthLogLevel logLevel,
    String message, {
    String? provider,
    Map<String, dynamic>? data,
    Object? error,
    StackTrace? stackTrace,
  }) {
    // 로그 레벨 체크
    if (level == KAuthLogLevel.none) return;
    if (logLevel.index > level.index) return;

    final event = KAuthLogEvent(
      level: logLevel,
      message: message,
      timestamp: DateTime.now(),
      provider: provider,
      data: data,
      error: error,
      stackTrace: stackTrace,
    );

    // 커스텀 로거가 있으면 호출
    if (onLog != null) {
      onLog!(event);
      return;
    }

    // 기본 로거
    developer.log(
      event.toString(),
      name: 'K-Auth',
      level: _dartLogLevel(logLevel),
      error: error,
      stackTrace: stackTrace,
    );
  }

  static int _dartLogLevel(KAuthLogLevel level) => switch (level) {
        KAuthLogLevel.none => 0,
        KAuthLogLevel.debug => 500,
        KAuthLogLevel.info => 800,
        KAuthLogLevel.warning => 900,
        KAuthLogLevel.error => 1000,
      };
}
