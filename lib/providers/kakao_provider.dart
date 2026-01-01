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

  /// 사용자 정보로 AuthResult 생성
  AuthResult _buildResult(kakao.OAuthToken token, kakao.User user) {
    final rawData = <String, dynamic>{
      'id': user.id,
      'kakao_account': {
        'email': user.kakaoAccount?.email,
        'profile': {
          'nickname': user.kakaoAccount?.profile?.nickname,
          'profile_image_url': user.kakaoAccount?.profile?.profileImageUrl,
        },
        'phone_number': user.kakaoAccount?.phoneNumber,
        'birthday': user.kakaoAccount?.birthday,
        'birthyear': user.kakaoAccount?.birthyear,
        'gender': user.kakaoAccount?.gender?.name,
        'age_range': user.kakaoAccount?.ageRange?.name,
      },
    };

    return AuthResult.success(
      provider: AuthProvider.kakao,
      user: KAuthUser.fromKakao(rawData),
      accessToken: token.accessToken,
      refreshToken: token.refreshToken,
      idToken: token.idToken,
      expiresAt: token.expiresAt,
      rawData: rawData,
    );
  }

  /// 카카오 로그인 실행
  @override
  Future<AuthResult> signIn() async {
    try {
      final token = await kakao.isKakaoTalkInstalled()
          ? await kakao.UserApi.instance.loginWithKakaoTalk()
          : await kakao.UserApi.instance.loginWithKakaoAccount();

      final user = await kakao.UserApi.instance.me();
      return _buildResult(token, user);
    } on kakao.KakaoAuthException catch (e) {
      return ErrorMapper.toFailure(
          AuthProvider.kakao, ErrorMapper.kakaoAuth(e));
    } on kakao.KakaoApiException catch (e) {
      return ErrorMapper.toFailure(AuthProvider.kakao, ErrorMapper.kakaoApi(e));
    } catch (e) {
      return ErrorMapper.handleException(
        AuthProvider.kakao,
        e,
        operation: '로그인',
      );
    }
  }

  /// 카카오 로그아웃
  @override
  Future<AuthResult> signOut() async {
    try {
      await kakao.UserApi.instance.logout();
      return AuthResult.success(provider: AuthProvider.kakao, user: null);
    } catch (e) {
      return ErrorMapper.handleException(
        AuthProvider.kakao,
        e,
        operation: '로그아웃',
        errorCode: ErrorCodes.signOutFailed,
      );
    }
  }

  /// 카카오 연결 해제 (탈퇴)
  @override
  Future<AuthResult> unlink() async {
    try {
      await kakao.UserApi.instance.unlink();
      return AuthResult.success(provider: AuthProvider.kakao, user: null);
    } catch (e) {
      return ErrorMapper.handleException(
        AuthProvider.kakao,
        e,
        operation: '연결 해제',
        errorCode: ErrorCodes.unlinkFailed,
      );
    }
  }

  /// 카카오 토큰 갱신
  @override
  Future<AuthResult> refreshToken() async {
    try {
      final token = await kakao.AuthApi.instance.refreshToken();
      final user = await kakao.UserApi.instance.me();
      return _buildResult(token, user);
    } on kakao.KakaoAuthException catch (e) {
      return ErrorMapper.toFailure(
          AuthProvider.kakao, ErrorMapper.kakaoAuth(e));
    } catch (e) {
      return ErrorMapper.handleException(
        AuthProvider.kakao,
        e,
        operation: '토큰 갱신',
        errorCode: ErrorCodes.refreshFailed,
      );
    }
  }
}
