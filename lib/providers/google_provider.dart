import 'package:google_sign_in/google_sign_in.dart';

import '../models/auth_config.dart';
import '../models/auth_result.dart';
import '../errors/k_auth_error.dart';

/// 구글 로그인 Provider
class GoogleProvider {
  final GoogleConfig config;
  late final GoogleSignIn _googleSignIn;

  GoogleProvider(this.config) {
    _googleSignIn = GoogleSignIn(
      clientId: config.iosClientId,
      serverClientId: config.serverClientId,
      scopes: config.scopes ?? ['email', 'profile'],
    );
  }

  /// 구글 로그인 실행
  Future<AuthResult> signIn() async {
    try {
      final account = await _googleSignIn.signIn();

      if (account == null) {
        return AuthResult.failure(
          provider: AuthProvider.google,
          errorMessage: ErrorMessages.getMessage(ErrorCodes.userCancelled),
          errorCode: ErrorCodes.userCancelled,
        );
      }

      final auth = await account.authentication;

      return AuthResult.success(
        provider: AuthProvider.google,
        userId: account.id,
        email: account.email,
        name: account.displayName,
        profileImageUrl: account.photoUrl,
        accessToken: auth.accessToken,
        rawData: {
          'id': account.id,
          'email': account.email,
          'displayName': account.displayName,
          'photoUrl': account.photoUrl,
          'serverAuthCode': account.serverAuthCode,
          'idToken': auth.idToken,
        },
      );
    } catch (e) {
      return AuthResult.failure(
        provider: AuthProvider.google,
        errorMessage: '구글 로그인 중 오류 발생: $e',
        errorCode: ErrorCodes.loginFailed,
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
