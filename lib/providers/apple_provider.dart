import 'dart:io';

import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../models/auth_config.dart';
import '../models/auth_result.dart';
import '../errors/k_auth_error.dart';

/// 애플 로그인 Provider
class AppleProvider {
  final AppleConfig config;

  AppleProvider(this.config);

  /// 애플 로그인 지원 여부 확인
  Future<bool> isAvailable() async {
    if (!Platform.isIOS && !Platform.isMacOS) {
      return false;
    }
    return await SignInWithApple.isAvailable();
  }

  /// 애플 로그인 실행
  Future<AuthResult> signIn() async {
    try {
      // 플랫폼 지원 확인
      if (!await isAvailable()) {
        return AuthResult.failure(
          provider: AuthProvider.apple,
          errorMessage: ErrorMessages.getMessage(ErrorCodes.platformNotSupported),
          errorCode: ErrorCodes.platformNotSupported,
        );
      }

      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      // 이름 조합
      String? fullName;
      if (credential.givenName != null || credential.familyName != null) {
        fullName = [credential.familyName, credential.givenName]
            .where((s) => s != null && s.isNotEmpty)
            .join(' ');
        if (fullName.isEmpty) fullName = null;
      }

      return AuthResult.success(
        provider: AuthProvider.apple,
        userId: credential.userIdentifier ?? '',
        email: credential.email,
        name: fullName,
        accessToken: credential.authorizationCode,
        rawData: {
          'userIdentifier': credential.userIdentifier,
          'email': credential.email,
          'givenName': credential.givenName,
          'familyName': credential.familyName,
          'authorizationCode': credential.authorizationCode,
          'identityToken': credential.identityToken,
          'state': credential.state,
        },
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        return AuthResult.failure(
          provider: AuthProvider.apple,
          errorMessage: ErrorMessages.getMessage(ErrorCodes.userCancelled),
          errorCode: ErrorCodes.userCancelled,
        );
      }
      return AuthResult.failure(
        provider: AuthProvider.apple,
        errorMessage: '애플 로그인 실패: ${e.message}',
        errorCode: ErrorCodes.loginFailed,
      );
    } catch (e) {
      return AuthResult.failure(
        provider: AuthProvider.apple,
        errorMessage: '애플 로그인 중 오류 발생: $e',
        errorCode: ErrorCodes.loginFailed,
      );
    }
  }

  /// 애플 로그아웃 (클라이언트에서 세션만 정리)
  Future<void> signOut() async {
    // 애플은 별도의 로그아웃 API가 없음
    // 앱에서 저장된 토큰/세션만 정리하면 됨
  }
}
