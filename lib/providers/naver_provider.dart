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
///
/// 네이버 소셜 로그인을 위한 Provider입니다.
///
/// ## 주요 제약사항
///
/// ### 1. scope 미지원
/// 네이버 SDK는 **scope 파라미터를 지원하지 않습니다**.
/// 수집 항목은 네이버 개발자센터에서 직접 설정해야 합니다.
///
/// - 설정 위치: 애플리케이션 > API 설정 > 회원이름/연락처 등
/// - 문서: https://developers.naver.com/apps
///
/// ```dart
/// // ❌ scope 파라미터가 없음
/// NaverConfig(
///   clientId: 'xxx',
///   clientSecret: 'xxx',
///   appName: 'My App',
///   // scope: ['email', 'name'],  // 미지원!
/// )
/// ```
///
/// ### 2. 자동 토큰 갱신
/// 네이버 SDK는 토큰을 **자동으로 갱신**합니다.
/// `refreshToken()` 호출 시 현재 유효한 토큰을 반환합니다.
///
/// ```dart
/// // SDK가 자동으로 갱신하므로 직접 갱신할 필요 없음
/// final result = await kAuth.refreshToken(AuthProvider.naver);
/// // 현재 유효한 토큰 반환
/// ```
///
/// ### 3. 플랫폼별 설정
///
/// **Android** (`android/app/src/main/AndroidManifest.xml`)
/// ```xml
/// <application>
///   <meta-data
///     android:name="com.naver.sdk.clientId"
///     android:value="YOUR_CLIENT_ID" />
///   <meta-data
///     android:name="com.naver.sdk.clientSecret"
///     android:value="YOUR_CLIENT_SECRET" />
///   <meta-data
///     android:name="com.naver.sdk.clientName"
///     android:value="YOUR_APP_NAME" />
/// </application>
/// ```
///
/// **iOS** (`ios/Runner/Info.plist`)
/// ```xml
/// <key>NidConsumerKey</key>
/// <string>YOUR_CLIENT_ID</string>
/// <key>NidConsumerSecret</key>
/// <string>YOUR_CLIENT_SECRET</string>
/// <key>NidAppName</key>
/// <string>YOUR_APP_NAME</string>
/// <key>LSApplicationQueriesSchemes</key>
/// <array>
///   <string>naversearchapp</string>
///   <string>naversearchthirdlogin</string>
/// </array>
/// ```
///
/// ## 토큰 구조
///
/// | 토큰 | 설명 |
/// |-----|------|
/// | `accessToken` | OAuth 액세스 토큰 |
/// | `refreshToken` | SDK 내부 관리 (접근 불가) |
/// | `expiresAt` | 토큰 만료 시간 |
///
/// ## 사용 예제
///
/// ```dart
/// final result = await kAuth.signIn(AuthProvider.naver);
/// result.fold(
///   onSuccess: (user) {
///     print('이름: ${user.displayName}');
///     print('이메일: ${user.email}');
///     print('프로필: ${user.avatar}');
///   },
///   onFailure: (failure) => print(failure.message),
/// );
/// ```
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
