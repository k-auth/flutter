import 'package:flutter/material.dart';

import '../icons/social_icons.dart';
import 'base_button.dart';

/// 구글 로그인 버튼
///
/// 구글 공식 브랜딩 가이드라인 준수:
/// - 배경색: #FFFFFF
/// - 텍스트색: #1F1F1F
/// - Border: #747775 (1px)
/// - 아이콘: 멀티컬러 G 로고 필수
class GoogleLoginButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String text;
  final double? width;
  final double? height;
  final double borderRadius;
  final ButtonSize size;
  final bool isLoading;
  final bool disabled;

  const GoogleLoginButton({
    super.key,
    this.onPressed,
    this.text = 'Google로 로그인',
    this.width,
    this.height,
    this.borderRadius = 6,
    this.size = ButtonSize.medium,
    this.isLoading = false,
    this.disabled = false,
  });

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
      bgColor: Colors.white,
      fgColor: const Color(0xFF1F1F1F),
      borderColor: const Color(0xFF747775), // 구글 공식 가이드: #747775
      outlined: true,
      icon: GoogleIcon(size: SizeConfig.of(size).iconSize),
    );
  }
}
