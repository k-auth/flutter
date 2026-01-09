import 'k_auth_user.dart';
import 'k_auth_failure.dart';

/// 소셜 로그인 결과를 나타내는 클래스
///
/// [KAuth.signIn] 메서드의 반환값으로, 로그인 성공/실패 정보와
/// 사용자 정보, 토큰 등을 포함합니다.
///
/// ## 기본 사용법
///
/// ```dart
/// final result = await kAuth.signIn(AuthProvider.kakao);
///
/// if (result.success) {
///   final user = result.user!;
///   print('환영합니다, ${user.displayName}!');
/// } else {
///   print('로그인 실패: ${result.errorMessage}');
/// }
/// ```
///
/// ## 함수형 스타일 (권장)
///
/// ```dart
/// // fold: 성공/실패 분기
/// final message = result.fold(
///   onSuccess: (user) => '환영합니다, ${user.displayName}!',
///   onFailure: (failure) => '로그인 실패: ${failure.message}',
/// );
///
/// // when: 성공/취소/실패 세분화
/// result.when(
///   success: (user) => navigateToHome(user),
///   cancelled: () => showToast('로그인을 취소했습니다'),
///   failure: (failure) => showError(failure.message),
/// );
///
/// // 체이닝
/// result
///   .onSuccess((user) => saveUser(user))
///   .onFailure((failure) => logError(failure.code, failure.message));
///
/// // 값 추출
/// final name = result.mapUserOr((u) => u.displayName, 'Guest');
/// ```
///
/// ## 토큰 관리
///
/// ```dart
/// if (result.isExpired) {
///   // 토큰 만료됨, 재로그인 필요
/// }
///
/// if (result.isExpiringSoon()) {
///   // 5분 내 만료 예정, 갱신 권장
/// }
///
/// print('남은 시간: ${result.timeUntilExpiry}');
/// ```
///
/// ## JSON 직렬화
///
/// ```dart
/// // 저장
/// final json = result.toJson();
/// await storage.write('auth', jsonEncode(json));
///
/// // 복원
/// final data = jsonDecode(await storage.read('auth'));
/// final restored = AuthResult.fromJson(data);
/// ```
///
/// See also:
/// - [KAuthUser] - 표준화된 사용자 정보
/// - [AuthProvider] - 지원하는 로그인 Provider
/// - [KAuth.signIn] - 로그인 실행 메서드
class AuthResult {
  /// 로그인 성공 여부
  final bool success;

  /// 표준화된 사용자 정보
  ///
  /// 로그인 성공 시에만 값이 있습니다.
  /// `user.id`, `user.email`, `user.name` 등으로 접근하세요.
  final KAuthUser? user;

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
  ///
  /// [user]는 로그인 성공 시 필수이며, 로그아웃/연결해제 성공 시 null입니다.
  factory AuthResult.success({
    required AuthProvider provider,
    KAuthUser? user,
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

  /// 실패 정보를 KAuthFailure로 반환
  ///
  /// fold, when, onFailure에서 사용됩니다.
  /// 에러 코드에 따라 적절한 서브타입 (NetworkError, TokenError 등)을 반환합니다.
  ///
  /// ```dart
  /// result.onFailure((failure) {
  ///   switch (failure) {
  ///     case NetworkError():
  ///       showRetryButton();
  ///     case TokenError():
  ///       navigateToLogin();
  ///     case ConfigError():
  ///       showSetupGuide();
  ///     case CancelledError():
  ///       return; // 무시
  ///     case AuthError():
  ///       showError(failure.message);
  ///   }
  /// });
  /// ```
  KAuthFailure get failure => KAuthFailure.create(
        code: errorCode,
        message: errorMessage,
        hint: errorHint,
      );

  /// 성공/실패에 따라 다른 값 반환
  ///
  /// ```dart
  /// final message = result.fold(
  ///   onSuccess: (user) => '환영합니다, ${user.displayName}님!',
  ///   onFailure: (failure) => '로그인 실패: ${failure.message}',
  /// );
  ///
  /// // 취소 여부 확인
  /// result.fold(
  ///   onSuccess: (user) => navigateToHome(),
  ///   onFailure: (failure) {
  ///     if (failure.isCancelled) {
  ///       // 취소는 조용히 처리
  ///       return;
  ///     }
  ///     showError(failure.message);
  ///   },
  /// );
  /// ```
  T fold<T>({
    required T Function(KAuthUser user) onSuccess,
    required T Function(KAuthFailure failure) onFailure,
  }) {
    if (success && user != null) {
      return onSuccess(user!);
    }
    return onFailure(failure);
  }

  /// 성공/실패/취소에 따라 다른 값 반환
  ///
  /// ```dart
  /// result.when(
  ///   success: (user) => navigateToHome(user),
  ///   cancelled: () => showToast('로그인을 취소했습니다'),
  ///   failure: (failure) => showError(failure.message),
  /// );
  /// ```
  T when<T>({
    required T Function(KAuthUser user) success,
    required T Function() cancelled,
    required T Function(KAuthFailure failure) failure,
  }) {
    if (this.success && user != null) {
      return success(user!);
    }
    if (errorCode == 'USER_CANCELLED') {
      return cancelled();
    }
    return failure(this.failure);
  }

  /// 성공 시에만 콜백 실행
  ///
  /// ```dart
  /// result.onSuccess((user) {
  ///   print('로그인 성공: ${user.name}');
  /// });
  /// ```
  AuthResult onSuccess(void Function(KAuthUser user) callback) {
    if (success && user != null) {
      callback(user!);
    }
    return this;
  }

  /// 실패 시에만 콜백 실행
  ///
  /// ```dart
  /// result.onFailure((failure) {
  ///   print('에러: ${failure.message}');
  ///   if (failure.hint != null) {
  ///     print('힌트: ${failure.hint}');
  ///   }
  /// });
  /// ```
  AuthResult onFailure(void Function(KAuthFailure failure) callback) {
    if (!success) {
      callback(failure);
    }
    return this;
  }

  /// 사용자 정보를 변환하여 반환 (실패 시 null)
  ///
  /// ```dart
  /// final userName = result.mapUser((user) => user.displayName);
  /// ```
  T? mapUser<T>(T Function(KAuthUser user) mapper) {
    if (success && user != null) {
      return mapper(user!);
    }
    return null;
  }

  /// 사용자 정보를 변환하거나 기본값 반환
  ///
  /// ```dart
  /// final userName = result.mapUserOr((user) => user.displayName, 'Guest');
  /// ```
  T mapUserOr<T>(T Function(KAuthUser user) mapper, T defaultValue) {
    if (success && user != null) {
      return mapper(user!);
    }
    return defaultValue;
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
///
/// K-Auth에서 지원하는 OAuth Provider 목록입니다.
///
/// ## 사용 예시
///
/// ```dart
/// // 특정 Provider로 로그인
/// await kAuth.signIn(AuthProvider.kakao);
///
/// // 설정된 Provider 확인
/// if (kAuth.isConfigured(AuthProvider.naver)) {
///   print('네이버 로그인 가능');
/// }
///
/// // Provider 정보 접근
/// print(AuthProvider.kakao.displayName);  // '카카오'
/// print(AuthProvider.kakao.supportsUnlink);  // true
/// ```
///
/// ## Provider별 특징
///
/// | Provider | 연결해제 | 토큰갱신 | 비고 |
/// |----------|---------|---------|------|
/// | kakao | O | O | Native App Key 필요 |
/// | naver | O | O | scope 미지원 (개발자센터에서 설정) |
/// | google | O | O | iOS는 iosClientId 필요 |
/// | apple | X | X | iOS 13+, macOS만 지원 |
enum AuthProvider {
  /// 카카오 로그인
  ///
  /// [KakaoConfig]로 설정합니다.
  /// Native App Key가 필요합니다 (REST API Key 아님).
  kakao,

  /// 네이버 로그인
  ///
  /// [NaverConfig]로 설정합니다.
  /// scope 파라미터를 지원하지 않으므로 개발자센터에서 직접 설정해야 합니다.
  naver,

  /// 구글 로그인
  ///
  /// [GoogleConfig]로 설정합니다.
  /// iOS에서는 iosClientId가 필요합니다.
  google,

  /// 애플 로그인
  ///
  /// [AppleConfig]로 설정합니다.
  /// iOS 13+, macOS에서만 지원됩니다.
  /// 첫 로그인 시에만 이름을 제공합니다.
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
        return false;
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
