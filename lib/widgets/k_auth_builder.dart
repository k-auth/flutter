import 'package:flutter/material.dart';

import '../models/k_auth_user.dart';

/// 인증 상태에 따라 화면을 자동으로 전환하는 위젯
///
/// ```dart
/// KAuthBuilder(
///   stream: kAuth.authStateChanges,
///   signedIn: (user) => HomeScreen(user: user),
///   signedOut: () => LoginScreen(),
///   loading: () => SplashScreen(),
///   error: (e) => ErrorScreen(error: e),
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

  /// 초기 사용자 (스트림 연결 전)
  final KAuthUser? initialUser;

  const KAuthBuilder({
    super.key,
    required this.stream,
    required this.signedIn,
    required this.signedOut,
    this.loading,
    this.error,
    this.initialUser,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<KAuthUser?>(
      stream: stream,
      initialData: initialUser,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return loading?.call() ??
              const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return error?.call(snapshot.error!) ??
              Center(child: Text('오류: ${snapshot.error}'));
        }

        final user = snapshot.data;
        if (user != null) return signedIn(user);
        return signedOut();
      },
    );
  }
}
