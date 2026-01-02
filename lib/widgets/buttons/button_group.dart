import 'package:flutter/material.dart';

import '../../models/auth_result.dart';
import 'apple_button.dart';
import 'base_button.dart';
import 'google_button.dart';
import 'kakao_button.dart';
import 'naver_button.dart';

/// 로그인 버튼 그룹 방향
enum ButtonGroupDirection {
  /// 세로 배치
  vertical,

  /// 가로 배치
  horizontal,
}

/// 로그인 버튼 그룹
///
/// 여러 소셜 로그인 버튼을 한번에 배치합니다.
///
/// ```dart
/// LoginButtonGroup(
///   providers: [AuthProvider.kakao, AuthProvider.naver, AuthProvider.google],
///   onPressed: (provider) => kAuth.signIn(provider),
/// )
/// ```
///
/// ## 로딩 상태
///
/// ```dart
/// LoginButtonGroup(
///   providers: [...],
///   loading: _currentProvider,  // 로딩 중인 Provider
///   onPressed: (p) async {
///     setState(() => _currentProvider = p);
///     await kAuth.signIn(p);
///     setState(() => _currentProvider = null);
///   },
/// )
/// ```
class LoginButtonGroup extends StatelessWidget {
  final List<AuthProvider> providers;
  final void Function(AuthProvider provider)? onPressed;
  final double spacing;
  final ButtonSize buttonSize;
  final ButtonGroupDirection direction;

  /// 현재 로딩 중인 Provider (단일값)
  ///
  /// 해당 Provider 버튼만 로딩 표시되고, 나머지는 비활성화됩니다.
  final AuthProvider? loading;

  /// @Deprecated 대신 [loading]을 사용하세요.
  final Map<AuthProvider, bool> loadingStates;
  final Map<AuthProvider, bool> disabledStates;

  const LoginButtonGroup({
    super.key,
    required this.providers,
    this.onPressed,
    this.spacing = 12,
    this.buttonSize = ButtonSize.medium,
    this.direction = ButtonGroupDirection.vertical,
    this.loading,
    this.loadingStates = const {},
    this.disabledStates = const {},
  });

  @override
  Widget build(BuildContext context) {
    final buttons = providers.map(_buildButton).toList();

    if (direction == ButtonGroupDirection.horizontal) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: _addSpacing(buttons, EdgeInsets.only(right: spacing)),
      );
    }

    return Column(
      children: _addSpacing(buttons, EdgeInsets.only(bottom: spacing)),
    );
  }

  Widget _buildButton(AuthProvider provider) {
    // loading 파라미터 우선, 없으면 loadingStates 사용 (하위 호환성)
    final isLoading = loading == provider || (loadingStates[provider] ?? false);
    // 다른 버튼이 로딩 중이면 비활성화
    final isOtherLoading = loading != null && loading != provider;
    final isDisabled = isOtherLoading || (disabledStates[provider] ?? false);
    void callback() => onPressed?.call(provider);

    return switch (provider) {
      AuthProvider.kakao => KakaoLoginButton(
          onPressed: callback,
          size: buttonSize,
          isLoading: isLoading,
          disabled: isDisabled,
        ),
      AuthProvider.naver => NaverLoginButton(
          onPressed: callback,
          size: buttonSize,
          isLoading: isLoading,
          disabled: isDisabled,
        ),
      AuthProvider.google => GoogleLoginButton(
          onPressed: callback,
          size: buttonSize,
          isLoading: isLoading,
          disabled: isDisabled,
        ),
      AuthProvider.apple => AppleLoginButton(
          onPressed: callback,
          size: buttonSize,
          isLoading: isLoading,
          disabled: isDisabled,
        ),
      AuthProvider.phone => throw UnsupportedError(
          '전화번호 로그인은 LoginButtonGroup에서 지원하지 않습니다. '
          'kAuth.sendCode()와 kAuth.verifyCode()를 사용하세요.',
        ),
    };
  }

  List<Widget> _addSpacing(List<Widget> widgets, EdgeInsets padding) {
    return widgets.asMap().entries.map((entry) {
      if (entry.key < widgets.length - 1) {
        return Padding(padding: padding, child: entry.value);
      }
      return entry.value;
    }).toList();
  }
}
