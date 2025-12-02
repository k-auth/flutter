/// KAuth 설정
class KAuthConfig {
  /// 카카오 설정
  final KakaoConfig? kakao;

  /// 네이버 설정
  final NaverConfig? naver;

  /// 구글 설정
  final GoogleConfig? google;

  /// 애플 설정
  final AppleConfig? apple;

  const KAuthConfig({
    this.kakao,
    this.naver,
    this.google,
    this.apple,
  });
}

/// 카카오 로그인 설정
class KakaoConfig {
  /// 카카오 앱 키 (Native App Key)
  final String appKey;

  /// 추가 scope (기본: profile_nickname, profile_image, account_email)
  final List<String>? scopes;

  /// 전화번호 수집 여부
  final bool collectPhone;

  const KakaoConfig({
    required this.appKey,
    this.scopes,
    this.collectPhone = false,
  });

  /// 전체 scope 목록
  List<String> get allScopes {
    final defaultScopes = [
      'profile_nickname',
      'profile_image',
      'account_email',
    ];

    if (collectPhone) {
      defaultScopes.add('phone_number');
    }

    if (scopes != null) {
      defaultScopes.addAll(scopes!);
    }

    return defaultScopes.toSet().toList();
  }
}

/// 네이버 로그인 설정
class NaverConfig {
  /// 클라이언트 ID
  final String clientId;

  /// 클라이언트 시크릿
  final String clientSecret;

  /// 앱 이름 (로그인 화면에 표시)
  final String appName;

  const NaverConfig({
    required this.clientId,
    required this.clientSecret,
    required this.appName,
  });
}

/// 구글 로그인 설정
class GoogleConfig {
  /// iOS 클라이언트 ID (iOS에서만 필요)
  final String? iosClientId;

  /// 서버 클라이언트 ID (백엔드 연동 시)
  final String? serverClientId;

  /// 추가 scope
  final List<String>? scopes;

  const GoogleConfig({
    this.iosClientId,
    this.serverClientId,
    this.scopes,
  });
}

/// 애플 로그인 설정
class AppleConfig {
  /// 추가 scope (기본: email, fullName)
  final List<String>? scopes;

  const AppleConfig({
    this.scopes,
  });
}
