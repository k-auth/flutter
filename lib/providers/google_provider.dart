import 'package:google_sign_in/google_sign_in.dart';

import '../models/auth_config.dart';
import '../models/auth_result.dart';
import '../models/k_auth_user.dart';
import '../errors/k_auth_error.dart';

/// 구글 로그인 Provider
class GoogleProvider {
  final GoogleConfig config;
  bool _initialized = false;

  GoogleProvider(this.config);

  /// Provider 초기화
  Future<void> initialize() async {
    if (_initialized) return;

    await GoogleSignIn.instance.initialize(
      clientId: config.iosClientId,
      serverClientId: config.serverClientId,
    );
    _initialized = true;
  }

  /// 구글 로그인 실행
  Future<AuthResult> signIn() async {
    try {
      if (!_initialized) {
        await initialize();
      }

      // 먼저 조용한 로그인 시도
      GoogleSignInAccount? account =
          await GoogleSignIn.instance.attemptLightweightAuthentication();

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

      // 인증 토큰 가져오기
      final auth = account.authentication;

      // accessToken을 위한 authorization 요청
      String? accessToken;
      if (config.allScopes.isNotEmpty) {
        final authorization = await account.authorizationClient
            .authorizationForScopes(config.allScopes);
        accessToken = authorization?.accessToken;
      }

      // 원본 데이터 구성
      final rawData = <String, dynamic>{
        'id': account.id,
        'email': account.email,
        'displayName': account.displayName,
        'photoUrl': account.photoUrl,
        'idToken': auth.idToken,
        'accessToken': accessToken,
      };

      // KAuthUser 생성
      final user = KAuthUser.fromGoogle(rawData);

      return AuthResult.success(
        provider: AuthProvider.google,
        user: user,
        accessToken: accessToken,
        idToken: auth.idToken,
        rawData: rawData,
      );
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        final error = KAuthError.fromCode(ErrorCodes.userCancelled);
        return AuthResult.failure(
          provider: AuthProvider.google,
          errorMessage: error.message,
          errorCode: error.code,
          errorHint: error.hint,
        );
      }

      final error = KAuthError.fromCode(
        ErrorCodes.googleSignInFailed,
        originalError: e,
      );
      return AuthResult.failure(
        provider: AuthProvider.google,
        errorMessage: '구글 로그인 중 오류 발생: ${e.description ?? e.code}',
        errorCode: error.code,
        errorHint: error.hint,
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
      await GoogleSignIn.instance.signOut();
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
      await GoogleSignIn.instance.disconnect();
    } catch (e) {
      throw KAuthError(
        code: ErrorCodes.loginFailed,
        message: '구글 연결 해제 실패: $e',
        originalError: e,
      );
    }
  }

  /// 구글 토큰 갱신 (조용한 로그인)
  ///
  /// UI 없이 기존 세션으로 로그인을 시도합니다.
  Future<AuthResult> refreshToken() async {
    try {
      if (!_initialized) {
        await initialize();
      }

      final account =
          await GoogleSignIn.instance.attemptLightweightAuthentication();

      if (account == null) {
        final error = KAuthError.fromCode(ErrorCodes.tokenExpired);
        return AuthResult.failure(
          provider: AuthProvider.google,
          errorMessage: error.message,
          errorCode: error.code,
          errorHint: '다시 로그인해주세요.',
        );
      }

      final auth = account.authentication;

      // accessToken을 위한 authorization 요청
      String? accessToken;
      if (config.allScopes.isNotEmpty) {
        final authorization = await account.authorizationClient
            .authorizationForScopes(config.allScopes);
        accessToken = authorization?.accessToken;
      }

      // 원본 데이터 구성
      final rawData = <String, dynamic>{
        'id': account.id,
        'email': account.email,
        'displayName': account.displayName,
        'photoUrl': account.photoUrl,
        'idToken': auth.idToken,
        'accessToken': accessToken,
      };

      // KAuthUser 생성
      final user = KAuthUser.fromGoogle(rawData);

      return AuthResult.success(
        provider: AuthProvider.google,
        user: user,
        accessToken: accessToken,
        idToken: auth.idToken,
        rawData: rawData,
      );
    } catch (e) {
      final error = KAuthError.fromCode(
        ErrorCodes.tokenExpired,
        originalError: e,
      );
      return AuthResult.failure(
        provider: AuthProvider.google,
        errorMessage: '구글 토큰 갱신 중 오류 발생: $e',
        errorCode: error.code,
        errorHint: error.hint,
      );
    }
  }
}
