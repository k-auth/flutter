/// 전화번호 인증 상태
///
/// ```dart
/// switch (kAuth.phone.state) {
///   case PhoneState.idle:
///     return PhoneInputScreen();
///   case PhoneState.codeSent:
///     return OtpInputScreen();
///   case PhoneState.verified:
///     return SuccessScreen();
///   // ...
/// }
/// ```
enum PhoneState {
  /// 초기 상태
  idle,

  /// 인증번호 발송 중
  sending,

  /// 인증번호 발송 완료
  codeSent,

  /// 인증번호 확인 중
  verifying,

  /// 인증 완료
  verified,

  /// 에러 발생
  error,
}
