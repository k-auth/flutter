import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart' as kakao;
import 'package:google_sign_in/google_sign_in.dart';

import 'k_auth_error.dart';

/// 각 Provider의 네이티브 에러를 KAuthError로 변환하는 매퍼
class ErrorMapper {
  ErrorMapper._();

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
  static KAuthError google(GoogleSignInException e) {
    if (e.code == GoogleSignInExceptionCode.canceled) {
      return KAuthError.fromCode(ErrorCodes.userCancelled, originalError: e);
    }

    final desc = e.description?.toLowerCase() ?? '';

    // 네트워크 에러
    if (desc.contains('network') ||
        desc.contains('internet') ||
        desc.contains('connection')) {
      return KAuthError(
        code: ErrorCodes.networkError,
        message: '네트워크 오류가 발생했습니다.',
        hint: '인터넷 연결을 확인해주세요.',
        originalError: e,
      );
    }

    // OAuth 설정 에러
    if (desc.contains('client') || desc.contains('oauth')) {
      return KAuthError(
        code: ErrorCodes.googleMissingIosClientId,
        message: 'Google OAuth 설정 오류입니다.',
        hint: 'iosClientId 설정과 Cloud Console을 확인하세요.',
        docs: 'https://console.cloud.google.com/apis/credentials',
        originalError: e,
      );
    }

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
  static KAuthError naver(String errorMessage, {Object? originalError}) {
    final msg = errorMessage.toLowerCase();

    // 사용자 취소
    if (msg.contains('cancel') ||
        msg.contains('취소') ||
        msg.contains('denied') ||
        msg.contains('거부')) {
      return KAuthError.fromCode(ErrorCodes.userCancelled,
          originalError: originalError);
    }

    // 네트워크/타임아웃 에러
    if (msg.contains('network') ||
        msg.contains('internet') ||
        msg.contains('connection') ||
        msg.contains('timeout') ||
        msg.contains('네트워크') ||
        msg.contains('연결') ||
        msg.contains('시간 초과')) {
      return KAuthError(
        code: ErrorCodes.networkError,
        message: '네트워크 오류가 발생했습니다.',
        hint: '인터넷 연결을 확인해주세요.',
        originalError: originalError,
      );
    }

    // URL 스킴/콜백 오류 (클라이언트 오류보다 먼저 체크)
    if (msg.contains('url') ||
        msg.contains('scheme') ||
        msg.contains('callback') ||
        msg.contains('redirect')) {
      return KAuthError(
        code: ErrorCodes.naverInvalidCallback,
        message: '콜백 URL 설정 오류입니다.',
        hint: 'URL 스킴, 콜백 URL, Info.plist를 확인하세요.',
        docs: 'https://developers.naver.com/apps',
        originalError: originalError,
      );
    }

    // 클라이언트/OAuth 정보 오류
    if (msg.contains('client') ||
        msg.contains('invalid') ||
        msg.contains('unauthorized') ||
        msg.contains('oauth') ||
        msg.contains('permission') ||
        msg.contains('권한')) {
      return KAuthError(
        code: ErrorCodes.naverClientInfoInvalid,
        message: '네이버 클라이언트 정보가 유효하지 않습니다.',
        hint: 'Client ID/Secret을 확인하세요.',
        docs: 'https://developers.naver.com/apps',
        originalError: originalError,
      );
    }

    // 토큰 만료
    if (msg.contains('token') ||
        msg.contains('expired') ||
        msg.contains('만료') ||
        msg.contains('세션')) {
      return KAuthError(
        code: ErrorCodes.tokenExpired,
        message: '인증 정보가 만료되었습니다.',
        hint: '다시 로그인해주세요.',
        originalError: originalError,
      );
    }

    return KAuthError(
      code: ErrorCodes.loginFailed,
      message: '네이버 로그인 중 오류가 발생했습니다.',
      hint: errorMessage.isNotEmpty ? errorMessage : '다시 시도해주세요.',
      docs: 'https://developers.naver.com/apps',
      originalError: originalError,
    );
  }
}
