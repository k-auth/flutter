import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart' as kakao;

import '../models/auth_config.dart';
import '../models/auth_result.dart';
import '../models/k_auth_user.dart';
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
      final kakaoUser = await kakao.UserApi.instance.me();

      // 원본 데이터 구성
      final rawData = <String, dynamic>{
        'id': kakaoUser.id,
        'kakao_account': {
          'email': kakaoUser.kakaoAccount?.email,
          'profile': {
            'nickname': kakaoUser.kakaoAccount?.profile?.nickname,
            'profile_image_url':
                kakaoUser.kakaoAccount?.profile?.profileImageUrl,
          },
          'phone_number': kakaoUser.kakaoAccount?.phoneNumber,
          'birthday': kakaoUser.kakaoAccount?.birthday,
          'birthyear': kakaoUser.kakaoAccount?.birthyear,
          'gender': kakaoUser.kakaoAccount?.gender?.name,
          'age_range': kakaoUser.kakaoAccount?.ageRange?.name,
        },
      };

      // KAuthUser 생성
      final user = KAuthUser.fromKakao(rawData);

      return AuthResult.success(
        provider: AuthProvider.kakao,
        user: user,
        accessToken: token.accessToken,
        refreshToken: token.refreshToken,
        idToken: token.idToken,
        expiresAt: token.expiresAt,
        rawData: rawData,
      );
    } on kakao.KakaoAuthException catch (e) {
      if (e.error == kakao.AuthErrorCause.accessDenied) {
        final error = KAuthError.fromCode(ErrorCodes.userCancelled);
        return AuthResult.failure(
          provider: AuthProvider.kakao,
          errorMessage: error.message,
          errorCode: error.code,
          errorHint: error.hint,
        );
      }
      final error = KAuthError.fromCode(
        ErrorCodes.loginFailed,
        details: {'kakaoError': e.message},
        originalError: e,
      );
      return AuthResult.failure(
        provider: AuthProvider.kakao,
        errorMessage: '카카오 로그인 실패: ${e.message}',
        errorCode: error.code,
        errorHint: error.hint,
      );
    } catch (e) {
      final error = KAuthError.fromCode(
        ErrorCodes.loginFailed,
        originalError: e,
      );
      return AuthResult.failure(
        provider: AuthProvider.kakao,
        errorMessage: '카카오 로그인 중 오류 발생: $e',
        errorCode: error.code,
        errorHint: error.hint,
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

  /// 카카오 토큰 갱신
  Future<AuthResult> refreshToken() async {
    try {
      // 토큰 갱신
      final token = await kakao.AuthApi.instance.refreshToken();

      // 사용자 정보 조회
      final kakaoUser = await kakao.UserApi.instance.me();

      // 원본 데이터 구성
      final rawData = <String, dynamic>{
        'id': kakaoUser.id,
        'kakao_account': {
          'email': kakaoUser.kakaoAccount?.email,
          'profile': {
            'nickname': kakaoUser.kakaoAccount?.profile?.nickname,
            'profile_image_url':
                kakaoUser.kakaoAccount?.profile?.profileImageUrl,
          },
          'phone_number': kakaoUser.kakaoAccount?.phoneNumber,
          'birthday': kakaoUser.kakaoAccount?.birthday,
          'birthyear': kakaoUser.kakaoAccount?.birthyear,
          'gender': kakaoUser.kakaoAccount?.gender?.name,
          'age_range': kakaoUser.kakaoAccount?.ageRange?.name,
        },
      };

      // KAuthUser 생성
      final user = KAuthUser.fromKakao(rawData);

      return AuthResult.success(
        provider: AuthProvider.kakao,
        user: user,
        accessToken: token.accessToken,
        refreshToken: token.refreshToken,
        idToken: token.idToken,
        expiresAt: token.expiresAt,
        rawData: rawData,
      );
    } on kakao.KakaoAuthException catch (e) {
      final error = KAuthError.fromCode(
        ErrorCodes.tokenExpired,
        details: {'kakaoError': e.message},
        originalError: e,
      );
      return AuthResult.failure(
        provider: AuthProvider.kakao,
        errorMessage: '카카오 토큰 갱신 실패: ${e.message}',
        errorCode: error.code,
        errorHint: error.hint,
      );
    } catch (e) {
      final error = KAuthError.fromCode(
        ErrorCodes.tokenExpired,
        originalError: e,
      );
      return AuthResult.failure(
        provider: AuthProvider.kakao,
        errorMessage: '카카오 토큰 갱신 중 오류 발생: $e',
        errorCode: error.code,
        errorHint: error.hint,
      );
    }
  }
}
