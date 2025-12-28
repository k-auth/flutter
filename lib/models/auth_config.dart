import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform;

import '../errors/k_auth_error.dart';

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

  /// 설정 유효성 검증
  ///
  /// [throwOnError]가 true이면 에러 시 예외를 던지고,
  /// false이면 에러 목록을 반환합니다.
  ///
  /// [targetPlatform]을 지정하면 해당 플랫폼 기준으로 검증합니다.
  /// 지정하지 않으면 현재 플랫폼([defaultTargetPlatform])을 사용합니다.
  List<KAuthError> validate({
    bool throwOnError = false,
    TargetPlatform? targetPlatform,
  }) {
    final errors = <KAuthError>[];
    final platform = targetPlatform ?? defaultTargetPlatform;

    // 최소 하나의 Provider가 설정되어 있어야 함
    if (kakao == null && naver == null && google == null && apple == null) {
      errors.add(KAuthError.fromCode(ErrorCodes.noProviderConfigured));
    }

    // 각 Provider 설정 검증
    if (kakao != null) {
      errors.addAll(kakao!.validate());
    }

    if (naver != null) {
      errors.addAll(naver!.validate());
    }

    if (google != null) {
      errors.addAll(google!.validate(targetPlatform: platform));
    }

    if (apple != null) {
      errors.addAll(apple!.validate());
    }

    if (throwOnError && errors.isNotEmpty) {
      throw errors.first;
    }

    return errors;
  }

  /// 설정이 유효한지 확인
  bool get isValid => validate().isEmpty;

  /// 설정된 Provider 목록
  List<String> get configuredProviders {
    final providers = <String>[];
    if (kakao != null) providers.add('kakao');
    if (naver != null) providers.add('naver');
    if (google != null) providers.add('google');
    if (apple != null) providers.add('apple');
    return providers;
  }
}

// ============================================
// 카카오 설정
// ============================================

/// 카카오 수집 옵션
///
/// 카카오 개발자센터에서 해당 항목을 먼저 활성화해야 합니다.
/// https://developers.kakao.com/console
class KakaoCollectOptions {
  /// 이메일 수집 (기본: true)
  final bool email;

  /// 프로필 정보 수집 - 닉네임, 프로필 이미지 (기본: true)
  final bool profile;

  /// 전화번호 수집 (개발자센터에서 활성화 필요)
  final bool phone;

  /// 생일 수집
  final bool birthday;

  /// 성별 수집
  final bool gender;

  /// 연령대 수집
  final bool ageRange;

  /// CI(연계정보) 수집 (카카오싱크 비즈니스용)
  final bool ci;

  const KakaoCollectOptions({
    this.email = true,
    this.profile = true,
    this.phone = false,
    this.birthday = false,
    this.gender = false,
    this.ageRange = false,
    this.ci = false,
  });

  /// 기본 옵션 (이메일, 프로필만)
  static const KakaoCollectOptions defaults = KakaoCollectOptions();

  /// 모든 옵션 활성화
  static const KakaoCollectOptions all = KakaoCollectOptions(
    email: true,
    profile: true,
    phone: true,
    birthday: true,
    gender: true,
    ageRange: true,
    ci: true,
  );

  /// scope 문자열 목록 생성
  List<String> toScopes() {
    final scopes = <String>[];

    if (profile) {
      scopes.add('profile_nickname');
      scopes.add('profile_image');
    }

    if (email) {
      scopes.add('account_email');
    }

    if (phone) {
      scopes.add('phone_number');
    }

    if (birthday) {
      scopes.add('birthday');
      scopes.add('birthyear');
    }

    if (gender) {
      scopes.add('gender');
    }

    if (ageRange) {
      scopes.add('age_range');
    }

    if (ci) {
      scopes.add('account_ci');
    }

    return scopes;
  }
}

/// 카카오 로그인 설정
class KakaoConfig {
  /// 카카오 앱 키 (Native App Key)
  ///
  /// REST API Key가 아닌 Native App Key를 사용해야 합니다.
  final String appKey;

  /// 수집 옵션
  final KakaoCollectOptions collect;

  /// 추가 scope (기본 scope 외 추가로 필요한 경우)
  final List<String>? additionalScopes;

  const KakaoConfig({
    required this.appKey,
    this.collect = const KakaoCollectOptions(),
    this.additionalScopes,
  });

  /// 전체 scope 목록
  List<String> get allScopes {
    final scopes = collect.toScopes();

    if (additionalScopes != null) {
      scopes.addAll(additionalScopes!);
    }

    return scopes.toSet().toList();
  }

  /// 설정 검증
  List<KAuthError> validate() {
    final errors = <KAuthError>[];

    if (appKey.isEmpty) {
      errors.add(KAuthError.fromCode(
        ErrorCodes.missingAppKey,
        details: {'provider': 'kakao'},
      ));
    }

    return errors;
  }
}

// ============================================
// 네이버 설정
// ============================================

/// 네이버 수집 옵션
///
/// ⚠️ 중요: 네이버는 OAuth scope 파라미터를 지원하지 않습니다.
/// 수집 항목은 네이버 개발자센터에서 직접 설정해야 합니다.
/// https://developers.naver.com/apps
///
/// 이 클래스는 문서화 및 타입 안전성 목적으로만 제공됩니다.
class NaverCollectOptions {
  /// 이메일 (개발자센터에서 설정)
  final bool email;

  /// 별명 (개발자센터에서 설정)
  final bool nickname;

  /// 프로필 이미지 (개발자센터에서 설정)
  final bool profileImage;

  /// 이름 (개발자센터에서 설정)
  final bool name;

  /// 생일 (개발자센터에서 설정)
  final bool birthday;

  /// 연령대 (개발자센터에서 설정)
  final bool ageRange;

  /// 성별 (개발자센터에서 설정)
  final bool gender;

  /// 휴대전화번호 (개발자센터에서 설정)
  final bool mobile;

  const NaverCollectOptions({
    this.email = true,
    this.nickname = true,
    this.profileImage = true,
    this.name = false,
    this.birthday = false,
    this.ageRange = false,
    this.gender = false,
    this.mobile = false,
  });

  /// 기본 옵션
  static const NaverCollectOptions defaults = NaverCollectOptions();
}

/// 네이버 로그인 설정
class NaverConfig {
  /// 클라이언트 ID
  final String clientId;

  /// 클라이언트 시크릿
  final String clientSecret;

  /// 앱 이름 (로그인 화면에 표시)
  final String appName;

  /// 수집 옵션 (문서화 목적, 실제 설정은 개발자센터에서)
  ///
  /// ⚠️ 네이버는 scope 파라미터를 지원하지 않습니다.
  /// 이 옵션은 어떤 데이터를 수집하는지 기록용으로만 사용됩니다.
  final NaverCollectOptions? collect;

  const NaverConfig({
    required this.clientId,
    required this.clientSecret,
    required this.appName,
    this.collect,
  });

  /// 설정 검증
  List<KAuthError> validate() {
    final errors = <KAuthError>[];

    if (clientId.isEmpty) {
      errors.add(KAuthError.fromCode(
        ErrorCodes.missingClientId,
        details: {'provider': 'naver'},
      ));
    }

    if (clientSecret.isEmpty) {
      errors.add(KAuthError.fromCode(
        ErrorCodes.missingClientSecret,
        details: {'provider': 'naver'},
      ));
    }

    return errors;
  }
}

// ============================================
// 구글 설정
// ============================================

/// 구글 수집 옵션
class GoogleCollectOptions {
  /// 이메일 수집 (기본: true)
  final bool email;

  /// 프로필 정보 수집 (기본: true)
  final bool profile;

  /// OpenID Connect 사용 (기본: true)
  final bool openid;

  const GoogleCollectOptions({
    this.email = true,
    this.profile = true,
    this.openid = true,
  });

  /// 기본 옵션
  static const GoogleCollectOptions defaults = GoogleCollectOptions();

  /// scope 문자열 목록 생성
  List<String> toScopes() {
    final scopes = <String>[];

    if (openid) scopes.add('openid');
    if (email) scopes.add('email');
    if (profile) scopes.add('profile');

    return scopes;
  }
}

/// 구글 로그인 설정
class GoogleConfig {
  /// iOS 클라이언트 ID (iOS에서 필수)
  final String? iosClientId;

  /// 서버 클라이언트 ID (백엔드 연동 시)
  final String? serverClientId;

  /// 수집 옵션
  final GoogleCollectOptions collect;

  /// 추가 scope
  final List<String>? additionalScopes;

  /// 항상 동의 화면 표시 (refresh token 획득 시 필요)
  final bool forceConsent;

  const GoogleConfig({
    this.iosClientId,
    this.serverClientId,
    this.collect = const GoogleCollectOptions(),
    this.additionalScopes,
    this.forceConsent = false,
  });

  /// 전체 scope 목록
  List<String> get allScopes {
    final scopes = collect.toScopes();

    if (additionalScopes != null) {
      scopes.addAll(additionalScopes!);
    }

    return scopes.toSet().toList();
  }

  /// 설정 검증
  ///
  /// iOS 플랫폼에서는 [iosClientId]가 필수입니다.
  /// [targetPlatform]을 지정하면 해당 플랫폼 기준으로 검증합니다.
  List<KAuthError> validate({TargetPlatform? targetPlatform}) {
    final errors = <KAuthError>[];

    // iOS 플랫폼 체크
    final isIOS = targetPlatform == TargetPlatform.iOS ||
        targetPlatform == TargetPlatform.macOS;

    if (isIOS && (iosClientId == null || iosClientId!.isEmpty)) {
      errors.add(KAuthError.fromCode(
        ErrorCodes.googleMissingIosClientId,
        details: {'provider': 'google'},
      ));
    }

    return errors;
  }
}

// ============================================
// 애플 설정
// ============================================

/// 애플 수집 옵션
class AppleCollectOptions {
  /// 이메일 수집 (기본: true)
  final bool email;

  /// 이름 수집 (기본: true)
  ///
  /// ⚠️ 주의: 애플은 첫 로그인 시에만 이름을 제공합니다.
  final bool fullName;

  const AppleCollectOptions({
    this.email = true,
    this.fullName = true,
  });

  /// 기본 옵션
  static const AppleCollectOptions defaults = AppleCollectOptions();
}

/// 애플 로그인 설정
class AppleConfig {
  /// 수집 옵션
  final AppleCollectOptions collect;

  const AppleConfig({
    this.collect = const AppleCollectOptions(),
  });

  /// 설정 검증
  List<KAuthError> validate() {
    return [];
  }
}
