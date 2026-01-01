import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart' as kakao;
import 'package:google_sign_in/google_sign_in.dart';

import '../models/auth_result.dart';
import '../utils/logger.dart';
import 'k_auth_error.dart';

/// 각 Provider의 네이티브 에러를 KAuthError로 변환하는 매퍼
///
/// ## 사용법
///
/// ```dart
/// try {
///   await kakaoProvider.signIn();
/// } on KakaoAuthException catch (e) {
///   final error = ErrorMapper.kakaoAuth(e);
///   return ErrorMapper.toFailure(AuthProvider.kakao, error);
/// }
/// ```
///
/// ## 에러 매핑 전략
///
/// - **Kakao**: enum 기반 매핑 (가장 안정적)
/// - **Google**: 에러 코드 우선 + 문자열 fallback
/// - **Naver**: 패턴 상수 기반 문자열 매칭
///
/// ## 주의사항
///
/// Google과 Naver는 SDK에서 상세한 에러 코드를 제공하지 않아
/// 문자열 패턴 매칭을 사용합니다. SDK 업데이트 시 테스트를 확인하세요.
class ErrorMapper {
  ErrorMapper._();

  // ============================================
  // 공통 에러 처리
  // ============================================

  /// KAuthError를 AuthResult.failure로 변환
  static AuthResult toFailure(AuthProvider provider, KAuthError error) {
    return AuthResult.failure(
      provider: provider,
      errorMessage: error.message,
      errorCode: error.code,
      errorHint: error.hint,
    );
  }

  /// 알 수 없는 에러를 AuthResult.failure로 변환
  ///
  /// [operation]: 작업 이름 (로그인, 로그아웃, 토큰 갱신 등)
  /// [errorCode]: 에러 코드 (기본값: ErrorCodes.loginFailed)
  static AuthResult handleException(
    AuthProvider provider,
    Object error, {
    required String operation,
    String errorCode = ErrorCodes.loginFailed,
  }) {
    // 디버그 정보는 로거로만 출력 (보안)
    KAuthLogger.error('${provider.displayName} $operation 실패', error: error);

    final kError = KAuthError.fromCode(errorCode, originalError: error);
    return AuthResult.failure(
      provider: provider,
      errorMessage: '${provider.displayName} $operation 실패',
      errorCode: kError.code,
      errorHint: kError.hint,
    );
  }

  // ============================================
  // Kakao
  // ============================================

  /// 카카오 인증 에러 → KAuthError
  static KAuthError kakaoAuth(kakao.KakaoAuthException e) {
    switch (e.error) {
      case kakao.AuthErrorCause.accessDenied:
        return KAuthError.fromCode(ErrorCodes.userCancelled, originalError: e);

      case kakao.AuthErrorCause.invalidClient:
        return KAuthError(
          code: ErrorCodes.kakaoAppKeyInvalid,
          message: '카카오 앱 키가 유효하지 않습니다.',
          hint: 'Native App Key를 사용하세요. (REST API Key 아님)',
          docs: 'https://developers.kakao.com/console',
          originalError: e,
        );

      case kakao.AuthErrorCause.invalidGrant:
        return KAuthError(
          code: ErrorCodes.tokenExpired,
          message: '인증 정보가 만료되었습니다.',
          hint: '다시 로그인해주세요.',
          originalError: e,
        );

      case kakao.AuthErrorCause.invalidRequest:
        return KAuthError(
          code: ErrorCodes.kakaoInvalidRedirectUri,
          message: '잘못된 요청입니다.',
          hint: '플랫폼 설정(번들 ID, 패키지명)을 확인하세요.',
          docs: 'https://developers.kakao.com/console',
          originalError: e,
        );

      case kakao.AuthErrorCause.invalidScope:
        return KAuthError(
          code: ErrorCodes.kakaoConsentRequired,
          message: '요청한 권한이 유효하지 않습니다.',
          hint: '동의항목에서 해당 권한을 활성화하세요.',
          docs: 'https://developers.kakao.com/console',
          originalError: e,
        );

      case kakao.AuthErrorCause.serverError:
        return KAuthError(
          code: ErrorCodes.networkError,
          message: '카카오 서버 오류가 발생했습니다.',
          hint: '잠시 후 다시 시도해주세요.',
          originalError: e,
        );

      case kakao.AuthErrorCause.unauthorized:
        return KAuthError(
          code: ErrorCodes.kakaoAppKeyInvalid,
          message: '카카오 로그인 권한이 없습니다.',
          hint: '개발자센터에서 카카오 로그인을 활성화하세요.',
          docs: 'https://developers.kakao.com/console',
          originalError: e,
        );

      default:
        return KAuthError(
          code: ErrorCodes.loginFailed,
          message: '카카오 로그인 중 오류가 발생했습니다.',
          hint: e.message ?? '다시 시도해주세요.',
          originalError: e,
        );
    }
  }

  /// 카카오 API 에러 → KAuthError
  static KAuthError kakaoApi(kakao.KakaoApiException e) {
    switch (e.code) {
      case kakao.ApiErrorCause.invalidToken:
        return KAuthError(
          code: ErrorCodes.tokenExpired,
          message: '액세스 토큰이 만료되었습니다.',
          hint: '토큰 갱신 또는 다시 로그인해주세요.',
          originalError: e,
        );

      case kakao.ApiErrorCause.insufficientScope:
        return KAuthError(
          code: ErrorCodes.kakaoConsentRequired,
          message: '추가 동의가 필요합니다.',
          hint: '동의항목을 확인하고 추가 동의를 요청하세요.',
          docs: 'https://developers.kakao.com/console',
          originalError: e,
        );

      case kakao.ApiErrorCause.notRegisteredUser:
        return KAuthError(
          code: ErrorCodes.loginFailed,
          message: '앱에 연결되지 않은 사용자입니다.',
          hint: '카카오 로그인으로 앱에 연결해주세요.',
          originalError: e,
        );

      case kakao.ApiErrorCause.accountDoesNotExist:
        return KAuthError(
          code: ErrorCodes.loginFailed,
          message: '카카오 계정이 존재하지 않습니다.',
          hint: '카카오 계정을 확인해주세요.',
          originalError: e,
        );

      case kakao.ApiErrorCause.propertyKeyDoesNotExist:
        return KAuthError(
          code: ErrorCodes.userInfoError,
          message: '요청한 사용자 정보가 없습니다.',
          hint: '사용자 프로퍼티 설정을 확인하세요.',
          docs: 'https://developers.kakao.com/console',
          originalError: e,
        );

      default:
        return KAuthError(
          code: ErrorCodes.loginFailed,
          message: '카카오 API 오류가 발생했습니다.',
          hint: e.message ?? '다시 시도해주세요.',
          details: {'apiErrorCode': e.code.name},
          originalError: e,
        );
    }
  }

  // ============================================
  // Google
  // ============================================

  /// 구글 로그인 에러 → KAuthError
  ///
  /// ## 매핑 전략
  ///
  /// 1. 에러 코드 기반 매핑 (안정적)
  /// 2. description 문자열 패턴 매칭 (fallback)
  /// 3. 기본 에러 반환
  ///
  /// ## 지원하는 에러 코드
  ///
  /// - `canceled`, `interrupted`: 사용자가 로그인을 취소/중단함
  /// - `clientConfigurationError`, `providerConfigurationError`: OAuth 설정 오류
  /// - `unknownError`: 알 수 없는 에러 (문자열 패턴으로 세분화)
  static KAuthError google(GoogleSignInException e) {
    final code = e.code;

    // 1. 사용자 취소/중단
    if (code == GoogleSignInExceptionCode.canceled ||
        code == GoogleSignInExceptionCode.interrupted) {
      return KAuthError.fromCode(ErrorCodes.userCancelled, originalError: e);
    }

    // 2. OAuth 설정 오류 (코드 기반)
    if (code == GoogleSignInExceptionCode.clientConfigurationError ||
        code == GoogleSignInExceptionCode.providerConfigurationError) {
      return KAuthError(
        code: ErrorCodes.googleMissingIosClientId,
        message: 'Google OAuth 설정 오류입니다.',
        hint: 'iosClientId 설정과 Cloud Console을 확인하세요.',
        docs: 'https://console.cloud.google.com/apis/credentials',
        originalError: e,
      );
    }

    // 3. description 문자열 패턴 매칭 (unknownError용 fallback)
    final desc = e.description?.toLowerCase() ?? '';

    // 네트워크 에러 패턴
    if (_GoogleErrorPatterns.matchesNetwork(desc)) {
      return KAuthError(
        code: ErrorCodes.networkError,
        message: '네트워크 오류가 발생했습니다.',
        hint: '인터넷 연결을 확인해주세요.',
        originalError: e,
      );
    }

    // OAuth 설정 에러 패턴
    if (_GoogleErrorPatterns.matchesOAuth(desc)) {
      return KAuthError(
        code: ErrorCodes.googleMissingIosClientId,
        message: 'Google OAuth 설정 오류입니다.',
        hint: 'iosClientId 설정과 Cloud Console을 확인하세요.',
        docs: 'https://console.cloud.google.com/apis/credentials',
        originalError: e,
      );
    }

    // 4. 기본 에러
    return KAuthError(
      code: ErrorCodes.googleSignInFailed,
      message: '구글 로그인 중 오류가 발생했습니다.',
      hint: e.description ?? 'Cloud Console 설정을 확인하세요.',
      docs: 'https://console.cloud.google.com/apis/credentials',
      originalError: e,
    );
  }

  // ============================================
  // Naver
  // ============================================

  /// 네이버 에러 메시지 → KAuthError
  ///
  /// ## 매핑 전략
  ///
  /// 네이버 SDK는 상세한 에러 코드를 제공하지 않아 문자열 패턴 매칭을 사용합니다.
  /// 패턴은 [_NaverErrorPatterns]에 상수로 정의되어 있어 테스트와 유지보수가 용이합니다.
  ///
  /// ## 매핑 우선순위
  ///
  /// 1. 사용자 취소 (cancel, 취소, denied, 거부)
  /// 2. 네트워크 에러 (network, timeout, 연결 등)
  /// 3. URL/콜백 에러 (url, scheme, callback, redirect)
  /// 4. 클라이언트 에러 (client, invalid, unauthorized 등)
  /// 5. 토큰 만료 (token, expired, 만료, 세션)
  /// 6. 기본 에러
  ///
  /// URL/콜백 에러가 클라이언트 에러보다 우선순위가 높습니다.
  /// (예: "invalid redirect url"은 콜백 에러로 분류)
  static KAuthError naver(String errorMessage, {Object? originalError}) {
    final msg = errorMessage.toLowerCase();

    // 1. 사용자 취소
    if (_NaverErrorPatterns.matchesCancel(msg)) {
      return KAuthError.fromCode(ErrorCodes.userCancelled,
          originalError: originalError);
    }

    // 2. 네트워크/타임아웃 에러
    if (_NaverErrorPatterns.matchesNetwork(msg)) {
      return KAuthError(
        code: ErrorCodes.networkError,
        message: '네트워크 오류가 발생했습니다.',
        hint: '인터넷 연결을 확인해주세요.',
        originalError: originalError,
      );
    }

    // 3. URL 스킴/콜백 오류 (클라이언트 오류보다 먼저 체크)
    if (_NaverErrorPatterns.matchesCallback(msg)) {
      return KAuthError(
        code: ErrorCodes.naverInvalidCallback,
        message: '콜백 URL 설정 오류입니다.',
        hint: 'URL 스킴, 콜백 URL, Info.plist를 확인하세요.',
        docs: 'https://developers.naver.com/apps',
        originalError: originalError,
      );
    }

    // 4. 클라이언트/OAuth 정보 오류
    if (_NaverErrorPatterns.matchesClient(msg)) {
      return KAuthError(
        code: ErrorCodes.naverClientInfoInvalid,
        message: '네이버 클라이언트 정보가 유효하지 않습니다.',
        hint: 'Client ID/Secret을 확인하세요.',
        docs: 'https://developers.naver.com/apps',
        originalError: originalError,
      );
    }

    // 5. 토큰 만료
    if (_NaverErrorPatterns.matchesTokenExpired(msg)) {
      return KAuthError(
        code: ErrorCodes.tokenExpired,
        message: '인증 정보가 만료되었습니다.',
        hint: '다시 로그인해주세요.',
        originalError: originalError,
      );
    }

    // 6. 기본 에러
    return KAuthError(
      code: ErrorCodes.loginFailed,
      message: '네이버 로그인 중 오류가 발생했습니다.',
      hint: errorMessage.isNotEmpty ? errorMessage : '다시 시도해주세요.',
      docs: 'https://developers.naver.com/apps',
      originalError: originalError,
    );
  }
}

// ============================================
// 에러 패턴 상수 (내부용)
// ============================================

/// Google 에러 메시지 패턴
///
/// SDK 업데이트 시 이 패턴들을 확인하세요.
/// 테스트: test/error_mapper_test.dart
class _GoogleErrorPatterns {
  _GoogleErrorPatterns._();

  /// 네트워크 에러 패턴
  static const network = ['network', 'internet', 'connection'];

  /// OAuth 설정 에러 패턴
  static const oauth = ['client', 'oauth'];

  static bool matchesNetwork(String msg) => _matchesAny(msg, network);
  static bool matchesOAuth(String msg) => _matchesAny(msg, oauth);

  static bool _matchesAny(String msg, List<String> patterns) {
    return patterns.any((p) => msg.contains(p));
  }
}

/// Naver 에러 메시지 패턴
///
/// 한글과 영문 키워드를 모두 지원합니다.
/// SDK 업데이트 시 이 패턴들을 확인하세요.
/// 테스트: test/error_mapper_test.dart
class _NaverErrorPatterns {
  _NaverErrorPatterns._();

  /// 사용자 취소 패턴
  static const cancel = ['cancel', '취소', 'denied', '거부'];

  /// 네트워크 에러 패턴
  static const network = [
    'network',
    'internet',
    'connection',
    'timeout',
    '네트워크',
    '연결',
    '시간 초과',
  ];

  /// URL/콜백 에러 패턴
  static const callback = ['url', 'scheme', 'callback', 'redirect'];

  /// 클라이언트 에러 패턴
  static const client = [
    'client',
    'invalid',
    'unauthorized',
    'oauth',
    'permission',
    '권한',
  ];

  /// 토큰 만료 패턴
  static const tokenExpired = ['token', 'expired', '만료', '세션'];

  static bool matchesCancel(String msg) => _matchesAny(msg, cancel);
  static bool matchesNetwork(String msg) => _matchesAny(msg, network);
  static bool matchesCallback(String msg) => _matchesAny(msg, callback);
  static bool matchesClient(String msg) => _matchesAny(msg, client);
  static bool matchesTokenExpired(String msg) => _matchesAny(msg, tokenExpired);

  static bool _matchesAny(String msg, List<String> patterns) {
    return patterns.any((p) => msg.contains(p));
  }
}
