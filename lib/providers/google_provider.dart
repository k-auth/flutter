import 'package:google_sign_in/google_sign_in.dart';

import '../models/auth_config.dart';
import '../models/auth_result.dart';
import '../models/k_auth_user.dart';
import '../errors/k_auth_error.dart';

/// 구글 로그인 Provider
class GoogleProvider {
  final GoogleConfig config;
  late final GoogleSignIn _googleSignIn;

  GoogleProvider(this.config) {
    _googleSignIn = GoogleSignIn(
      clientId: config.iosClientId,
      serverClientId: config.serverClientId,
      scopes: config.allScopes,
      forceCodeForRefreshToken: config.forceConsent,
    );
  }

  /// 구글 로그인 실행
  Future<AuthResult> signIn() async {
    try {
      final account = await _googleSignIn.signIn();

      if (account == null) {
        final error = KAuthError.fromCode(ErrorCodes.userCancelled);
        return AuthResult.failure(
          provider: AuthProvider.google,
          errorMessage: error.message,
          errorCode: error.code,
          errorHint: error.hint,
        );
      }

      final auth = await account.authentication;

      // 원본 데이터 구성
      final rawData = <String, dynamic>{
        'id': account.id,
        'email': account.email,
        'displayName': account.displayName,
        'photoUrl': account.photoUrl,
        'serverAuthCode': account.serverAuthCode,
        'idToken': auth.idToken,
      };

      // KAuthUser 생성
      final user = KAuthUser.fromGoogle(rawData);

      return AuthResult.success(
        provider: AuthProvider.google,
        user: user,
        accessToken: auth.accessToken,
        idToken: auth.idToken,
        rawData: rawData,
      );
    } catch (e) {
      final error = KAuthError.fromCode(
        ErrorCodes.googleSignInFailed,
        originalError: e,
      );
      return AuthResult.failure(
        provider: AuthProvider.google,
        errorMessage: '구글 로그인 중 오류 발생: $e',
        errorCode: error.code,
        errorHint: error.hint,
      );
    }
  }

  /// 구글 로그아웃
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      throw KAuthError(
        code: ErrorCodes.loginFailed,
        message: '구글 로그아웃 실패: $e',
        originalError: e,
      );
    }
  }

  /// 구글 연결 해제 (탈퇴)
  Future<void> unlink() async {
    try {
      await _googleSignIn.disconnect();
    } catch (e) {
      throw KAuthError(
        code: ErrorCodes.loginFailed,
        message: '구글 연결 해제 실패: $e',
        originalError: e,
      );
    }
  }
}
