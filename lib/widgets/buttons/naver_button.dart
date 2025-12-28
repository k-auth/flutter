import 'package:flutter/material.dart';

import '../icons/social_icons.dart';
import 'base_button.dart';

/// 네이버 로그인 버튼
///
/// 네이버 공식 디자인 가이드라인 준수:
/// - 배경색: #03C75A (네이버 그린)
/// - 텍스트색: #FFFFFF
/// - 심볼: 네이버 N 로고
class NaverLoginButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String text;
  final double? width;
  final double? height;
  final double borderRadius;
  final ButtonSize size;
  final bool isLoading;
  final bool disabled;

  const NaverLoginButton({
    super.key,
    this.onPressed,
    this.text = '네이버 로그인',
    this.width,
    this.height,
    this.borderRadius = 6,
    this.size = ButtonSize.medium,
    this.isLoading = false,
    this.disabled = false,
  });

  /// 아이콘만 있는 버튼
  const NaverLoginButton.icon({
    super.key,
    this.onPressed,
    this.width,
    this.height,
    this.borderRadius = 6,
    this.isLoading = false,
    this.disabled = false,
  })  : text = '',
        size = ButtonSize.icon;

  @override
  Widget build(BuildContext context) {
    return BaseSocialButton(
      onPressed: onPressed,
      text: text,
      width: width,
      height: height,
      borderRadius: borderRadius,
      size: size,
      isLoading: isLoading,
      disabled: disabled,
      bgColor: const Color(0xFF03C75A),
      fgColor: Colors.white,
      icon: NaverIcon(size: SizeConfig.of(size).iconSize),
    );
  }
}
