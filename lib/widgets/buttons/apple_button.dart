import 'package:flutter/material.dart';

import '../icons/social_icons.dart';
import 'base_button.dart';

/// 애플 로그인 버튼
///
/// 애플 공식 Human Interface Guidelines 준수:
/// - 배경색: Black 또는 White
/// - 텍스트색: 배경 반대색
/// - 최소 높이: 44pt
/// - 심볼: 애플 로고
class AppleLoginButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String text;
  final double? width;
  final double? height;
  final double borderRadius;
  final bool isDark;
  final ButtonSize size;
  final bool isLoading;
  final bool disabled;

  const AppleLoginButton({
    super.key,
    this.onPressed,
    this.text = 'Apple로 로그인',
    this.width,
    this.height,
    this.borderRadius = 6,
    this.isDark = true,
    this.size = ButtonSize.medium,
    this.isLoading = false,
    this.disabled = false,
  });

  /// 아이콘만 있는 버튼 (다크 모드)
  const AppleLoginButton.icon({
    super.key,
    this.onPressed,
    this.width,
    this.height,
    this.borderRadius = 6,
    this.isDark = true,
    this.isLoading = false,
    this.disabled = false,
  })  : text = '',
        size = ButtonSize.icon;

  @override
  Widget build(BuildContext context) {
    final bgColor = isDark ? Colors.black : Colors.white;
    final fgColor = isDark ? Colors.white : Colors.black;

    return BaseSocialButton(
      onPressed: onPressed,
      text: text,
      width: width,
      height: height,
      borderRadius: borderRadius,
      size: size,
      isLoading: isLoading,
      disabled: disabled,
      bgColor: bgColor,
      fgColor: fgColor,
      borderColor: isDark ? null : Colors.black,
      icon: AppleIcon(isDark: isDark, size: SizeConfig.of(size).iconSize),
    );
  }
}
