import 'package:google_sign_in/google_sign_in.dart';

import '../errors/error_mapper.dart';
import '../errors/k_auth_error.dart';
import '../models/auth_config.dart';
import '../models/auth_result.dart';
import '../models/k_auth_user.dart';
import 'base_auth_provider.dart';

/// 구글 로그인 Provider
///
/// Google Sign-In을 위한 Provider입니다.
///
/// ## 주요 제약사항
///
/// ### 1. iOS에서 iosClientId 필수
/// iOS 플랫폼에서는 반드시 `iosClientId`가 필요합니다.
/// Google Cloud Console에서 iOS OAuth 2.0 클라이언트 ID를 생성하세요.
///
/// ```dart
/// GoogleConfig(
///   iosClientId: 'xxx.apps.googleusercontent.com',  // iOS 필수
///   serverClientId: 'xxx.apps.googleusercontent.com',  // 백엔드 연동 시
/// )
/// ```
///
/// ### 2. refreshToken 미제공
/// Google Sign-In은 **refresh token을 클라이언트에 제공하지 않습니다**.
/// `refreshToken()` 호출 시 silent sign-in을 시도합니다.
///
/// ```dart
/// // UI 없이 기존 세션으로 로그인 시도
/// final result = await kAuth.refreshToken(AuthProvider.google);
///
/// // 실패하면 다시 로그인 필요
/// if (!result.success) {
///   await kAuth.signIn(AuthProvider.google);
/// }
/// ```
///
/// ### 3. 서버 연동 시 serverClientId 설정
/// 백엔드에서 토큰을 검증하려면 `serverClientId`가 필요합니다.
///
/// ```dart
/// GoogleConfig(
///   serverClientId: 'xxx.apps.googleusercontent.com',  // 웹 클라이언트 ID
/// )
/// ```
///
/// ### 4. 플랫폼별 설정
///
/// **iOS** (`ios/Runner/Info.plist`)
/// ```xml
/// <key>GIDClientID</key>
/// <string>YOUR_IOS_CLIENT_ID</string>
/// <key>CFBundleURLTypes</key>
/// <array>
///   <dict>
///     <key>CFBundleURLSchemes</key>
///     <array>
///       <string>com.googleusercontent.apps.YOUR_CLIENT_ID</string>
///     </array>
///   </dict>
/// </array>
/// ```
///
/// **Android** (`android/app/build.gradle`)
/// - google-services.json 파일 추가
/// - SHA-1 인증서 지문 등록
///
/// ## 토큰 구조
///
/// | 토큰 | 설명 |
/// |-----|------|
/// | `accessToken` | OAuth 액세스 토큰 (scope 요청 시에만) |
/// | `idToken` | JWT 형식의 ID 토큰 (사용자 정보 포함) |
/// | `refreshToken` | 미제공 (서버에서 관리 필요) |
///
/// ## 사용 예제
///
/// ```dart
/// final result = await kAuth.signIn(AuthProvider.google);
/// result.fold(
///   onSuccess: (user) {
///     print('이름: ${user.displayName}');
///     print('이메일: ${user.email}');
///     print('프로필: ${user.avatar}');
///     // 백엔드로 idToken 전송
///     await myServer.verifyGoogleToken(result.idToken!);
///   },
///   onFailure: (failure) => print(failure.message),
/// );
/// ```
class GoogleProvider implements BaseAuthProvider {
  final GoogleConfig config;
  bool _initialized = false;

  GoogleProvider(this.config);

  /// Provider 초기화
  @override
  Future<void> initialize() async {
    if (_initialized) return;

    await GoogleSignIn.instance.initialize(
      clientId: config.iosClientId,
      serverClientId: config.serverClientId,
    );
    _initialized = true;
  }

  /// 사용자 정보로 AuthResult 생성
  Future<AuthResult> _buildResult(GoogleSignInAccount account) async {
    final auth = account.authentication;

    String? accessToken;
    if (config.allScopes.isNotEmpty) {
      final authorization = await account.authorizationClient
          .authorizationForScopes(config.allScopes);
      accessToken = authorization?.accessToken;
    }

    final rawData = <String, dynamic>{
      'id': account.id,
      'email': account.email,
      'displayName': account.displayName,
      'photoUrl': account.photoUrl,
      'idToken': auth.idToken,
      'accessToken': accessToken,
    };

    return AuthResult.success(
      provider: AuthProvider.google,
      user: KAuthUser.fromGoogle(rawData),
      accessToken: accessToken,
      idToken: auth.idToken,
      rawData: rawData,
    );
  }

  /// 구글 로그인 실행
  @override
  Future<AuthResult> signIn() async {
    try {
      if (!_initialized) await initialize();

      // 먼저 조용한 로그인 시도
      var account =
          await GoogleSignIn.instance.attemptLightweightAuthentication();

      // 실패하면 전체 로그인 플로우
      if (account == null) {
        if (!GoogleSignIn.instance.supportsAuthenticate()) {
          return ErrorMapper.toFailure(
            AuthProvider.google,
            KAuthError.fromCode(ErrorCodes.platformNotSupported),
          );
        }
        account = await GoogleSignIn.instance.authenticate();
      }

      return _buildResult(account);
    } on GoogleSignInException catch (e) {
      return ErrorMapper.toFailure(AuthProvider.google, ErrorMapper.google(e));
    } catch (e) {
      return ErrorMapper.handleException(
        AuthProvider.google,
        e,
        operation: '로그인',
        errorCode: ErrorCodes.googleSignInFailed,
      );
    }
  }

  /// 구글 로그아웃
  @override
  Future<AuthResult> signOut() async {
    try {
      await GoogleSignIn.instance.signOut();
      return AuthResult.success(provider: AuthProvider.google, user: null);
    } catch (e) {
      return ErrorMapper.handleException(
        AuthProvider.google,
        e,
        operation: '로그아웃',
        errorCode: ErrorCodes.signOutFailed,
      );
    }
  }

  /// 구글 연결 해제 (탈퇴)
  @override
  Future<AuthResult> unlink() async {
    try {
      await GoogleSignIn.instance.disconnect();
      return AuthResult.success(provider: AuthProvider.google, user: null);
    } catch (e) {
      return ErrorMapper.handleException(
        AuthProvider.google,
        e,
        operation: '연결 해제',
        errorCode: ErrorCodes.unlinkFailed,
      );
    }
  }

  /// 구글 토큰 갱신 (조용한 로그인)
  ///
  /// UI 없이 기존 세션으로 로그인을 시도합니다.
  @override
  Future<AuthResult> refreshToken() async {
    try {
      if (!_initialized) await initialize();

      final account =
          await GoogleSignIn.instance.attemptLightweightAuthentication();

      if (account == null) {
        return ErrorMapper.toFailure(
          AuthProvider.google,
          KAuthError.fromCode(ErrorCodes.tokenExpired),
        );
      }

      return _buildResult(account);
    } catch (e) {
      return ErrorMapper.handleException(
        AuthProvider.google,
        e,
        operation: '토큰 갱신',
        errorCode: ErrorCodes.refreshFailed,
      );
    }
  }
}
