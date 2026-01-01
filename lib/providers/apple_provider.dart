import 'dart:io';

import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../errors/error_mapper.dart';
import '../errors/k_auth_error.dart';
import '../models/auth_config.dart';
import '../models/auth_result.dart';
import '../models/k_auth_user.dart';
import 'base_auth_provider.dart';

/// 애플 로그인 Provider
///
/// Sign in with Apple을 위한 Provider입니다.
///
/// ## 주요 제약사항
///
/// ### 1. 지원 플랫폼
/// - iOS 13+
/// - macOS 10.15+
/// - **Android, Web: 미지원**
///
/// ### 2. 토큰 갱신 불가
/// Apple은 `authorizationCode`를 **일회용**으로 제공합니다.
/// 클라이언트에서 토큰 갱신이 불가능하며, 서버에서 이 코드로
/// refresh token을 발급받아 관리해야 합니다.
///
/// ```dart
/// // ❌ 작동하지 않음
/// await kAuth.refreshToken(AuthProvider.apple);
///
/// // ✅ 서버에서 처리
/// final serverToken = await myServer.exchangeAppleCode(
///   result.accessToken!,  // authorizationCode
/// );
/// ```
///
/// ### 3. 연결 해제는 서버에서만 가능
/// Apple REST API를 통해서만 연결 해제가 가능합니다.
/// - 문서: https://developer.apple.com/documentation/sign_in_with_apple/revoke_tokens
///
/// ```dart
/// // ❌ 에러 반환
/// await kAuth.unlink(AuthProvider.apple);
///
/// // ✅ 서버 API 호출
/// await myServer.revokeAppleToken(userId);
/// ```
///
/// ### 4. 이름은 첫 로그인 시에만 제공
/// 재로그인 시 `givenName`, `familyName`이 **null**입니다.
/// 첫 로그인 시 서버에 저장해두어야 합니다.
///
/// ```dart
/// result.onSuccess((user) {
///   // 첫 로그인이면 이름 저장
///   if (user.displayName != null) {
///     saveNameToServer(user.displayName);
///   }
/// });
/// ```
///
/// ## 토큰 구조
///
/// | 토큰 | 설명 |
/// |-----|------|
/// | `accessToken` | authorizationCode (일회용, 서버 교환용) |
/// | `idToken` | identityToken (JWT, 사용자 정보 포함) |
/// | `refreshToken` | 미제공 |
///
/// ## 사용 예제
///
/// ```dart
/// final result = await kAuth.signIn(AuthProvider.apple);
/// result.fold(
///   onSuccess: (user) {
///     // 첫 로그인이면 이름 저장
///     if (user.displayName != null) {
///       saveToServer(user.displayName);
///     }
///     // authorizationCode로 서버에서 토큰 발급
///     final serverToken = await myServer.exchangeAppleCode(
///       result.accessToken!,
///     );
///   },
///   onFailure: (failure) => print(failure.message),
/// );
/// ```
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
        return ErrorMapper.toFailure(
          AuthProvider.apple,
          KAuthError.fromCode(ErrorCodes.appleNotSupported),
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

      return AuthResult.success(
        provider: AuthProvider.apple,
        user: KAuthUser.fromApple(rawData),
        accessToken: credential.authorizationCode,
        idToken: credential.identityToken,
        rawData: rawData,
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        return ErrorMapper.toFailure(
          AuthProvider.apple,
          KAuthError.fromCode(ErrorCodes.userCancelled),
        );
      }
      return ErrorMapper.toFailure(
        AuthProvider.apple,
        KAuthError.fromCode(
          ErrorCodes.appleSignInFailed,
          details: {'appleError': e.message},
          originalError: e,
        ),
      );
    } catch (e) {
      return ErrorMapper.handleException(
        AuthProvider.apple,
        e,
        operation: '로그인',
        errorCode: ErrorCodes.appleSignInFailed,
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
    return ErrorMapper.toFailure(
      AuthProvider.apple,
      KAuthError(
        code: ErrorCodes.providerNotSupported,
        message: 'Apple은 클라이언트에서 연결 해제를 지원하지 않습니다.',
        hint: '서버에서 Apple REST API를 통해 처리하세요.',
        docs:
            'https://developer.apple.com/documentation/sign_in_with_apple/revoke_tokens',
      ),
    );
  }

  /// 애플 토큰 갱신 (지원하지 않음)
  @override
  Future<AuthResult> refreshToken() async {
    return ErrorMapper.toFailure(
      AuthProvider.apple,
      KAuthError(
        code: ErrorCodes.providerNotSupported,
        message: 'Apple은 토큰 갱신을 지원하지 않습니다.',
        hint: '다시 로그인해주세요.',
      ),
    );
  }
}
