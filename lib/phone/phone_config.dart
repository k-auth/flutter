/// 전화번호 인증 Provider 타입
enum PhoneProvider {
  /// Firebase Phone Auth
  ///
  /// 백엔드 없이 바로 사용 가능합니다.
  /// 무료 할당량: 월 10,000건
  firebase,

  /// 커스텀 백엔드 (알림톡, SMS 등)
  ///
  /// [verifyUrl]을 설정해야 합니다.
  custom,
}

/// 전화번호 인증 설정
///
/// ```dart
/// final kAuth = await KAuth.init(
///   kakao: KakaoConfig(...),
///   phone: PhoneConfig(),  // Firebase 기본
/// );
///
/// // 또는 커스텀 백엔드
/// final kAuth = await KAuth.init(
///   phone: PhoneConfig.custom(
///     sendUrl: 'https://api.myapp.com/phone/send',
///     verifyUrl: 'https://api.myapp.com/phone/verify',
///   ),
/// );
/// ```
class PhoneConfig {
  /// Provider 타입
  final PhoneProvider provider;

  /// 인증번호 발송 URL (커스텀 백엔드용)
  final String? sendUrl;

  /// 인증번호 확인 URL (커스텀 백엔드용)
  final String? verifyUrl;

  /// 인증번호 길이 (기본: 6)
  final int codeLength;

  /// 재발송 대기 시간 (기본: 60초)
  final Duration resendDelay;

  /// 인증번호 만료 시간 (기본: 3분)
  final Duration codeExpiry;

  /// 디버그 모드
  final bool debug;

  const PhoneConfig({
    this.provider = PhoneProvider.firebase,
    this.sendUrl,
    this.verifyUrl,
    this.codeLength = 6,
    this.resendDelay = const Duration(seconds: 60),
    this.codeExpiry = const Duration(minutes: 3),
    this.debug = false,
  });

  /// 커스텀 백엔드 설정
  const PhoneConfig.custom({
    required String this.sendUrl,
    required String this.verifyUrl,
    this.codeLength = 6,
    this.resendDelay = const Duration(seconds: 60),
    this.codeExpiry = const Duration(minutes: 3),
    this.debug = false,
  }) : provider = PhoneProvider.custom;

  /// Firebase 설정 (기본값)
  const PhoneConfig.firebase({
    this.codeLength = 6,
    this.resendDelay = const Duration(seconds: 60),
    this.codeExpiry = const Duration(minutes: 3),
    this.debug = false,
  })  : provider = PhoneProvider.firebase,
        sendUrl = null,
        verifyUrl = null;
}
