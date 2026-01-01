import '../models/k_auth_failure.dart';

/// 전화번호 인증 사용자 정보
class PhoneUser {
  /// 인증된 전화번호
  final String phoneNumber;

  /// Firebase UID (Firebase 사용 시)
  final String? uid;

  /// 인증 완료 시간
  final DateTime verifiedAt;

  /// 신규 사용자 여부
  final bool isNewUser;

  const PhoneUser({
    required this.phoneNumber,
    this.uid,
    required this.verifiedAt,
    this.isNewUser = false,
  });

  @override
  String toString() => 'PhoneUser(phoneNumber: $phoneNumber, uid: $uid)';
}

/// 전화번호 인증 실패 정보
class PhoneFailure {
  /// 에러 코드
  final String? code;

  /// 에러 메시지
  final String? message;

  /// 해결 힌트
  final String? hint;

  const PhoneFailure({
    this.code,
    this.message,
    this.hint,
  });

  /// 사용자 취소 여부
  bool get isCancelled => code == 'USER_CANCELLED';

  /// 네트워크 에러 여부
  bool get isNetworkError => code == 'NETWORK_ERROR' || code == 'TIMEOUT';

  /// 잘못된 인증번호 여부
  bool get isInvalidCode =>
      code == 'INVALID_CODE' || code == 'INVALID_VERIFICATION_CODE';

  /// 인증번호 만료 여부
  bool get isCodeExpired => code == 'CODE_EXPIRED' || code == 'SESSION_EXPIRED';

  /// 재시도 가능 여부
  bool get canRetry => isNetworkError || isCodeExpired;

  /// 무시해도 되는 에러 (취소 등)
  bool get shouldIgnore => isCancelled;

  /// 표시용 메시지
  String get displayMessage => message ?? '인증에 실패했습니다.';

  @override
  String toString() => 'PhoneFailure(code: $code, message: $message)';
}

/// 전화번호 인증 결과
///
/// ```dart
/// final result = await kAuth.phone.verify('123456');
///
/// // 간단하게
/// if (result.ok) {
///   navigateToHome();
/// }
///
/// // fold 패턴
/// result.fold(
///   ok: (user) => navigateToHome(),
///   err: (e) => showError(e.message),
/// );
///
/// // when 패턴 (취소 구분)
/// result.when(
///   ok: (user) => navigateToHome(),
///   cancelled: () => {},
///   err: (e) => showError(e.message),
/// );
/// ```
class PhoneResult {
  /// 성공 여부
  final bool ok;

  /// 인증된 사용자 정보 (성공 시)
  final PhoneUser? user;

  /// 실패 정보 (실패 시)
  final PhoneFailure? _failure;

  /// Firebase verification ID (내부용)
  final String? verificationId;

  const PhoneResult._({
    required this.ok,
    this.user,
    PhoneFailure? failure,
    this.verificationId,
  }) : _failure = failure;

  /// 성공 결과 생성
  factory PhoneResult.success({
    PhoneUser? user,
    String? verificationId,
  }) {
    return PhoneResult._(
      ok: true,
      user: user,
      verificationId: verificationId,
    );
  }

  /// 실패 결과 생성
  factory PhoneResult.failure({
    String? code,
    String? message,
    String? hint,
  }) {
    return PhoneResult._(
      ok: false,
      failure: PhoneFailure(
        code: code,
        message: message,
        hint: hint,
      ),
    );
  }

  /// 취소 결과 생성
  factory PhoneResult.cancelled() {
    return PhoneResult._(
      ok: false,
      failure: const PhoneFailure(
        code: 'USER_CANCELLED',
        message: '인증이 취소되었습니다.',
      ),
    );
  }

  /// 실패 정보 (실패 시에만 유효)
  PhoneFailure get failure => _failure ?? const PhoneFailure();

  /// 에러 메시지
  String? get errorMessage => _failure?.message;

  /// 에러 코드
  String? get errorCode => _failure?.code;

  /// 성공/실패 분기 (fold)
  ///
  /// ```dart
  /// result.fold(
  ///   ok: (user) => print('인증 완료: ${user.phoneNumber}'),
  ///   err: (e) => print('실패: ${e.message}'),
  /// );
  /// ```
  T fold<T>({
    required T Function(PhoneUser? user) ok,
    required T Function(PhoneFailure failure) err,
  }) {
    if (this.ok) {
      return ok(user);
    }
    return err(failure);
  }

  /// 성공/취소/실패 분기 (when)
  ///
  /// ```dart
  /// result.when(
  ///   ok: (user) => navigateToHome(),
  ///   cancelled: () => showToast('취소됨'),
  ///   err: (e) => showError(e.message),
  /// );
  /// ```
  T when<T>({
    required T Function(PhoneUser? user) ok,
    required T Function() cancelled,
    required T Function(PhoneFailure failure) err,
  }) {
    if (this.ok) {
      return ok(user);
    }
    if (failure.isCancelled) {
      return cancelled();
    }
    return err(failure);
  }

  /// 성공 시 콜백 (체이닝)
  ///
  /// ```dart
  /// result
  ///   .onSuccess((user) => saveUser(user))
  ///   .onFailure((e) => logError(e));
  /// ```
  PhoneResult onSuccess(void Function(PhoneUser? user) callback) {
    if (ok) {
      callback(user);
    }
    return this;
  }

  /// 실패 시 콜백 (체이닝)
  PhoneResult onFailure(void Function(PhoneFailure failure) callback) {
    if (!ok) {
      callback(failure);
    }
    return this;
  }

  /// KAuthFailure로 변환 (호환성)
  KAuthFailure toKAuthFailure() => KAuthFailure(
        code: _failure?.code,
        message: _failure?.message,
        hint: _failure?.hint,
      );

  @override
  String toString() {
    if (ok) {
      return 'PhoneResult.success(user: $user)';
    }
    return 'PhoneResult.failure(${failure.code}: ${failure.message})';
  }
}
