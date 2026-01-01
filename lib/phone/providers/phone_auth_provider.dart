import '../phone_config.dart';
import '../phone_result.dart';

/// 전화번호 인증 Provider 인터페이스
///
/// Firebase, 알림톡, SMS 등 다양한 Provider를 추상화합니다.
abstract class BasePhoneAuthProvider {
  final PhoneConfig config;

  BasePhoneAuthProvider({required this.config});

  /// 인증번호 발송
  Future<PhoneResult> sendCode(String phoneNumber);

  /// 인증번호 확인
  Future<PhoneResult> verifyCode({
    required String phoneNumber,
    required String code,
    String? verificationId,
  });

  /// Provider 이름
  String get name;

  /// 재발송 대기 시간
  Duration get resendDelay => config.resendDelay;
}
