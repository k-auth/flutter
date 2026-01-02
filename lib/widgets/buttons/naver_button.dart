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
  /// 버튼 클릭 콜백. null이면 버튼이 비활성화됩니다.
  final VoidCallback? onPressed;

  /// 버튼에 표시할 텍스트. 기본값: '네이버 로그인'
  final String text;

  /// 버튼 너비. null이면 부모 위젯에 맞춤.
  final double? width;

  /// 버튼 높이. null이면 [size]에 따라 자동 결정.
  final double? height;

  /// 버튼 모서리 둥글기. 기본값: 6
  final double borderRadius;

  /// 버튼 크기 프리셋. [ButtonSize.small], [ButtonSize.medium], [ButtonSize.large], [ButtonSize.icon]
  final ButtonSize size;

  /// 로딩 상태. true면 로딩 인디케이터 표시.
  final bool isLoading;

  /// 비활성화 상태. true면 버튼을 누를 수 없음.
  final bool disabled;

  /// 네이버 로그인 버튼을 생성합니다.
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
