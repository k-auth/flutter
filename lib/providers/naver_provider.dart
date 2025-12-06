import 'package:flutter_naver_login/flutter_naver_login.dart';
import 'package:flutter_naver_login/interface/types/naver_login_status.dart';

import '../models/auth_config.dart';
import '../models/auth_result.dart';
import '../models/k_auth_user.dart';
import '../errors/k_auth_error.dart';
import 'base_auth_provider.dart';

/// 네이버 로그인 Provider
class NaverProvider implements BaseAuthProvider {
  final NaverConfig config;

  NaverProvider(this.config);

  /// 네이버 SDK 초기화 (별도 초기화 필요 없음)
  @override
  Future<void> initialize() async {}

  /// 네이버 로그인 실행
  @override
  Future<AuthResult> signIn() async {
    try {
      final result = await FlutterNaverLogin.logIn();

      if (result.status == NaverLoginStatus.error) {
        final errorMsg = result.errorMessage ?? '네이버 로그인 실패';
        final error = KAuthError.fromCode(
          ErrorCodes.loginFailed,
          details: {'naverError': errorMsg},
        );
        return AuthResult.failure(
          provider: AuthProvider.naver,
          errorMessage: errorMsg,
          errorCode: error.code,
          errorHint: error.hint,
        );
      }

      if (result.status == NaverLoginStatus.loggedOut) {
        final error = KAuthError.fromCode(ErrorCodes.userCancelled);
        return AuthResult.failure(
          provider: AuthProvider.naver,
          errorMessage: error.message,
          errorCode: error.code,
          errorHint: error.hint,
        );
      }

      // 토큰 정보 조회
      final token = await FlutterNaverLogin.getCurrentAccessToken();

      // expiresAt 파싱 (String -> DateTime)
      DateTime? expiresAt;
      if (token.expiresAt.isNotEmpty) {
        expiresAt = DateTime.tryParse(token.expiresAt);
      }

      // 사용자 정보
      final account = result.account;

      // 원본 데이터 구성
      final rawData = <String, dynamic>{
        'response': {
          'id': account?.id,
          'email': account?.email,
          'name': account?.name,
          'nickname': account?.nickname,
          'profile_image': account?.profileImage,
          'gender': account?.gender,
          'age': account?.age,
          'birthday': account?.birthday,
          'birthyear': account?.birthYear,
          'mobile': account?.mobile,
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
  @override
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
  @override
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

  /// 네이버 토큰 갱신
  ///
  /// 네이버 SDK는 자동 토큰 갱신을 지원합니다.
  /// 이 메서드는 현재 토큰 상태를 확인하고 필요시 갱신합니다.
  @override
  Future<AuthResult> refreshToken() async {
    try {
      // 현재 토큰 상태 확인 (SDK가 자동으로 갱신)
      final token = await FlutterNaverLogin.getCurrentAccessToken();

      if (token.accessToken.isEmpty) {
        final error = KAuthError.fromCode(ErrorCodes.tokenExpired);
        return AuthResult.failure(
          provider: AuthProvider.naver,
          errorMessage: error.message,
          errorCode: error.code,
          errorHint: '다시 로그인해주세요.',
        );
      }

      // 사용자 정보 조회
      final account = await FlutterNaverLogin.getCurrentAccount();

      // expiresAt 파싱
      DateTime? expiresAt;
      if (token.expiresAt.isNotEmpty) {
        expiresAt = DateTime.tryParse(token.expiresAt);
      }

      // 원본 데이터 구성
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
        ErrorCodes.tokenExpired,
        originalError: e,
      );
      return AuthResult.failure(
        provider: AuthProvider.naver,
        errorMessage: '네이버 토큰 갱신 중 오류 발생: $e',
        errorCode: error.code,
        errorHint: error.hint,
      );
    }
  }
}
