import '../errors/k_auth_error.dart';

/// 로그인 실패 정보를 담는 클래스
///
/// [AuthResult]의 실패 상태에서 사용됩니다.
/// [KAuthError]와 달리 Exception이 아닌 데이터 클래스입니다.
///
/// ## 사용 예시
///
/// ```dart
/// final result = await kAuth.signIn(AuthProvider.kakao);
///
/// result.fold(
///   onSuccess: (user) => navigateToHome(user),
///   onFailure: (failure) {
///     if (failure.isCancelled) {
///       showToast('로그인이 취소되었습니다');
///     } else {
///       showError(failure.message);
///     }
///   },
/// );
/// ```
///
/// ## when 패턴
///
/// ```dart
/// result.when(
///   success: (user) => navigateToHome(user),
///   cancelled: () => showToast('취소됨'),
///   failure: (failure) => showError(failure.message),
/// );
/// ```
class KAuthFailure {
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

  /// 에러 코드로부터 KAuthFailure 생성
  ///
  /// [ErrorCodes]에 정의된 코드를 사용하여 메시지와 힌트를 자동으로 설정합니다.
  ///
  /// ```dart
  /// final failure = KAuthFailure.fromCode(ErrorCodes.userCancelled);
  /// print(failure.message);  // '사용자가 로그인을 취소했습니다.'
  /// ```
  factory KAuthFailure.fromCode(String code) {
    final errorInfo = ErrorCodes.getErrorInfo(code);
    return KAuthFailure(
      code: code,
      message: errorInfo.message,
      hint: errorInfo.hint,
    );
  }

  /// 사용자가 로그인을 취소했는지 확인
  ///
  /// ```dart
  /// if (failure.isCancelled) {
  ///   // 취소는 에러가 아니므로 조용히 처리
  ///   return;
  /// }
  /// ```
  bool get isCancelled => code == ErrorCodes.userCancelled;

  /// 네트워크 오류인지 확인
  bool get isNetworkError => code == ErrorCodes.networkError;

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
  bool get canRetry => isNetworkError || code == ErrorCodes.timeout;

  /// 무시해도 되는 에러인지 확인
  ///
  /// 사용자 취소 등 에러 메시지를 표시하지 않아도 되는 경우.
  ///
  /// ```dart
  /// if (failure.shouldIgnore) return;
  /// showError(failure.message);
  /// ```
  bool get shouldIgnore => isCancelled;

  /// 사용자에게 표시할 메시지
  ///
  /// [message]가 없으면 기본 메시지를 반환합니다.
  String get displayMessage => message ?? '알 수 없는 오류가 발생했습니다.';

  /// JSON으로 변환
  Map<String, dynamic> toJson() => {
        if (code != null) 'code': code,
        if (message != null) 'message': message,
        if (hint != null) 'hint': hint,
      };

  /// JSON에서 생성
  factory KAuthFailure.fromJson(Map<String, dynamic> json) {
    return KAuthFailure(
      code: json['code'] as String?,
      message: json['message'] as String?,
      hint: json['hint'] as String?,
    );
  }

  @override
  String toString() {
    if (code != null) {
      return 'KAuthFailure[$code]: $message';
    }
    return 'KAuthFailure: $message';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is KAuthFailure &&
        other.code == code &&
        other.message == message &&
        other.hint == hint;
  }

  @override
  int get hashCode => Object.hash(code, message, hint);
}
