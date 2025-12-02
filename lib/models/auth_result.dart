/// 소셜 로그인 결과
class AuthResult {
  /// 로그인 성공 여부
  final bool success;

  /// 사용자 고유 ID (provider별 고유값)
  final String? userId;

  /// 사용자 이메일
  final String? email;

  /// 사용자 이름
  final String? name;

  /// 프로필 이미지 URL
  final String? profileImageUrl;

  /// 액세스 토큰
  final String? accessToken;

  /// 리프레시 토큰
  final String? refreshToken;

  /// 토큰 만료 시간
  final DateTime? expiresAt;

  /// 에러 메시지 (실패 시)
  final String? errorMessage;

  /// 에러 코드 (실패 시)
  final String? errorCode;

  /// 로그인한 Provider 타입
  final AuthProvider provider;

  /// 원본 응답 데이터
  final Map<String, dynamic>? rawData;

  const AuthResult({
    required this.success,
    required this.provider,
    this.userId,
    this.email,
    this.name,
    this.profileImageUrl,
    this.accessToken,
    this.refreshToken,
    this.expiresAt,
    this.errorMessage,
    this.errorCode,
    this.rawData,
  });

  /// 성공 결과 생성
  factory AuthResult.success({
    required AuthProvider provider,
    required String userId,
    String? email,
    String? name,
    String? profileImageUrl,
    String? accessToken,
    String? refreshToken,
    DateTime? expiresAt,
    Map<String, dynamic>? rawData,
  }) {
    return AuthResult(
      success: true,
      provider: provider,
      userId: userId,
      email: email,
      name: name,
      profileImageUrl: profileImageUrl,
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresAt: expiresAt,
      rawData: rawData,
    );
  }

  /// 실패 결과 생성
  factory AuthResult.failure({
    required AuthProvider provider,
    required String errorMessage,
    String? errorCode,
  }) {
    return AuthResult(
      success: false,
      provider: provider,
      errorMessage: errorMessage,
      errorCode: errorCode,
    );
  }

  @override
  String toString() {
    return 'AuthResult(success: $success, provider: $provider, userId: $userId, email: $email)';
  }
}

/// 지원하는 소셜 로그인 Provider
enum AuthProvider {
  kakao,
  naver,
  google,
  apple,
}
