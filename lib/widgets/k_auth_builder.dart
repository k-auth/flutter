import 'package:flutter/material.dart';

import '../models/k_auth_user.dart';

/// 인증 상태
///
/// [KAuthBuilder]에서 현재 인증 상태를 나타냅니다.
enum AuthState {
  /// 로딩 중
  loading,

  /// 로그인됨
  signedIn,

  /// 로그아웃됨
  signedOut,

  /// 토큰 만료 임박
  expiring,

  /// 에러
  error,
}

/// 인증 상태에 따라 화면을 자동으로 전환하는 위젯
///
/// ## 기본 사용법
///
/// ```dart
/// KAuthBuilder(
///   stream: kAuth.authStateChanges,
///   signedIn: (user) => HomeScreen(user: user),
///   signedOut: () => LoginScreen(),
/// )
/// ```
///
/// ## 토큰 만료 처리
///
/// ```dart
/// KAuthBuilder(
///   stream: kAuth.authStateChanges,
///   signedIn: (user) => HomeScreen(user: user),
///   signedOut: () => LoginScreen(),
///   expiring: () => TokenRefreshBanner(),  // 만료 임박 시 표시
///   isExpiring: kAuth.isExpiringSoon,      // 만료 임박 여부 판단
/// )
/// ```
///
/// ## 모든 상태 처리
///
/// ```dart
/// KAuthBuilder(
///   stream: kAuth.authStateChanges,
///   signedIn: (user) => HomeScreen(user: user),
///   signedOut: () => LoginScreen(),
///   loading: () => SplashScreen(),
///   error: (e) => ErrorScreen(error: e),
///   expiring: () => TokenRefreshBanner(),
///   isExpiring: kAuth.isExpiringSoon,
/// )
/// ```
class KAuthBuilder extends StatelessWidget {
  /// 인증 상태 변화 스트림
  final Stream<KAuthUser?> stream;

  /// 로그인 상태일 때 표시할 위젯
  final Widget Function(KAuthUser user) signedIn;

  /// 로그아웃 상태일 때 표시할 위젯
  final Widget Function() signedOut;

  /// 로딩 중일 때 표시할 위젯 (선택)
  final Widget Function()? loading;

  /// 에러 발생 시 표시할 위젯 (선택)
  final Widget Function(Object error)? error;

  /// 토큰 만료 임박 시 표시할 위젯 (선택)
  ///
  /// [isExpiring]이 true를 반환할 때 표시됩니다.
  /// 보통 갱신 버튼이나 배너를 표시합니다.
  ///
  /// ```dart
  /// expiring: () => RefreshBanner(onRefresh: kAuth.refreshToken),
  /// ```
  final Widget Function()? expiring;

  /// 토큰 만료 임박 여부를 판단하는 함수 (선택)
  ///
  /// [expiring]과 함께 사용됩니다.
  /// 기본적으로 false를 반환합니다.
  ///
  /// ```dart
  /// isExpiring: kAuth.isExpiringSoon,
  /// // 또는 커스텀 로직
  /// isExpiring: () => kAuth.expiresIn.inMinutes < 10,
  /// ```
  final bool Function()? isExpiring;

  /// 초기 사용자 (스트림 연결 전)
  final KAuthUser? initialUser;

  const KAuthBuilder({
    super.key,
    required this.stream,
    required this.signedIn,
    required this.signedOut,
    this.loading,
    this.error,
    this.expiring,
    this.isExpiring,
    this.initialUser,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<KAuthUser?>(
      stream: stream,
      initialData: initialUser,
      builder: (context, snapshot) {
        // 로딩 상태
        if (snapshot.connectionState == ConnectionState.waiting) {
          return loading?.call() ??
              const Center(child: CircularProgressIndicator());
        }

        // 에러 상태
        if (snapshot.hasError) {
          return error?.call(snapshot.error!) ??
              Center(child: Text('오류: ${snapshot.error}'));
        }

        final user = snapshot.data;

        // 로그인된 상태
        if (user != null) {
          // 토큰 만료 임박 체크
          if (expiring != null && isExpiring != null && isExpiring!()) {
            return Stack(
              children: [
                signedIn(user),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: SafeArea(child: expiring!()),
                ),
              ],
            );
          }
          return signedIn(user);
        }

        // 로그아웃 상태
        return signedOut();
      },
    );
  }
}

/// 간단한 토큰 만료 배너 위젯
///
/// [KAuthBuilder]의 [expiring]과 함께 사용할 수 있습니다.
///
/// ```dart
/// KAuthBuilder(
///   stream: kAuth.authStateChanges,
///   signedIn: (user) => HomeScreen(user: user),
///   signedOut: () => LoginScreen(),
///   expiring: () => TokenBanner(
///     onRefresh: () => kAuth.refreshToken(),
///   ),
///   isExpiring: kAuth.isExpiringSoon,
/// )
/// ```
class TokenBanner extends StatelessWidget {
  /// 갱신 버튼 클릭 시 콜백
  final VoidCallback? onRefresh;

  /// 메시지 (기본: '세션이 곧 만료됩니다')
  final String? message;

  /// 버튼 텍스트 (기본: '갱신')
  final String? buttonText;

  /// 배경색
  final Color? backgroundColor;

  /// 텍스트 색상
  final Color? textColor;

  const TokenBanner({
    super.key,
    this.onRefresh,
    this.message,
    this.buttonText,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = backgroundColor ?? Colors.orange.shade100;
    final txtColor = textColor ?? Colors.orange.shade900;

    return Material(
      color: bgColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Icon(Icons.timer_outlined, color: txtColor, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message ?? '세션이 곧 만료됩니다',
                style: theme.textTheme.bodyMedium?.copyWith(color: txtColor),
              ),
            ),
            if (onRefresh != null)
              TextButton(
                onPressed: onRefresh,
                child: Text(
                  buttonText ?? '갱신',
                  style:
                      TextStyle(color: txtColor, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
