/// KAuth 에러 클래스
class KAuthError implements Exception {
  /// 에러 코드
  final String code;

  /// 에러 메시지 (한글)
  final String message;

  /// 원본 에러
  final Object? originalError;

  const KAuthError({
    required this.code,
    required this.message,
    this.originalError,
  });

  @override
  String toString() => 'KAuthError[$code]: $message';
}

/// 에러 코드 정의
class ErrorCodes {
  ErrorCodes._();

  // 설정 에러
  static const String configNotFound = 'CONFIG_NOT_FOUND';
  static const String invalidConfig = 'INVALID_CONFIG';

  // 인증 에러
  static const String userCancelled = 'USER_CANCELLED';
  static const String loginFailed = 'LOGIN_FAILED';
  static const String tokenExpired = 'TOKEN_EXPIRED';
  static const String networkError = 'NETWORK_ERROR';

  // Provider 에러
  static const String providerNotConfigured = 'PROVIDER_NOT_CONFIGURED';
  static const String providerNotSupported = 'PROVIDER_NOT_SUPPORTED';

  // 플랫폼 에러
  static const String platformNotSupported = 'PLATFORM_NOT_SUPPORTED';
}

/// 에러 메시지 (한글)
class ErrorMessages {
  ErrorMessages._();

  static String getMessage(String code) {
    return _messages[code] ?? '알 수 없는 에러가 발생했습니다.';
  }

  static const Map<String, String> _messages = {
    ErrorCodes.configNotFound: '설정을 찾을 수 없습니다.',
    ErrorCodes.invalidConfig: '잘못된 설정입니다.',
    ErrorCodes.userCancelled: '사용자가 로그인을 취소했습니다.',
    ErrorCodes.loginFailed: '로그인에 실패했습니다.',
    ErrorCodes.tokenExpired: '토큰이 만료되었습니다.',
    ErrorCodes.networkError: '네트워크 오류가 발생했습니다.',
    ErrorCodes.providerNotConfigured: '해당 Provider가 설정되지 않았습니다.',
    ErrorCodes.providerNotSupported: '지원하지 않는 Provider입니다.',
    ErrorCodes.platformNotSupported: '현재 플랫폼에서 지원하지 않습니다.',
  };
}
