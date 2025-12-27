import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../errors/error_mapper.dart';
import '../errors/k_auth_error.dart';
import '../models/auth_config.dart';
import '../models/auth_result.dart';
import '../models/k_auth_user.dart';
import 'base_auth_provider.dart';

/// 구글 로그인 Provider
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
      var account = await GoogleSignIn.instance.attemptLightweightAuthentication();

      // 실패하면 전체 로그인 플로우
      if (account == null) {
        if (!GoogleSignIn.instance.supportsAuthenticate()) {
          final error = KAuthError.fromCode(ErrorCodes.platformNotSupported);
          return AuthResult.failure(
            provider: AuthProvider.google,
            errorMessage: error.message,
            errorCode: error.code,
            errorHint: error.hint,
          );
        }
        account = await GoogleSignIn.instance.authenticate();
      }

      return _buildResult(account);
    } on GoogleSignInException catch (e) {
      final err = ErrorMapper.google(e);
      return AuthResult.failure(
        provider: AuthProvider.google,
        errorMessage: err.message,
        errorCode: err.code,
        errorHint: err.hint,
      );
    } catch (e) {
      return AuthResult.failure(
        provider: AuthProvider.google,
        errorMessage: kDebugMode ? '구글 로그인 실패: $e' : '구글 로그인 실패',
        errorCode: ErrorCodes.googleSignInFailed,
      );
    }
  }

  /// 구글 로그아웃
  @override
  Future<AuthResult> signOut() async {
    try {
      await GoogleSignIn.instance.signOut();
      return AuthResult.success(
        provider: AuthProvider.google,
        user: null,
      );
    } catch (e) {
      return AuthResult.failure(
        provider: AuthProvider.google,
        errorMessage: kDebugMode ? '구글 로그아웃 실패: $e' : '구글 로그아웃 실패',
        errorCode: ErrorCodes.signOutFailed,
      );
    }
  }

  /// 구글 연결 해제 (탈퇴)
  @override
  Future<AuthResult> unlink() async {
    try {
      await GoogleSignIn.instance.disconnect();
      return AuthResult.success(
        provider: AuthProvider.google,
        user: null,
      );
    } catch (e) {
      return AuthResult.failure(
        provider: AuthProvider.google,
        errorMessage: kDebugMode ? '구글 연결 해제 실패: $e' : '구글 연결 해제 실패',
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

      final account = await GoogleSignIn.instance.attemptLightweightAuthentication();

      if (account == null) {
        final error = KAuthError.fromCode(ErrorCodes.tokenExpired);
        return AuthResult.failure(
          provider: AuthProvider.google,
          errorMessage: error.message,
          errorCode: error.code,
          errorHint: '다시 로그인해주세요.',
        );
      }

      return _buildResult(account);
    } catch (e) {
      final error = KAuthError.fromCode(
        ErrorCodes.tokenExpired,
        originalError: e,
      );
      return AuthResult.failure(
        provider: AuthProvider.google,
        errorMessage: kDebugMode ? '구글 토큰 갱신 실패: $e' : '구글 토큰 갱신 실패',
        errorCode: error.code,
        errorHint: error.hint,
      );
    }
  }
}
