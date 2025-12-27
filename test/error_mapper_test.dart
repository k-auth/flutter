import 'package:flutter/foundation.dart' show TargetPlatform;
import 'package:flutter_test/flutter_test.dart';
import 'package:k_auth/k_auth.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart' as kakao;
import 'package:google_sign_in/google_sign_in.dart';

void main() {
  // ============================================
  // ErrorMapper.kakaoAuth 테스트
  // ============================================
  group('ErrorMapper.kakaoAuth', () {
    test('accessDenied → USER_CANCELLED', () {
      final exception = kakao.KakaoAuthException(
        kakao.AuthErrorCause.accessDenied,
        '사용자가 취소함',
      );

      final error = ErrorMapper.kakaoAuth(exception);

      expect(error.code, ErrorCodes.userCancelled);
    });

    test('invalidClient → KAKAO_APP_KEY_INVALID', () {
      final exception = kakao.KakaoAuthException(
        kakao.AuthErrorCause.invalidClient,
        '클라이언트 오류',
      );

      final error = ErrorMapper.kakaoAuth(exception);

      expect(error.code, ErrorCodes.kakaoAppKeyInvalid);
      expect(error.message, contains('앱 키'));
      expect(error.hint, contains('Native App Key'));
    });

    test('invalidGrant → TOKEN_EXPIRED', () {
      final exception = kakao.KakaoAuthException(
        kakao.AuthErrorCause.invalidGrant,
        '토큰 만료',
      );

      final error = ErrorMapper.kakaoAuth(exception);

      expect(error.code, ErrorCodes.tokenExpired);
      expect(error.hint, contains('다시 로그인'));
    });

    test('invalidRequest → KAKAO_INVALID_REDIRECT_URI', () {
      final exception = kakao.KakaoAuthException(
        kakao.AuthErrorCause.invalidRequest,
        '잘못된 요청',
      );

      final error = ErrorMapper.kakaoAuth(exception);

      expect(error.code, ErrorCodes.kakaoInvalidRedirectUri);
      expect(error.hint, contains('플랫폼 설정'));
    });

    test('invalidScope → KAKAO_CONSENT_REQUIRED', () {
      final exception = kakao.KakaoAuthException(
        kakao.AuthErrorCause.invalidScope,
        '스코프 오류',
      );

      final error = ErrorMapper.kakaoAuth(exception);

      expect(error.code, ErrorCodes.kakaoConsentRequired);
      expect(error.hint, contains('동의항목'));
    });

    test('serverError → NETWORK_ERROR', () {
      final exception = kakao.KakaoAuthException(
        kakao.AuthErrorCause.serverError,
        '서버 오류',
      );

      final error = ErrorMapper.kakaoAuth(exception);

      expect(error.code, ErrorCodes.networkError);
      expect(error.hint, contains('다시 시도'));
    });

    test('unauthorized → KAKAO_APP_KEY_INVALID', () {
      final exception = kakao.KakaoAuthException(
        kakao.AuthErrorCause.unauthorized,
        '권한 없음',
      );

      final error = ErrorMapper.kakaoAuth(exception);

      expect(error.code, ErrorCodes.kakaoAppKeyInvalid);
      expect(error.hint, contains('활성화'));
    });

    test('unknown → LOGIN_FAILED', () {
      final exception = kakao.KakaoAuthException(
        kakao.AuthErrorCause.unknown,
        '알 수 없는 오류',
      );

      final error = ErrorMapper.kakaoAuth(exception);

      expect(error.code, ErrorCodes.loginFailed);
    });
  });

  // ============================================
  // ErrorMapper.kakaoApi 테스트
  // ============================================
  group('ErrorMapper.kakaoApi', () {
    test('invalidToken → TOKEN_EXPIRED', () {
      final exception = kakao.KakaoApiException(
        kakao.ApiErrorCause.invalidToken,
        '토큰 무효',
      );

      final error = ErrorMapper.kakaoApi(exception);

      expect(error.code, ErrorCodes.tokenExpired);
      expect(error.hint, contains('갱신'));
    });

    test('insufficientScope → KAKAO_CONSENT_REQUIRED', () {
      final exception = kakao.KakaoApiException(
        kakao.ApiErrorCause.insufficientScope,
        '스코프 부족',
      );

      final error = ErrorMapper.kakaoApi(exception);

      expect(error.code, ErrorCodes.kakaoConsentRequired);
      expect(error.hint, contains('동의'));
    });

    test('notRegisteredUser → LOGIN_FAILED', () {
      final exception = kakao.KakaoApiException(
        kakao.ApiErrorCause.notRegisteredUser,
        '등록 안 된 사용자',
      );

      final error = ErrorMapper.kakaoApi(exception);

      expect(error.code, ErrorCodes.loginFailed);
      expect(error.message, contains('연결되지 않은'));
    });

    test('accountDoesNotExist → LOGIN_FAILED', () {
      final exception = kakao.KakaoApiException(
        kakao.ApiErrorCause.accountDoesNotExist,
        '계정 없음',
      );

      final error = ErrorMapper.kakaoApi(exception);

      expect(error.code, ErrorCodes.loginFailed);
      expect(error.message, contains('존재하지 않습니다'));
    });

    test('propertyKeyDoesNotExist → USER_INFO_ERROR', () {
      final exception = kakao.KakaoApiException(
        kakao.ApiErrorCause.propertyKeyDoesNotExist,
        '프로퍼티 없음',
      );

      final error = ErrorMapper.kakaoApi(exception);

      expect(error.code, ErrorCodes.userInfoError);
      expect(error.hint, contains('프로퍼티'));
    });

    test('unknown → LOGIN_FAILED with details', () {
      final exception = kakao.KakaoApiException(
        kakao.ApiErrorCause.unknown,
        '알 수 없는 오류',
      );

      final error = ErrorMapper.kakaoApi(exception);

      expect(error.code, ErrorCodes.loginFailed);
      expect(error.details?['apiErrorCode'], 'unknown');
    });
  });

  // ============================================
  // ErrorMapper.google 테스트
  // ============================================
  group('ErrorMapper.google', () {
    test('canceled → USER_CANCELLED', () {
      final exception = GoogleSignInException(
        code: GoogleSignInExceptionCode.canceled,
        description: '취소됨',
      );

      final error = ErrorMapper.google(exception);

      expect(error.code, ErrorCodes.userCancelled);
    });

    test('network 키워드 → NETWORK_ERROR', () {
      final exception = GoogleSignInException(
        code: GoogleSignInExceptionCode.unknownError,
        description: 'Network connection failed',
      );

      final error = ErrorMapper.google(exception);

      expect(error.code, ErrorCodes.networkError);
      expect(error.hint, contains('인터넷'));
    });

    test('internet 키워드 → NETWORK_ERROR', () {
      final exception = GoogleSignInException(
        code: GoogleSignInExceptionCode.unknownError,
        description: 'No internet connection',
      );

      final error = ErrorMapper.google(exception);

      expect(error.code, ErrorCodes.networkError);
    });

    test('client 키워드 → GOOGLE_MISSING_IOS_CLIENT_ID', () {
      final exception = GoogleSignInException(
        code: GoogleSignInExceptionCode.unknownError,
        description: 'Invalid client configuration',
      );

      final error = ErrorMapper.google(exception);

      expect(error.code, ErrorCodes.googleMissingIosClientId);
      expect(error.hint, contains('iosClientId'));
    });

    test('oauth 키워드 → GOOGLE_MISSING_IOS_CLIENT_ID', () {
      final exception = GoogleSignInException(
        code: GoogleSignInExceptionCode.unknownError,
        description: 'OAuth error occurred',
      );

      final error = ErrorMapper.google(exception);

      expect(error.code, ErrorCodes.googleMissingIosClientId);
    });

    test('unknown → GOOGLE_SIGN_IN_FAILED', () {
      final exception = GoogleSignInException(
        code: GoogleSignInExceptionCode.unknownError,
        description: '알 수 없는 오류',
      );

      final error = ErrorMapper.google(exception);

      expect(error.code, ErrorCodes.googleSignInFailed);
      expect(error.docs, contains('console.cloud.google.com'));
    });

    test('null description → GOOGLE_SIGN_IN_FAILED', () {
      final exception = GoogleSignInException(
        code: GoogleSignInExceptionCode.unknownError,
      );

      final error = ErrorMapper.google(exception);

      expect(error.code, ErrorCodes.googleSignInFailed);
    });
  });

  // ============================================
  // ErrorMapper.naver 테스트
  // ============================================
  group('ErrorMapper.naver', () {
    test('cancel 키워드 → USER_CANCELLED', () {
      final error = ErrorMapper.naver('User cancelled the login');

      expect(error.code, ErrorCodes.userCancelled);
    });

    test('취소 키워드 → USER_CANCELLED', () {
      final error = ErrorMapper.naver('사용자가 로그인을 취소했습니다');

      expect(error.code, ErrorCodes.userCancelled);
    });

    test('network 키워드 → NETWORK_ERROR', () {
      final error = ErrorMapper.naver('Network error occurred');

      expect(error.code, ErrorCodes.networkError);
      expect(error.hint, contains('인터넷'));
    });

    test('네트워크 키워드 → NETWORK_ERROR', () {
      final error = ErrorMapper.naver('네트워크 연결 실패');

      expect(error.code, ErrorCodes.networkError);
    });

    test('internet 키워드 → NETWORK_ERROR', () {
      final error = ErrorMapper.naver('No internet connection');

      expect(error.code, ErrorCodes.networkError);
    });

    test('connection 키워드 → NETWORK_ERROR', () {
      final error = ErrorMapper.naver('Connection timeout');

      expect(error.code, ErrorCodes.networkError);
    });

    test('client 키워드 → NAVER_CLIENT_INFO_INVALID', () {
      final error = ErrorMapper.naver('Invalid client credentials');

      expect(error.code, ErrorCodes.naverClientInfoInvalid);
      expect(error.hint, contains('Client ID'));
    });

    test('invalid 키워드 → NAVER_CLIENT_INFO_INVALID', () {
      final error = ErrorMapper.naver('Invalid request');

      expect(error.code, ErrorCodes.naverClientInfoInvalid);
    });

    test('unauthorized 키워드 → NAVER_CLIENT_INFO_INVALID', () {
      final error = ErrorMapper.naver('Unauthorized access');

      expect(error.code, ErrorCodes.naverClientInfoInvalid);
    });

    test('url 키워드 → NAVER_INVALID_CALLBACK', () {
      final error = ErrorMapper.naver('URL scheme error');

      expect(error.code, ErrorCodes.naverInvalidCallback);
      expect(error.hint, contains('URL 스킴'));
    });

    test('scheme 키워드 → NAVER_INVALID_CALLBACK', () {
      final error = ErrorMapper.naver('URL scheme not registered');

      expect(error.code, ErrorCodes.naverInvalidCallback);
    });

    test('callback 키워드 → NAVER_INVALID_CALLBACK', () {
      final error = ErrorMapper.naver('Callback URL mismatch');

      expect(error.code, ErrorCodes.naverInvalidCallback);
    });

    test('token 키워드 → TOKEN_EXPIRED', () {
      final error = ErrorMapper.naver('Token expired');

      expect(error.code, ErrorCodes.tokenExpired);
      expect(error.hint, contains('다시 로그인'));
    });

    test('expired 키워드 → TOKEN_EXPIRED', () {
      final error = ErrorMapper.naver('Session expired');

      expect(error.code, ErrorCodes.tokenExpired);
    });

    test('unknown → LOGIN_FAILED with hint', () {
      final error = ErrorMapper.naver('Something went wrong');

      expect(error.code, ErrorCodes.loginFailed);
      expect(error.hint, 'Something went wrong');
      expect(error.docs, contains('developers.naver.com'));
    });

    test('empty → LOGIN_FAILED with default hint', () {
      final error = ErrorMapper.naver('');

      expect(error.code, ErrorCodes.loginFailed);
      expect(error.hint, contains('다시 시도'));
    });
  });

  // ============================================
  // GoogleConfig.validate 테스트 (iOS 검증)
  // ============================================
  group('GoogleConfig.validate', () {
    test('iOS에서 iosClientId 없으면 에러', () {
      final config = GoogleConfig();
      final errors = config.validate(targetPlatform: TargetPlatform.iOS);

      expect(errors, isNotEmpty);
      expect(errors.first.code, ErrorCodes.googleMissingIosClientId);
    });

    test('macOS에서 iosClientId 없으면 에러', () {
      final config = GoogleConfig();
      final errors = config.validate(targetPlatform: TargetPlatform.macOS);

      expect(errors, isNotEmpty);
      expect(errors.first.code, ErrorCodes.googleMissingIosClientId);
    });

    test('iOS에서 iosClientId 있으면 통과', () {
      final config = GoogleConfig(iosClientId: 'valid-client-id');
      final errors = config.validate(targetPlatform: TargetPlatform.iOS);

      expect(errors, isEmpty);
    });

    test('Android에서 iosClientId 없어도 통과', () {
      final config = GoogleConfig();
      final errors = config.validate(targetPlatform: TargetPlatform.android);

      expect(errors, isEmpty);
    });

    test('빈 iosClientId는 에러', () {
      final config = GoogleConfig(iosClientId: '');
      final errors = config.validate(targetPlatform: TargetPlatform.iOS);

      expect(errors, isNotEmpty);
    });
  });
}
