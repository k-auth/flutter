import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../models/auth_config.dart';
import '../models/auth_result.dart';
import '../models/k_auth_user.dart';
import '../errors/k_auth_error.dart';
import 'base_auth_provider.dart';

/// 애플 로그인 Provider
class AppleProvider implements BaseAuthProvider {
  final AppleConfig config;

  AppleProvider(this.config);

  /// 애플 로그인 지원 여부 확인
  Future<bool> isAvailable() async {
    if (!Platform.isIOS && !Platform.isMacOS) {
      return false;
    }
    return await SignInWithApple.isAvailable();
  }

  /// 초기화 (별도 초기화 필요 없음)
  @override
  Future<void> initialize() async {}

  /// 애플 로그인 실행
  @override
  Future<AuthResult> signIn() async {
    try {
      // 플랫폼 지원 확인
      if (!await isAvailable()) {
        final error = KAuthError.fromCode(ErrorCodes.appleNotSupported);
        return AuthResult.failure(
          provider: AuthProvider.apple,
          errorMessage: error.message,
          errorCode: error.code,
          errorHint: error.hint,
        );
      }

      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          if (config.collect.email) AppleIDAuthorizationScopes.email,
          if (config.collect.fullName) AppleIDAuthorizationScopes.fullName,
        ],
      );

      // 원본 데이터 구성
      final rawData = <String, dynamic>{
        'userIdentifier': credential.userIdentifier,
        'email': credential.email,
        'givenName': credential.givenName,
        'familyName': credential.familyName,
        'authorizationCode': credential.authorizationCode,
        'identityToken': credential.identityToken,
        'state': credential.state,
      };

      // KAuthUser 생성
      final user = KAuthUser.fromApple(rawData);

      return AuthResult.success(
        provider: AuthProvider.apple,
        user: user,
        accessToken: credential.authorizationCode,
        idToken: credential.identityToken,
        rawData: rawData,
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        final error = KAuthError.fromCode(ErrorCodes.userCancelled);
        return AuthResult.failure(
          provider: AuthProvider.apple,
          errorMessage: error.message,
          errorCode: error.code,
          errorHint: error.hint,
        );
      }
      final error = KAuthError.fromCode(
        ErrorCodes.appleSignInFailed,
        details: {'appleError': e.message},
        originalError: e,
      );
      return AuthResult.failure(
        provider: AuthProvider.apple,
        errorMessage: '애플 로그인 실패: ${e.message}',
        errorCode: error.code,
        errorHint: error.hint,
      );
    } catch (e) {
      final error = KAuthError.fromCode(
        ErrorCodes.appleSignInFailed,
        originalError: e,
      );
      return AuthResult.failure(
        provider: AuthProvider.apple,
        errorMessage: kDebugMode ? '애플 로그인 실패: $e' : '애플 로그인 실패',
        errorCode: error.code,
        errorHint: error.hint,
      );
    }
  }

  /// 애플 로그아웃 (클라이언트에서 세션만 정리)
  @override
  Future<AuthResult> signOut() async {
    // 애플은 별도의 로그아웃 API가 없음
    // 앱에서 저장된 토큰/세션만 정리하면 됨
    return AuthResult.success(
      provider: AuthProvider.apple,
      user: null,
    );
  }

  /// 애플 연결 해제 (서버사이드에서만 가능)
  @override
  Future<AuthResult> unlink() async {
    // Apple은 클라이언트에서 연결 해제를 지원하지 않음
    // 서버에서 Apple REST API를 통해 처리해야 함
    return AuthResult.failure(
      provider: AuthProvider.apple,
      errorMessage:
          'Apple은 클라이언트에서 연결 해제를 지원하지 않습니다. 서버에서 Apple REST API를 통해 처리하세요.',
      errorCode: ErrorCodes.providerNotSupported,
      errorHint:
          'https://developer.apple.com/documentation/sign_in_with_apple/revoke_tokens',
    );
  }

  /// 애플 토큰 갱신 (지원하지 않음)
  @override
  Future<AuthResult> refreshToken() async {
    return AuthResult.failure(
      provider: AuthProvider.apple,
      errorMessage: 'Apple은 토큰 갱신을 지원하지 않습니다.',
      errorCode: ErrorCodes.providerNotSupported,
    );
  }
}
