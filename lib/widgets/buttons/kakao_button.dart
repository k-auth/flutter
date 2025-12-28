import 'package:flutter/material.dart';

import '../icons/social_icons.dart';
import 'base_button.dart';

/// 카카오 로그인 버튼
///
/// 카카오 공식 디자인 가이드라인 준수:
/// - 배경색: #FEE500
/// - 텍스트색: #000000 (85% 투명도)
/// - Corner Radius: 12px
/// - 심볼: 카카오 말풍선
class KakaoLoginButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String text;
  final double? width;
  final double? height;
  final double borderRadius;
  final ButtonSize size;
  final bool isLoading;
  final bool disabled;

  const KakaoLoginButton({
    super.key,
    this.onPressed,
    this.text = '카카오 로그인',
    this.width,
    this.height,
    this.borderRadius = 12, // 카카오 공식 가이드: 12px
    this.size = ButtonSize.medium,
    this.isLoading = false,
    this.disabled = false,
  });

  /// 아이콘만 있는 버튼
  const KakaoLoginButton.icon({
    super.key,
    this.onPressed,
    this.width,
    this.height,
    this.borderRadius = 12,
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
      bgColor: const Color(0xFFFEE500),
      fgColor: const Color(0xD9000000), // #000000 85% 투명도
      icon: KakaoIcon(size: SizeConfig.of(size).iconSize),
    );
  }
}
