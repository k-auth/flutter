/// 소셜 로그인 버튼 위젯
///
/// 카카오, 네이버, 구글, 애플 로그인 버튼과 관련 위젯을 제공합니다.
///
/// ## 개별 버튼 사용
/// ```dart
/// KakaoLoginButton(onPressed: () => kAuth.signIn(AuthProvider.kakao))
/// NaverLoginButton(onPressed: () => kAuth.signIn(AuthProvider.naver))
/// GoogleLoginButton(onPressed: () => kAuth.signIn(AuthProvider.google))
/// AppleLoginButton(onPressed: () => kAuth.signIn(AuthProvider.apple))
/// ```
///
/// ## 버튼 그룹 사용
/// ```dart
/// LoginButtonGroup(
///   providers: [AuthProvider.kakao, AuthProvider.naver, AuthProvider.google],
///   onPressed: (provider) => kAuth.signIn(provider),
/// )
/// ```
///
/// ## 인증 상태 기반 화면 전환
/// ```dart
/// KAuthBuilder(
///   stream: kAuth.authStateChanges,
///   signedIn: (user) => HomeScreen(user: user),
///   signedOut: () => LoginScreen(),
/// )
/// ```
library;

// 버튼 기본 클래스
export 'buttons/base_button.dart' show ButtonSize, SizeConfig;

// 개별 버튼
export 'buttons/kakao_button.dart';
export 'buttons/naver_button.dart';
export 'buttons/google_button.dart';
export 'buttons/apple_button.dart';

// 버튼 그룹
export 'buttons/button_group.dart';

// 아이콘 (필요시 직접 사용 가능)
export 'icons/social_icons.dart';

// KAuthBuilder
export 'k_auth_builder.dart';
