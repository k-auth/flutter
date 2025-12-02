import 'package:flutter_naver_login/flutter_naver_login.dart';

import '../models/auth_config.dart';
import '../models/auth_result.dart';
import '../errors/k_auth_error.dart';

/// 네이버 로그인 Provider
class NaverProvider {
  final NaverConfig config;

  NaverProvider(this.config);

  /// 네이버 로그인 실행
  Future<AuthResult> signIn() async {
    try {
      final result = await FlutterNaverLogin.logIn();

      if (result.status == NaverLoginStatus.error) {
        return AuthResult.failure(
          provider: AuthProvider.naver,
          errorMessage: result.errorMessage.isNotEmpty
              ? result.errorMessage
              : '네이버 로그인 실패',
          errorCode: ErrorCodes.loginFailed,
        );
      }

      if (result.status == NaverLoginStatus.cancelledByUser) {
        return AuthResult.failure(
          provider: AuthProvider.naver,
          errorMessage: ErrorMessages.getMessage(ErrorCodes.userCancelled),
          errorCode: ErrorCodes.userCancelled,
        );
      }

      // 토큰 정보 조회
      final token = await FlutterNaverLogin.currentAccessToken;

      // expiresAt 파싱 (String -> DateTime)
      DateTime? expiresAt;
      if (token.expiresAt.isNotEmpty) {
        expiresAt = DateTime.tryParse(token.expiresAt);
      }

      return AuthResult.success(
        provider: AuthProvider.naver,
        userId: result.account.id,
        email: result.account.email,
        name: result.account.name,
        profileImageUrl: result.account.profileImage,
        accessToken: token.accessToken,
        expiresAt: expiresAt,
        rawData: {
          'id': result.account.id,
          'email': result.account.email,
          'name': result.account.name,
          'nickname': result.account.nickname,
          'profileImage': result.account.profileImage,
          'gender': result.account.gender,
          'age': result.account.age,
          'birthday': result.account.birthday,
          'birthyear': result.account.birthyear,
          'mobile': result.account.mobile,
        },
      );
    } catch (e) {
      return AuthResult.failure(
        provider: AuthProvider.naver,
        errorMessage: '네이버 로그인 중 오류 발생: $e',
        errorCode: ErrorCodes.loginFailed,
      );
    }
  }

  /// 네이버 로그아웃
  Future<void> signOut() async {
    try {
      await FlutterNaverLogin.logOut();
    } catch (e) {
      throw KAuthError(
        code: ErrorCodes.loginFailed,
        message: '네이버 로그아웃 실패: $e',
        originalError: e,
      );
    }
  }

  /// 네이버 연결 해제 (탈퇴)
  Future<void> unlink() async {
    try {
      await FlutterNaverLogin.logOutAndDeleteToken();
    } catch (e) {
      throw KAuthError(
        code: ErrorCodes.loginFailed,
        message: '네이버 연결 해제 실패: $e',
        originalError: e,
      );
    }
  }
}
