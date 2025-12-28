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
class LoginButtonGroup extends StatelessWidget {
  final List<AuthProvider> providers;
  final void Function(AuthProvider provider)? onPressed;
  final double spacing;
  final ButtonSize buttonSize;
  final ButtonGroupDirection direction;
  final Map<AuthProvider, bool> loadingStates;
  final Map<AuthProvider, bool> disabledStates;

  const LoginButtonGroup({
    super.key,
    required this.providers,
    this.onPressed,
    this.spacing = 12,
    this.buttonSize = ButtonSize.medium,
    this.direction = ButtonGroupDirection.vertical,
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
    final isLoading = loadingStates[provider] ?? false;
    final isDisabled = disabledStates[provider] ?? false;
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
