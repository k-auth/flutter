import 'dart:developer' as developer;

/// KAuth 에러 클래스
class KAuthError implements Exception {
  /// 에러 코드
  final String code;

  /// 에러 메시지 (한글)
  final String message;

  /// 해결 힌트
  final String? hint;

  /// 관련 문서 링크
  final String? docs;

  /// 추가 상세 정보
  final Map<String, dynamic>? details;

  /// 원본 에러
  final Object? originalError;

  const KAuthError({
    required this.code,
    required this.message,
    this.hint,
    this.docs,
    this.details,
    this.originalError,
  });

  /// 에러 코드로부터 KAuthError 생성
  factory KAuthError.fromCode(
    String code, {
    Map<String, dynamic>? details,
    Object? originalError,
  }) {
    final errorInfo = ErrorCodes.getErrorInfo(code);
    return KAuthError(
      code: code,
      message: errorInfo.message,
      hint: errorInfo.hint,
      docs: errorInfo.docs,
      details: details,
      originalError: originalError,
    );
  }

  /// 콘솔에 포맷된 에러 로그 출력
  void log() {
    final buffer = StringBuffer();
    buffer.writeln('');
    buffer.writeln('=' * 50);
    buffer.writeln('[K-Auth 오류] $code');
    buffer.writeln('=' * 50);
    buffer.writeln('');
    buffer.writeln('메시지: $message');

    if (hint != null) {
      buffer.writeln('');
      buffer.writeln('힌트: $hint');
    }

    if (docs != null) {
      buffer.writeln('');
      buffer.writeln('문서: $docs');
    }

    if (details != null && details!.isNotEmpty) {
      buffer.writeln('');
      buffer.writeln('상세 정보:');
      details!.forEach((key, value) {
        buffer.writeln('  - $key: $value');
      });
    }

    if (originalError != null) {
      buffer.writeln('');
      buffer.writeln('원본 에러: $originalError');
    }

    buffer.writeln('');
    buffer.writeln('=' * 50);

    developer.log(buffer.toString(), name: 'K-Auth');
  }

  @override
  String toString() => 'KAuthError[$code]: $message';

  /// 사용자에게 표시할 메시지
  String toUserMessage() => message;

  /// JSON 형식으로 변환
  Map<String, dynamic> toJson() => {
        'code': code,
        'message': message,
        if (hint != null) 'hint': hint,
        if (docs != null) 'docs': docs,
        if (details != null) 'details': details,
      };
}

/// 에러 정보 클래스
class ErrorInfo {
  final String message;
  final String? hint;
  final String? docs;

  const ErrorInfo({
    required this.message,
    this.hint,
    this.docs,
  });
}

/// 에러 코드 정의
class ErrorCodes {
  ErrorCodes._();

  // ============================================
  // 설정 에러
  // ============================================
  static const String configNotFound = 'CONFIG_NOT_FOUND';
  static const String invalidConfig = 'INVALID_CONFIG';
  static const String noProviderConfigured = 'NO_PROVIDER_CONFIGURED';
  static const String missingClientId = 'MISSING_CLIENT_ID';
  static const String missingClientSecret = 'MISSING_CLIENT_SECRET';
  static const String missingAppKey = 'MISSING_APP_KEY';

  // ============================================
  // 인증 에러
  // ============================================
  static const String userCancelled = 'USER_CANCELLED';
  static const String loginFailed = 'LOGIN_FAILED';
  static const String signOutFailed = 'SIGN_OUT_FAILED';
  static const String unlinkFailed = 'UNLINK_FAILED';
  static const String tokenExpired = 'TOKEN_EXPIRED';
  static const String refreshFailed = 'REFRESH_FAILED';
  static const String networkError = 'NETWORK_ERROR';
  static const String accessTokenError = 'ACCESS_TOKEN_ERROR';
  static const String userInfoError = 'USER_INFO_ERROR';
  static const String oauthCallbackError = 'OAUTH_CALLBACK_ERROR';

  // ============================================
  // Provider 에러
  // ============================================
  static const String providerNotConfigured = 'PROVIDER_NOT_CONFIGURED';
  static const String providerNotSupported = 'PROVIDER_NOT_SUPPORTED';
  static const String providerNotInitialized = 'PROVIDER_NOT_INITIALIZED';

  // ============================================
  // 카카오 에러
  // ============================================
  static const String kakaoInvalidRedirectUri = 'KAKAO_INVALID_REDIRECT_URI';
  static const String kakaoPhoneNotEnabled = 'KAKAO_PHONE_NOT_ENABLED';
  static const String kakaoConsentRequired = 'KAKAO_CONSENT_REQUIRED';
  static const String kakaoAppKeyInvalid = 'KAKAO_APP_KEY_INVALID';

  // ============================================
  // 네이버 에러
  // ============================================
  static const String naverInvalidCallback = 'NAVER_INVALID_CALLBACK';
  static const String naverServiceUrlMismatch = 'NAVER_SERVICE_URL_MISMATCH';
  static const String naverClientInfoInvalid = 'NAVER_CLIENT_INFO_INVALID';

  // ============================================
  // 구글 에러
  // ============================================
  static const String googleSignInFailed = 'GOOGLE_SIGN_IN_FAILED';
  static const String googleMissingIosClientId = 'GOOGLE_MISSING_IOS_CLIENT_ID';

  // ============================================
  // 애플 에러
  // ============================================
  static const String appleSignInFailed = 'APPLE_SIGN_IN_FAILED';
  static const String appleNotSupported = 'APPLE_NOT_SUPPORTED';
  static const String appleCredentialError = 'APPLE_CREDENTIAL_ERROR';

  // ============================================
  // 플랫폼 에러
  // ============================================
  static const String platformNotSupported = 'PLATFORM_NOT_SUPPORTED';

  // ============================================
  // 알 수 없는 에러
  // ============================================
  static const String unknownError = 'UNKNOWN_ERROR';

  /// 에러 코드에 대한 상세 정보 반환
  static ErrorInfo getErrorInfo(String code) {
    return _errorInfoMap[code] ??
        ErrorInfo(
          message: '알 수 없는 에러가 발생했습니다.',
          hint: '문제가 지속되면 이슈를 등록해주세요.',
          docs: 'https://github.com/k-auth/k-auth/issues',
        );
  }

  /// GitHub README 트러블슈팅 기본 URL
  static const String _docsBase = 'https://github.com/k-auth/flutter#';

  static const Map<String, ErrorInfo> _errorInfoMap = {
    // 설정 에러
    configNotFound: ErrorInfo(
      message: '설정을 찾을 수 없습니다.',
      hint: 'KAuth.initialize()를 먼저 호출해주세요.',
      docs: '$_docsBase공통',
    ),
    invalidConfig: ErrorInfo(
      message: '잘못된 설정입니다.',
      hint: '설정값이 올바른지 확인해주세요.',
      docs: '$_docsBase공통',
    ),
    noProviderConfigured: ErrorInfo(
      message: '설정된 Provider가 없습니다.',
      hint: 'KAuthConfig에 최소 하나의 Provider를 설정해주세요.',
      docs: '$_docsBase빠른-시작',
    ),
    missingClientId: ErrorInfo(
      message: 'Client ID가 설정되지 않았습니다.',
      hint: 'Provider 설정에 clientId를 추가해주세요.',
      docs: '${_docsBase}provider-설정',
    ),
    missingClientSecret: ErrorInfo(
      message: 'Client Secret이 설정되지 않았습니다.',
      hint: 'Provider 설정에 clientSecret을 추가해주세요.',
      docs: '${_docsBase}provider-설정',
    ),
    missingAppKey: ErrorInfo(
      message: 'App Key가 설정되지 않았습니다.',
      hint: 'Provider 설정에 appKey를 추가해주세요.',
      docs: '$_docsBase카카오-kakao',
    ),

    // 인증 에러
    userCancelled: ErrorInfo(
      message: '사용자가 로그인을 취소했습니다.',
      hint: '사용자가 로그인 과정을 취소하였습니다. 다시 시도해주세요.',
    ),
    loginFailed: ErrorInfo(
      message: '로그인에 실패했습니다.',
      hint: '네트워크 연결 상태와 설정을 확인해주세요.',
      docs: '$_docsBase트러블슈팅',
    ),
    signOutFailed: ErrorInfo(
      message: '로그아웃에 실패했습니다.',
      hint: '네트워크 연결 상태를 확인하고 다시 시도해주세요.',
    ),
    unlinkFailed: ErrorInfo(
      message: '연결 해제에 실패했습니다.',
      hint: '네트워크 연결 상태를 확인하고 다시 시도해주세요.',
    ),
    tokenExpired: ErrorInfo(
      message: '토큰이 만료되었습니다.',
      hint: '다시 로그인하거나 토큰을 갱신해주세요.',
    ),
    refreshFailed: ErrorInfo(
      message: '토큰 갱신에 실패했습니다.',
      hint: '다시 로그인해주세요.',
    ),
    networkError: ErrorInfo(
      message: '네트워크 오류가 발생했습니다.',
      hint: '인터넷 연결 상태를 확인하고 다시 시도해주세요.',
    ),
    accessTokenError: ErrorInfo(
      message: '액세스 토큰을 가져오는데 실패했습니다.',
      hint: 'OAuth 설정을 확인해주세요.',
      docs: '$_docsBase트러블슈팅',
    ),
    userInfoError: ErrorInfo(
      message: '사용자 정보를 가져오는데 실패했습니다.',
      hint: '권한 설정과 scope를 확인해주세요.',
    ),
    oauthCallbackError: ErrorInfo(
      message: 'OAuth 콜백 처리 중 오류가 발생했습니다.',
      hint: 'Redirect URI 설정을 확인해주세요.',
      docs: '$_docsBase플랫폼-설정',
    ),

    // Provider 에러
    providerNotConfigured: ErrorInfo(
      message: '해당 Provider가 설정되지 않았습니다.',
      hint: 'KAuthConfig에 해당 Provider 설정을 추가해주세요.',
      docs: '${_docsBase}provider-설정',
    ),
    providerNotSupported: ErrorInfo(
      message: '지원하지 않는 Provider입니다.',
      hint: '지원되는 Provider: kakao, naver, google, apple',
    ),
    providerNotInitialized: ErrorInfo(
      message: 'Provider가 초기화되지 않았습니다.',
      hint: 'KAuth.initialize()를 먼저 호출해주세요.',
      docs: '$_docsBase공통',
    ),

    // 카카오 에러
    kakaoInvalidRedirectUri: ErrorInfo(
      message: 'Redirect URI가 등록되지 않았습니다.',
      hint: '카카오 개발자센터 > 카카오 로그인 > Redirect URI에 앱의 URL을 추가하세요.',
      docs: '$_docsBase카카오',
    ),
    kakaoPhoneNotEnabled: ErrorInfo(
      message: '전화번호 수집 권한이 활성화되지 않았습니다.',
      hint: '카카오 개발자센터 > 카카오 로그인 > 동의항목에서 전화번호 항목을 활성화하세요.',
      docs: '$_docsBase카카오',
    ),
    kakaoConsentRequired: ErrorInfo(
      message: '사용자 동의가 필요합니다.',
      hint: '카카오 개발자센터에서 동의항목 설정을 확인하세요.',
      docs: '$_docsBase카카오',
    ),
    kakaoAppKeyInvalid: ErrorInfo(
      message: '카카오 앱 키가 유효하지 않습니다.',
      hint: 'Native App Key를 사용하고 있는지 확인하세요. (REST API Key 아님)',
      docs: '${_docsBase}koe101-invalid-client',
    ),

    // 네이버 에러
    naverInvalidCallback: ErrorInfo(
      message: '콜백 URL이 유효하지 않습니다.',
      hint: '네이버 개발자센터에서 Callback URL 설정을 확인하세요.',
      docs: '$_docsBase네이버',
    ),
    naverServiceUrlMismatch: ErrorInfo(
      message: '서비스 URL이 일치하지 않습니다.',
      hint: '네이버 개발자센터에서 서비스 URL 설정을 확인하세요.',
      docs: '$_docsBase네이버',
    ),
    naverClientInfoInvalid: ErrorInfo(
      message: '네이버 클라이언트 정보가 유효하지 않습니다.',
      hint: 'Client ID와 Client Secret이 올바른지 확인하세요.',
      docs: '$_docsBase인증-실패-invalid_request',
    ),

    // 구글 에러
    googleSignInFailed: ErrorInfo(
      message: '구글 로그인에 실패했습니다.',
      hint: 'Google Cloud Console에서 OAuth 설정을 확인하세요.',
      docs: '$_docsBase구글',
    ),
    googleMissingIosClientId: ErrorInfo(
      message: 'iOS Client ID가 설정되지 않았습니다.',
      hint: 'iOS에서 구글 로그인을 사용하려면 iosClientId를 설정하세요.',
      docs: '${_docsBase}ios에서-developer_error',
    ),

    // 애플 에러
    appleSignInFailed: ErrorInfo(
      message: '애플 로그인에 실패했습니다.',
      hint: 'Apple Developer 설정을 확인하세요.',
      docs: '$_docsBase애플',
    ),
    appleNotSupported: ErrorInfo(
      message: '이 기기에서 애플 로그인을 지원하지 않습니다.',
      hint: '애플 로그인은 iOS 13+, macOS에서만 지원됩니다.',
      docs: '$_docsBase애플',
    ),
    appleCredentialError: ErrorInfo(
      message: '애플 인증 정보를 가져오는데 실패했습니다.',
      hint: 'Apple ID 설정을 확인해주세요.',
      docs: '$_docsBase이름이메일이-null로-반환됨',
    ),

    // 플랫폼 에러
    platformNotSupported: ErrorInfo(
      message: '현재 플랫폼에서 지원하지 않습니다.',
      hint: '지원 플랫폼: iOS, Android',
    ),

    // 알 수 없는 에러
    unknownError: ErrorInfo(
      message: '알 수 없는 에러가 발생했습니다.',
      hint: '문제가 지속되면 이슈를 등록해주세요.',
      docs: 'https://github.com/k-auth/flutter/issues',
    ),
  };
}
