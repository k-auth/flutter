import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart' as kakao;

import '../models/auth_config.dart';
import '../models/auth_result.dart';
import '../errors/k_auth_error.dart';

/// 카카오 로그인 Provider
class KakaoProvider {
  final KakaoConfig config;

  KakaoProvider(this.config);

  /// 카카오 SDK 초기화
  void initialize() {
    kakao.KakaoSdk.init(nativeAppKey: config.appKey);
  }

  /// 카카오 로그인 실행
  Future<AuthResult> signIn() async {
    try {
      // 카카오톡 설치 여부에 따라 로그인 방식 선택
      kakao.OAuthToken token;

      if (await kakao.isKakaoTalkInstalled()) {
        token = await kakao.UserApi.instance.loginWithKakaoTalk();
      } else {
        token = await kakao.UserApi.instance.loginWithKakaoAccount();
      }

      // 사용자 정보 조회
      final user = await kakao.UserApi.instance.me();

      return AuthResult.success(
        provider: AuthProvider.kakao,
        userId: user.id.toString(),
        email: user.kakaoAccount?.email,
        name: user.kakaoAccount?.profile?.nickname,
        profileImageUrl: user.kakaoAccount?.profile?.profileImageUrl,
        accessToken: token.accessToken,
        refreshToken: token.refreshToken,
        expiresAt: token.expiresAt,
        rawData: {
          'id': user.id,
          'kakaoAccount': {
            'email': user.kakaoAccount?.email,
            'profile': {
              'nickname': user.kakaoAccount?.profile?.nickname,
              'profileImageUrl': user.kakaoAccount?.profile?.profileImageUrl,
            },
          },
        },
      );
    } on kakao.KakaoAuthException catch (e) {
      if (e.error == kakao.AuthErrorCause.accessDenied) {
        return AuthResult.failure(
          provider: AuthProvider.kakao,
          errorMessage: ErrorMessages.getMessage(ErrorCodes.userCancelled),
          errorCode: ErrorCodes.userCancelled,
        );
      }
      return AuthResult.failure(
        provider: AuthProvider.kakao,
        errorMessage: '카카오 로그인 실패: ${e.message}',
        errorCode: ErrorCodes.loginFailed,
      );
    } catch (e) {
      return AuthResult.failure(
        provider: AuthProvider.kakao,
        errorMessage: '카카오 로그인 중 오류 발생: $e',
        errorCode: ErrorCodes.loginFailed,
      );
    }
  }

  /// 카카오 로그아웃
  Future<void> signOut() async {
    try {
      await kakao.UserApi.instance.logout();
    } catch (e) {
      throw KAuthError(
        code: ErrorCodes.loginFailed,
        message: '카카오 로그아웃 실패: $e',
        originalError: e,
      );
    }
  }

  /// 카카오 연결 해제 (탈퇴)
  Future<void> unlink() async {
    try {
      await kakao.UserApi.instance.unlink();
    } catch (e) {
      throw KAuthError(
        code: ErrorCodes.loginFailed,
        message: '카카오 연결 해제 실패: $e',
        originalError: e,
      );
    }
  }
}
