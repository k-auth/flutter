import 'package:flutter_naver_login/flutter_naver_login.dart';
import 'package:flutter_naver_login/interface/types/naver_account_result.dart';
import 'package:flutter_naver_login/interface/types/naver_login_status.dart';
import 'package:flutter_naver_login/interface/types/naver_token.dart';

import '../errors/error_mapper.dart';
import '../errors/k_auth_error.dart';
import '../models/auth_config.dart';
import '../models/auth_result.dart';
import '../models/k_auth_user.dart';
import 'base_auth_provider.dart';

/// 네이버 로그인 Provider
class NaverProvider implements BaseAuthProvider {
  final NaverConfig config;

  NaverProvider(this.config);

  /// 네이버 SDK 초기화 (별도 초기화 필요 없음)
  @override
  Future<void> initialize() async {}

  /// 사용자 정보로 AuthResult 생성
  AuthResult _buildResult(NaverAccountResult account, NaverToken token) {
    DateTime? expiresAt;
    if (token.expiresAt.isNotEmpty) {
      expiresAt = DateTime.tryParse(token.expiresAt);
    }

    final rawData = <String, dynamic>{
      'response': {
        'id': account.id,
        'email': account.email,
        'name': account.name,
        'nickname': account.nickname,
        'profile_image': account.profileImage,
        'gender': account.gender,
        'age': account.age,
        'birthday': account.birthday,
        'birthyear': account.birthYear,
        'mobile': account.mobile,
      },
    };

    return AuthResult.success(
      provider: AuthProvider.naver,
      user: KAuthUser.fromNaver(rawData),
      accessToken: token.accessToken,
      expiresAt: expiresAt,
      rawData: rawData,
    );
  }

  /// 네이버 로그인 실행
  @override
  Future<AuthResult> signIn() async {
    try {
      final result = await FlutterNaverLogin.logIn();

      if (result.status == NaverLoginStatus.error) {
        return ErrorMapper.toFailure(
          AuthProvider.naver,
          ErrorMapper.naver(result.errorMessage ?? ''),
        );
      }

      if (result.status == NaverLoginStatus.loggedOut) {
        return ErrorMapper.toFailure(
          AuthProvider.naver,
          KAuthError.fromCode(ErrorCodes.userCancelled),
        );
      }

      // null 체크: account가 없으면 실패
      final account = result.account;
      if (account == null) {
        return ErrorMapper.toFailure(
          AuthProvider.naver,
          KAuthError.fromCode(ErrorCodes.userInfoError),
        );
      }

      final token = await FlutterNaverLogin.getCurrentAccessToken();
      return _buildResult(account, token);
    } catch (e) {
      return ErrorMapper.handleException(
        AuthProvider.naver,
        e,
        operation: '로그인',
      );
    }
  }

  /// 네이버 로그아웃
  @override
  Future<AuthResult> signOut() async {
    try {
      await FlutterNaverLogin.logOut();
      return AuthResult.success(provider: AuthProvider.naver, user: null);
    } catch (e) {
      return ErrorMapper.handleException(
        AuthProvider.naver,
        e,
        operation: '로그아웃',
        errorCode: ErrorCodes.signOutFailed,
      );
    }
  }

  /// 네이버 연결 해제 (탈퇴)
  @override
  Future<AuthResult> unlink() async {
    try {
      await FlutterNaverLogin.logOutAndDeleteToken();
      return AuthResult.success(provider: AuthProvider.naver, user: null);
    } catch (e) {
      return ErrorMapper.handleException(
        AuthProvider.naver,
        e,
        operation: '연결 해제',
        errorCode: ErrorCodes.unlinkFailed,
      );
    }
  }

  /// 네이버 토큰 갱신
  ///
  /// 네이버 SDK는 자동 토큰 갱신을 지원합니다.
  @override
  Future<AuthResult> refreshToken() async {
    try {
      final token = await FlutterNaverLogin.getCurrentAccessToken();

      if (token.accessToken.isEmpty) {
        return ErrorMapper.toFailure(
          AuthProvider.naver,
          KAuthError.fromCode(ErrorCodes.tokenExpired),
        );
      }

      final account = await FlutterNaverLogin.getCurrentAccount();
      return _buildResult(account, token);
    } catch (e) {
      return ErrorMapper.handleException(
        AuthProvider.naver,
        e,
        operation: '토큰 갱신',
        errorCode: ErrorCodes.refreshFailed,
      );
    }
  }
}
