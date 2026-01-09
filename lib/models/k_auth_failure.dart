import '../errors/k_auth_error.dart';

/// 에러 심각도
///
/// UI에서 에러 유형에 따라 다른 처리를 할 때 사용합니다.
///
/// ```dart
/// switch (failure.severity) {
///   case ErrorSeverity.ignorable:
///     return; // 무시
///   case ErrorSeverity.retryable:
///     showRetryDialog();
///   case ErrorSeverity.authRequired:
///     navigateToLogin();
///   case ErrorSeverity.fixRequired:
///     showErrorDialog(failure.message);
/// }
/// ```
enum ErrorSeverity {
  /// 무시 가능 (사용자 취소 등)
  ignorable,

  /// 재시도 가능 (네트워크 오류, 타임아웃 등)
  retryable,

  /// 재인증 필요 (토큰 만료 등)
  authRequired,

  /// 수정 필요 (설정 오류 등)
  fixRequired,
}

/// 로그인 실패 정보를 담는 sealed class
///
/// [AuthResult]의 실패 상태에서 사용됩니다.
/// 타입으로 에러 종류를 구분할 수 있습니다.
///
/// ## 타입 기반 처리 (권장)
///
/// ```dart
/// switch (failure) {
///   case NetworkError():
///     showRetryButton();
///   case TokenError():
///     navigateToLogin();
///   case ConfigError():
///     showSetupGuide();
///   case CancelledError():
///     return; // 무시
///   case AuthError():
///     showError(failure.message);
/// }
/// ```
///
/// ## 기존 방식도 지원
///
/// ```dart
/// if (failure.isCancelled) return;
/// if (failure.canRetry) showRetryButton();
/// ```
sealed class KAuthFailure {
  /// 에러 코드
  ///
  /// [ErrorCodes]에 정의된 코드 중 하나입니다.
  /// 예: 'USER_CANCELLED', 'NETWORK_ERROR', 'LOGIN_FAILED'
  final String? code;

  /// 에러 메시지 (한글)
  ///
  /// 사용자에게 표시할 수 있는 메시지입니다.
  final String? message;

  /// 해결 힌트
  ///
  /// 문제 해결을 위한 안내 메시지입니다.
  final String? hint;

  const KAuthFailure({
    this.code,
    this.message,
    this.hint,
  });

  /// 에러 코드로부터 적절한 KAuthFailure 서브타입 생성
  ///
  /// [ErrorCodes]에 정의된 코드를 사용하여 메시지와 힌트를 자동으로 설정합니다.
  ///
  /// ```dart
  /// final failure = KAuthFailure.fromCode(ErrorCodes.userCancelled);
  /// print(failure is CancelledError);  // true
  /// ```
  factory KAuthFailure.fromCode(String code) {
    final errorInfo = ErrorCodes.getErrorInfo(code);
    return _createFromCode(
      code: code,
      message: errorInfo.message,
      hint: errorInfo.hint,
    );
  }

  /// 코드와 메시지로 적절한 서브타입 생성 (내부용)
  static KAuthFailure _createFromCode({
    required String code,
    String? message,
    String? hint,
  }) {
    // 취소
    if (code == ErrorCodes.userCancelled) {
      return CancelledError(code: code, message: message, hint: hint);
    }

    // 네트워크 에러
    if (code == ErrorCodes.networkError || code == ErrorCodes.timeout) {
      return NetworkError(code: code, message: message, hint: hint);
    }

    // 토큰 에러
    if (code == ErrorCodes.tokenExpired ||
        code == ErrorCodes.refreshFailed ||
        code == ErrorCodes.accessTokenError) {
      return TokenError(code: code, message: message, hint: hint);
    }

    // 설정 에러
    if (code == ErrorCodes.configNotFound ||
        code == ErrorCodes.invalidConfig ||
        code == ErrorCodes.noProviderConfigured ||
        code == ErrorCodes.missingClientId ||
        code == ErrorCodes.missingClientSecret ||
        code == ErrorCodes.missingAppKey ||
        code == ErrorCodes.providerNotConfigured ||
        code == ErrorCodes.providerNotInitialized) {
      return ConfigError(code: code, message: message, hint: hint);
    }

    // 기타 인증 에러
    return AuthError(code: code, message: message, hint: hint);
  }

  /// 일반 생성자 (기존 호환)
  factory KAuthFailure.create({
    String? code,
    String? message,
    String? hint,
  }) {
    if (code != null) {
      return _createFromCode(code: code, message: message, hint: hint);
    }
    return AuthError(code: code, message: message, hint: hint);
  }

  /// 사용자가 로그인을 취소했는지 확인
  bool get isCancelled => this is CancelledError;

  /// 네트워크 오류인지 확인
  bool get isNetworkError => this is NetworkError;

  /// 토큰 관련 오류인지 확인
  bool get isTokenError => this is TokenError;

  /// 설정 오류인지 확인
  bool get isConfigError => this is ConfigError;

  /// 토큰 만료인지 확인
  bool get isTokenExpired => code == ErrorCodes.tokenExpired;

  /// Provider 설정 오류인지 확인
  bool get isProviderNotConfigured => code == ErrorCodes.providerNotConfigured;

  /// 재시도 가능한 에러인지 확인
  ///
  /// 네트워크 오류 등 일시적인 문제로 재시도하면 성공할 수 있는 경우.
  ///
  /// ```dart
  /// if (failure.canRetry) {
  ///   showRetryButton();
  /// }
  /// ```
  bool get canRetry => this is NetworkError;

  /// 무시해도 되는 에러인지 확인
  ///
  /// 사용자 취소 등 에러 메시지를 표시하지 않아도 되는 경우.
  ///
  /// ```dart
  /// if (failure.shouldIgnore) return;
  /// showError(failure.message);
  /// ```
  bool get shouldIgnore => this is CancelledError;

  /// 일시적인 에러인지 확인
  ///
  /// 네트워크 문제 등 시간이 지나면 해결될 수 있는 에러.
  /// [canRetry]와 동일합니다.
  bool get isTemporary => canRetry;

  /// 영구적인 에러인지 확인
  ///
  /// 설정 오류, 권한 거부 등 재시도해도 해결되지 않는 에러.
  bool get isPermanent => !isTemporary && !shouldIgnore;

  /// 재인증이 필요한지 확인
  ///
  /// 토큰 만료, 리프레시 실패 등 다시 로그인이 필요한 경우.
  bool get requiresReauth => this is TokenError;

  /// 에러 심각도
  ///
  /// UI에서 에러 유형별로 다른 처리를 할 때 사용합니다.
  ///
  /// ```dart
  /// switch (failure.severity) {
  ///   case ErrorSeverity.ignorable:
  ///     return;
  ///   case ErrorSeverity.retryable:
  ///     showRetryDialog();
  ///   case ErrorSeverity.authRequired:
  ///     navigateToLogin();
  ///   case ErrorSeverity.fixRequired:
  ///     showErrorDialog(failure.message);
  /// }
  /// ```
  ErrorSeverity get severity {
    return switch (this) {
      CancelledError() => ErrorSeverity.ignorable,
      NetworkError() => ErrorSeverity.retryable,
      TokenError() => ErrorSeverity.authRequired,
      ConfigError() => ErrorSeverity.fixRequired,
      AuthError() => ErrorSeverity.fixRequired,
    };
  }

  /// 사용자에게 표시할 메시지
  ///
  /// [message]가 없으면 기본 메시지를 반환합니다.
  String get displayMessage => message ?? '알 수 없는 오류가 발생했습니다.';

  /// JSON으로 변환
  Map<String, dynamic> toJson() => {
        'type': runtimeType.toString(),
        if (code != null) 'code': code,
        if (message != null) 'message': message,
        if (hint != null) 'hint': hint,
      };

  /// JSON에서 생성
  factory KAuthFailure.fromJson(Map<String, dynamic> json) {
    final code = json['code'] as String?;
    final message = json['message'] as String?;
    final hint = json['hint'] as String?;

    if (code != null) {
      return _createFromCode(code: code, message: message, hint: hint);
    }
    return AuthError(code: code, message: message, hint: hint);
  }

  @override
  String toString() {
    final typeName = runtimeType.toString();
    if (code != null) {
      return '$typeName[$code]: $message';
    }
    return '$typeName: $message';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is KAuthFailure &&
        other.runtimeType == runtimeType &&
        other.code == code &&
        other.message == message &&
        other.hint == hint;
  }

  @override
  int get hashCode => Object.hash(runtimeType, code, message, hint);
}

/// 네트워크 오류
///
/// 인터넷 연결 문제, 타임아웃 등 일시적인 네트워크 문제.
/// 재시도하면 성공할 수 있습니다.
///
/// ```dart
/// if (failure case NetworkError()) {
///   showRetryButton();
/// }
/// ```
final class NetworkError extends KAuthFailure {
  const NetworkError({
    super.code,
    super.message,
    super.hint,
  });

  /// 타임아웃 에러인지 확인
  bool get isTimeout => code == ErrorCodes.timeout;
}

/// 토큰 관련 오류
///
/// 토큰 만료, 갱신 실패 등 재인증이 필요한 상태.
///
/// ```dart
/// if (failure case TokenError()) {
///   navigateToLogin();
/// }
/// ```
final class TokenError extends KAuthFailure {
  const TokenError({
    super.code,
    super.message,
    super.hint,
  });

  /// 토큰이 만료된 경우인지 확인
  bool get isExpired => code == ErrorCodes.tokenExpired;

  /// 갱신 실패인지 확인
  bool get isRefreshFailed => code == ErrorCodes.refreshFailed;
}

/// 설정 오류
///
/// Provider 미설정, 잘못된 설정 등 개발자가 수정해야 하는 문제.
///
/// ```dart
/// if (failure case ConfigError()) {
///   showSetupGuide();
/// }
/// ```
final class ConfigError extends KAuthFailure {
  const ConfigError({
    super.code,
    super.message,
    super.hint,
  });

  /// Provider가 설정되지 않은 경우인지 확인
  bool get isProviderMissing => code == ErrorCodes.providerNotConfigured;

  /// 초기화가 안 된 경우인지 확인
  bool get isNotInitialized =>
      code == ErrorCodes.configNotFound ||
      code == ErrorCodes.providerNotInitialized;
}

/// 사용자 취소
///
/// 사용자가 로그인 과정을 취소한 경우.
/// 일반적으로 에러 메시지를 표시하지 않아도 됩니다.
///
/// ```dart
/// if (failure case CancelledError()) {
///   return; // 조용히 무시
/// }
/// ```
final class CancelledError extends KAuthFailure {
  const CancelledError({
    super.code,
    super.message,
    super.hint,
  });
}

/// 일반 인증 오류
///
/// 위 카테고리에 속하지 않는 기타 인증 관련 오류.
///
/// ```dart
/// if (failure case AuthError()) {
///   showError(failure.message);
/// }
/// ```
final class AuthError extends KAuthFailure {
  const AuthError({
    super.code,
    super.message,
    super.hint,
  });
}
