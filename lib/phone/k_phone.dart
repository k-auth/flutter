/// K-Auth 전화번호 인증 모듈
///
/// ```dart
/// import 'package:k_auth/phone/k_phone.dart';
///
/// // 인증번호 발송
/// await kAuth.phone.send('01012345678');
///
/// // 인증번호 확인
/// final result = await kAuth.phone.verify('123456');
/// ```
library;

export 'phone_config.dart';
export 'phone_state.dart';
export 'phone_result.dart';
export 'k_auth_phone.dart';
export 'widgets/phone_auth_builder.dart';
export 'widgets/otp_input.dart';
