import 'package:flutter/material.dart';

/// 버튼 사이즈
enum ButtonSize {
  /// 작은 버튼 (높이 36)
  small,

  /// 기본 버튼 (높이 48)
  medium,

  /// 큰 버튼 (높이 56)
  large,

  /// 아이콘만 표시 (정사각형)
  icon,
}

/// 버튼 사이즈 설정
class SizeConfig {
  final double height;
  final double fontSize;
  final double iconSize;
  final double spacing;
  final EdgeInsets padding;

  const SizeConfig({
    required this.height,
    required this.fontSize,
    required this.iconSize,
    required this.spacing,
    required this.padding,
  });

  static SizeConfig of(ButtonSize size) {
    return switch (size) {
      ButtonSize.small => const SizeConfig(
          height: 36,
          fontSize: 14,
          iconSize: 16,
          spacing: 6,
          padding: EdgeInsets.symmetric(horizontal: 12),
        ),
      ButtonSize.medium => const SizeConfig(
          height: 48,
          fontSize: 16,
          iconSize: 20,
          spacing: 8,
          padding: EdgeInsets.symmetric(horizontal: 16),
        ),
      ButtonSize.large => const SizeConfig(
          height: 56,
          fontSize: 18,
          iconSize: 24,
          spacing: 10,
          padding: EdgeInsets.symmetric(horizontal: 20),
        ),
      ButtonSize.icon => const SizeConfig(
          height: 48,
          fontSize: 0,
          iconSize: 24,
          spacing: 0,
          padding: EdgeInsets.zero,
        ),
    };
  }
}

/// 소셜 로그인 버튼 베이스 클래스
class BaseSocialButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String text;
  final double? width;
  final double? height;
  final double borderRadius;
  final ButtonSize size;
  final bool isLoading;
  final bool disabled;
  final Color bgColor;
  final Color fgColor;
  final Color? borderColor;
  final Widget icon;
  final bool outlined;

  const BaseSocialButton({
    super.key,
    required this.onPressed,
    required this.text,
    required this.bgColor,
    required this.fgColor,
    required this.icon,
    this.width,
    this.height,
    this.borderRadius = 6,
    this.size = ButtonSize.medium,
    this.isLoading = false,
    this.disabled = false,
    this.borderColor,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    final config = SizeConfig.of(size);
    final isIconOnly = size == ButtonSize.icon;
    final h = height ?? config.height;
    final w = isIconOnly ? h : (width ?? double.infinity);
    final content = _buildContent(config, isIconOnly);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(borderRadius),
    );

    Widget button;
    if (outlined) {
      button = OutlinedButton(
        onPressed: (disabled || isLoading) ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: fgColor,
          disabledBackgroundColor: bgColor.withValues(alpha: 0.6),
          disabledForegroundColor: fgColor.withValues(alpha: 0.6),
          side: BorderSide(
            color: disabled
                ? (borderColor ?? fgColor).withValues(alpha: 0.6)
                : (borderColor ?? fgColor),
          ),
          shape: shape,
          padding: config.padding,
          elevation: 0,
        ),
        child: content,
      );
    } else {
      button = ElevatedButton(
        onPressed: (disabled || isLoading) ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: fgColor,
          disabledBackgroundColor: bgColor.withValues(alpha: 0.6),
          disabledForegroundColor: fgColor.withValues(alpha: 0.6),
          shape: borderColor != null
              ? RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(borderRadius),
                  side: BorderSide(
                    color: disabled
                        ? borderColor!.withValues(alpha: 0.6)
                        : borderColor!,
                  ),
                )
              : shape,
          padding: config.padding,
          elevation: 0,
        ),
        child: content,
      );
    }

    return SizedBox(width: w, height: h, child: button);
  }

  Widget _buildContent(SizeConfig config, bool isIconOnly) {
    if (isLoading) {
      return SizedBox(
        width: config.iconSize,
        height: config.iconSize,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(fgColor),
        ),
      );
    }

    if (isIconOnly) return icon;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        icon,
        SizedBox(width: config.spacing),
        Text(
          text,
          style: TextStyle(
            fontSize: config.fontSize,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
