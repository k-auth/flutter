import 'package:flutter/foundation.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart' as kakao;

import '../errors/error_mapper.dart';
import '../errors/k_auth_error.dart';
import '../models/auth_config.dart';
import '../models/auth_result.dart';
import '../models/k_auth_user.dart';
import 'base_auth_provider.dart';

/// 카카오 로그인 Provider
class KakaoProvider implements BaseAuthProvider {
  final KakaoConfig config;

  KakaoProvider(this.config);

  /// 카카오 SDK 초기화
  @override
  Future<void> initialize() async {
    kakao.KakaoSdk.init(nativeAppKey: config.appKey);
  }

  /// 카카오 로그인 실행
  @override
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
      final err = ErrorMapper.kakaoAuth(e);
      return AuthResult.failure(
        provider: AuthProvider.kakao,
        errorMessage: err.message,
        errorCode: err.code,
        errorHint: err.hint,
      );
    } on kakao.KakaoApiException catch (e) {
      final err = ErrorMapper.kakaoApi(e);
      return AuthResult.failure(
        provider: AuthProvider.kakao,
        errorMessage: err.message,
        errorCode: err.code,
        errorHint: err.hint,
      );
    } catch (e) {
      return AuthResult.failure(
        provider: AuthProvider.kakao,
        errorMessage: kDebugMode ? '카카오 로그인 실패: $e' : '카카오 로그인 실패',
        errorCode: ErrorCodes.loginFailed,
      );
    }
  }

  /// 카카오 로그아웃
  @override
  Future<AuthResult> signOut() async {
    try {
      await kakao.UserApi.instance.logout();
      return AuthResult.success(
        provider: AuthProvider.kakao,
        user: null,
      );
    } catch (e) {
      return AuthResult.failure(
        provider: AuthProvider.kakao,
        errorMessage: kDebugMode ? '카카오 로그아웃 실패: $e' : '카카오 로그아웃 실패',
        errorCode: ErrorCodes.signOutFailed,
      );
    }
  }

  /// 카카오 연결 해제 (탈퇴)
  @override
  Future<AuthResult> unlink() async {
    try {
      await kakao.UserApi.instance.unlink();
      return AuthResult.success(
        provider: AuthProvider.kakao,
        user: null,
      );
    } catch (e) {
      return AuthResult.failure(
        provider: AuthProvider.kakao,
        errorMessage: kDebugMode ? '카카오 연결 해제 실패: $e' : '카카오 연결 해제 실패',
        errorCode: ErrorCodes.unlinkFailed,
      );
    }
  }

  /// 카카오 토큰 갱신
  @override
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
        errorMessage: kDebugMode ? '카카오 토큰 갱신 실패: $e' : '카카오 토큰 갱신 실패',
        errorCode: error.code,
        errorHint: error.hint,
      );
    }
  }
}
