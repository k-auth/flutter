import 'dart:convert';
import 'package:http/http.dart' as http;
import '../phone_result.dart';
import 'phone_auth_provider.dart';

/// 커스텀 백엔드 Phone Auth Provider
///
/// 알림톡, SMS 등 자체 백엔드를 사용할 때 사용합니다.
///
/// ## 백엔드 API 스펙
///
/// ### POST /phone/send
/// ```json
/// // Request
/// { "phoneNumber": "+821012345678" }
///
/// // Response (성공)
/// { "success": true, "verificationId": "xxx" }
///
/// // Response (실패)
/// { "success": false, "code": "ERROR_CODE", "message": "에러 메시지" }
/// ```
///
/// ### POST /phone/verify
/// ```json
/// // Request
/// { "phoneNumber": "+821012345678", "code": "123456", "verificationId": "xxx" }
///
/// // Response (성공)
/// { "success": true, "uid": "user_id", "isNewUser": false }
///
/// // Response (실패)
/// { "success": false, "code": "INVALID_CODE", "message": "인증번호가 일치하지 않습니다" }
/// ```
class CustomPhoneProvider extends BasePhoneAuthProvider {
  final http.Client _client;

  CustomPhoneProvider({
    required super.config,
    http.Client? client,
  }) : _client = client ?? http.Client();

  @override
  String get name => 'custom';

  @override
  Future<PhoneResult> sendCode(String phoneNumber) async {
    final sendUrl = config.sendUrl;
    if (sendUrl == null) {
      return PhoneResult.failure(
        code: 'NO_SEND_URL',
        message: 'sendUrl이 설정되지 않았습니다.',
        hint: 'PhoneConfig.custom(sendUrl: "...")을 설정하세요.',
      );
    }

    try {
      final response = await _client.post(
        Uri.parse(sendUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phoneNumber': phoneNumber}),
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && data['success'] == true) {
        return PhoneResult.success(
          verificationId: data['verificationId'] as String?,
        );
      }

      return PhoneResult.failure(
        code: data['code'] as String? ?? 'SEND_FAILED',
        message: data['message'] as String? ?? '인증번호 발송에 실패했습니다.',
      );
    } catch (e) {
      return PhoneResult.failure(
        code: 'NETWORK_ERROR',
        message: '서버 연결에 실패했습니다.',
        hint: e.toString(),
      );
    }
  }

  @override
  Future<PhoneResult> verifyCode({
    required String phoneNumber,
    required String code,
    String? verificationId,
  }) async {
    final verifyUrl = config.verifyUrl;
    if (verifyUrl == null) {
      return PhoneResult.failure(
        code: 'NO_VERIFY_URL',
        message: 'verifyUrl이 설정되지 않았습니다.',
        hint: 'PhoneConfig.custom(verifyUrl: "...")을 설정하세요.',
      );
    }

    try {
      final response = await _client.post(
        Uri.parse(verifyUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phoneNumber': phoneNumber,
          'code': code,
          if (verificationId != null) 'verificationId': verificationId,
        }),
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && data['success'] == true) {
        return PhoneResult.success(
          user: PhoneUser(
            phoneNumber: phoneNumber,
            uid: data['uid'] as String?,
            verifiedAt: DateTime.now(),
            isNewUser: data['isNewUser'] as bool? ?? false,
          ),
        );
      }

      return PhoneResult.failure(
        code: data['code'] as String? ?? 'VERIFY_FAILED',
        message: data['message'] as String? ?? '인증번호 확인에 실패했습니다.',
      );
    } catch (e) {
      return PhoneResult.failure(
        code: 'NETWORK_ERROR',
        message: '서버 연결에 실패했습니다.',
        hint: e.toString(),
      );
    }
  }
}
