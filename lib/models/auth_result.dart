import 'k_auth_user.dart';

/// 소셜 로그인 결과
class AuthResult {
  /// 로그인 성공 여부
  final bool success;

  /// 표준화된 사용자 정보
  final KAuthUser? user;

  /// 사용자 고유 ID (provider별 고유값)
  /// [user.id]와 동일 (하위 호환성 유지)
  final String? userId;

  /// 사용자 이메일
  /// [user.email]와 동일 (하위 호환성 유지)
  final String? email;

  /// 사용자 이름
  /// [user.name]와 동일 (하위 호환성 유지)
  final String? name;

  /// 프로필 이미지 URL
  /// [user.image]와 동일 (하위 호환성 유지)
  final String? profileImageUrl;

  /// 액세스 토큰
  final String? accessToken;

  /// 리프레시 토큰
  final String? refreshToken;

  /// ID 토큰 (OIDC)
  final String? idToken;

  /// 토큰 만료 시간
  final DateTime? expiresAt;

  /// 에러 메시지 (실패 시)
  final String? errorMessage;

  /// 에러 코드 (실패 시)
  final String? errorCode;

  /// 에러 힌트 (실패 시)
  final String? errorHint;

  /// 로그인한 Provider 타입
  final AuthProvider provider;

  /// 원본 응답 데이터
  final Map<String, dynamic>? rawData;

  const AuthResult({
    required this.success,
    required this.provider,
    this.user,
    this.userId,
    this.email,
    this.name,
    this.profileImageUrl,
    this.accessToken,
    this.refreshToken,
    this.idToken,
    this.expiresAt,
    this.errorMessage,
    this.errorCode,
    this.errorHint,
    this.rawData,
  });

  /// 성공 결과 생성
  factory AuthResult.success({
    required AuthProvider provider,
    required KAuthUser user,
    String? accessToken,
    String? refreshToken,
    String? idToken,
    DateTime? expiresAt,
    Map<String, dynamic>? rawData,
  }) {
    return AuthResult(
      success: true,
      provider: provider,
      user: user,
      userId: user.id,
      email: user.email,
      name: user.name,
      profileImageUrl: user.image,
      accessToken: accessToken,
      refreshToken: refreshToken,
      idToken: idToken,
      expiresAt: expiresAt,
      rawData: rawData,
    );
  }

  /// 실패 결과 생성
  factory AuthResult.failure({
    required AuthProvider provider,
    required String errorMessage,
    String? errorCode,
    String? errorHint,
  }) {
    return AuthResult(
      success: false,
      provider: provider,
      errorMessage: errorMessage,
      errorCode: errorCode,
      errorHint: errorHint,
    );
  }

  /// 토큰이 만료되었는지 확인
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  /// 토큰이 곧 만료되는지 확인 (기본 5분 전)
  bool isExpiringSoon([Duration threshold = const Duration(minutes: 5)]) {
    if (expiresAt == null) return false;
    return DateTime.now().add(threshold).isAfter(expiresAt!);
  }

  /// 토큰 만료까지 남은 시간
  Duration? get timeUntilExpiry {
    if (expiresAt == null) return null;
    final remaining = expiresAt!.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// JSON으로 변환
  Map<String, dynamic> toJson() => {
        'success': success,
        'provider': provider.name,
        if (user != null) 'user': user!.toJson(),
        if (userId != null) 'userId': userId,
        if (email != null) 'email': email,
        if (name != null) 'name': name,
        if (profileImageUrl != null) 'profileImageUrl': profileImageUrl,
        if (accessToken != null) 'accessToken': accessToken,
        if (refreshToken != null) 'refreshToken': refreshToken,
        if (idToken != null) 'idToken': idToken,
        if (expiresAt != null) 'expiresAt': expiresAt!.toIso8601String(),
        if (errorMessage != null) 'errorMessage': errorMessage,
        if (errorCode != null) 'errorCode': errorCode,
        if (errorHint != null) 'errorHint': errorHint,
      };

  /// JSON에서 생성
  factory AuthResult.fromJson(Map<String, dynamic> json) {
    return AuthResult(
      success: json['success'] as bool,
      provider: AuthProvider.values.firstWhere(
        (p) => p.name == json['provider'],
        orElse: () => AuthProvider.kakao,
      ),
      user: json['user'] != null
          ? KAuthUser.fromJson(json['user'] as Map<String, dynamic>)
          : null,
      userId: json['userId'] as String?,
      email: json['email'] as String?,
      name: json['name'] as String?,
      profileImageUrl: json['profileImageUrl'] as String?,
      accessToken: json['accessToken'] as String?,
      refreshToken: json['refreshToken'] as String?,
      idToken: json['idToken'] as String?,
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'] as String)
          : null,
      errorMessage: json['errorMessage'] as String?,
      errorCode: json['errorCode'] as String?,
      errorHint: json['errorHint'] as String?,
      rawData: json['rawData'] as Map<String, dynamic>?,
    );
  }

  @override
  String toString() {
    if (success) {
      return 'AuthResult.success(provider: $provider, user: $user)';
    }
    return 'AuthResult.failure(provider: $provider, error: $errorMessage)';
  }
}

/// 지원하는 소셜 로그인 Provider
enum AuthProvider {
  kakao,
  naver,
  google,
  apple;

  /// 표시용 이름
  String get displayName {
    switch (this) {
      case AuthProvider.kakao:
        return '카카오';
      case AuthProvider.naver:
        return '네이버';
      case AuthProvider.google:
        return 'Google';
      case AuthProvider.apple:
        return 'Apple';
    }
  }

  /// 영문 이름
  String get englishName {
    switch (this) {
      case AuthProvider.kakao:
        return 'Kakao';
      case AuthProvider.naver:
        return 'Naver';
      case AuthProvider.google:
        return 'Google';
      case AuthProvider.apple:
        return 'Apple';
    }
  }

  /// 연결 해제 지원 여부
  bool get supportsUnlink {
    switch (this) {
      case AuthProvider.kakao:
      case AuthProvider.naver:
      case AuthProvider.google:
        return true;
      case AuthProvider.apple:
        return false; // Apple은 서버사이드 revoke만 지원
    }
  }

  /// 토큰 갱신 지원 여부
  bool get supportsTokenRefresh {
    switch (this) {
      case AuthProvider.kakao:
      case AuthProvider.naver:
      case AuthProvider.google:
        return true;
      case AuthProvider.apple:
        return false;
    }
  }
}
