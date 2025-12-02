import 'package:flutter_naver_login/flutter_naver_login.dart';

import '../models/auth_config.dart';
import '../models/auth_result.dart';
import '../models/k_auth_user.dart';
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
        final error = KAuthError.fromCode(
          ErrorCodes.loginFailed,
          details: {'naverError': result.errorMessage},
        );
        return AuthResult.failure(
          provider: AuthProvider.naver,
          errorMessage: result.errorMessage.isNotEmpty
              ? result.errorMessage
              : '네이버 로그인 실패',
          errorCode: error.code,
          errorHint: error.hint,
        );
      }

      if (result.status == NaverLoginStatus.cancelledByUser) {
        final error = KAuthError.fromCode(ErrorCodes.userCancelled);
        return AuthResult.failure(
          provider: AuthProvider.naver,
          errorMessage: error.message,
          errorCode: error.code,
          errorHint: error.hint,
        );
      }

      // 토큰 정보 조회
      final token = await FlutterNaverLogin.currentAccessToken;

      // expiresAt 파싱 (String -> DateTime)
      DateTime? expiresAt;
      if (token.expiresAt.isNotEmpty) {
        expiresAt = DateTime.tryParse(token.expiresAt);
      }

      // 원본 데이터 구성
      final rawData = <String, dynamic>{
        'response': {
          'id': result.account.id,
          'email': result.account.email,
          'name': result.account.name,
          'nickname': result.account.nickname,
          'profile_image': result.account.profileImage,
          'gender': result.account.gender,
          'age': result.account.age,
          'birthday': result.account.birthday,
          'birthyear': result.account.birthyear,
          'mobile': result.account.mobile,
        },
      };

      // KAuthUser 생성
      final user = KAuthUser.fromNaver(rawData);

      return AuthResult.success(
        provider: AuthProvider.naver,
        user: user,
        accessToken: token.accessToken,
        expiresAt: expiresAt,
        rawData: rawData,
      );
    } catch (e) {
      final error = KAuthError.fromCode(
        ErrorCodes.loginFailed,
        originalError: e,
      );
      return AuthResult.failure(
        provider: AuthProvider.naver,
        errorMessage: '네이버 로그인 중 오류 발생: $e',
        errorCode: error.code,
        errorHint: error.hint,
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
