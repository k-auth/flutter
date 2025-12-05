import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../models/auth_result.dart';

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
class _ButtonSizeConfig {
  final double height;
  final double fontSize;
  final double iconSize;
  final double spacing;
  final EdgeInsets padding;

  const _ButtonSizeConfig({
    required this.height,
    required this.fontSize,
    required this.iconSize,
    required this.spacing,
    required this.padding,
  });

  static _ButtonSizeConfig fromSize(ButtonSize size) {
    switch (size) {
      case ButtonSize.small:
        return const _ButtonSizeConfig(
          height: 36,
          fontSize: 14,
          iconSize: 16,
          spacing: 6,
          padding: EdgeInsets.symmetric(horizontal: 12),
        );
      case ButtonSize.medium:
        return const _ButtonSizeConfig(
          height: 48,
          fontSize: 16,
          iconSize: 20,
          spacing: 8,
          padding: EdgeInsets.symmetric(horizontal: 16),
        );
      case ButtonSize.large:
        return const _ButtonSizeConfig(
          height: 56,
          fontSize: 18,
          iconSize: 24,
          spacing: 10,
          padding: EdgeInsets.symmetric(horizontal: 20),
        );
      case ButtonSize.icon:
        return const _ButtonSizeConfig(
          height: 48,
          fontSize: 0,
          iconSize: 24,
          spacing: 0,
          padding: EdgeInsets.zero,
        );
    }
  }
}

/// 카카오 로그인 버튼
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
    this.borderRadius = 6,
    this.size = ButtonSize.medium,
    this.isLoading = false,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final config = _ButtonSizeConfig.fromSize(size);
    final isIconOnly = size == ButtonSize.icon;
    final effectiveHeight = height ?? config.height;
    final effectiveWidth = isIconOnly ? effectiveHeight : (width ?? double.infinity);

    return SizedBox(
      width: effectiveWidth,
      height: effectiveHeight,
      child: ElevatedButton(
        onPressed: (disabled || isLoading) ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFEE500),
          foregroundColor: const Color(0xFF000000),
          disabledBackgroundColor: const Color(0xFFFEE500).withValues(alpha: 0.6),
          disabledForegroundColor: const Color(0xFF000000).withValues(alpha: 0.6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          padding: config.padding,
          elevation: 0,
        ),
        child: _buildContent(config, isIconOnly),
      ),
    );
  }

  Widget _buildContent(_ButtonSizeConfig config, bool isIconOnly) {
    if (isLoading) {
      return SizedBox(
        width: config.iconSize,
        height: config.iconSize,
        child: const CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF000000)),
        ),
      );
    }

    if (isIconOnly) {
      return _KakaoIcon(size: config.iconSize);
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        _KakaoIcon(size: config.iconSize),
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

/// 네이버 로그인 버튼
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

  @override
  Widget build(BuildContext context) {
    final config = _ButtonSizeConfig.fromSize(size);
    final isIconOnly = size == ButtonSize.icon;
    final effectiveHeight = height ?? config.height;
    final effectiveWidth = isIconOnly ? effectiveHeight : (width ?? double.infinity);

    return SizedBox(
      width: effectiveWidth,
      height: effectiveHeight,
      child: ElevatedButton(
        onPressed: (disabled || isLoading) ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF03C75A),
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFF03C75A).withValues(alpha: 0.6),
          disabledForegroundColor: Colors.white.withValues(alpha: 0.6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          padding: config.padding,
          elevation: 0,
        ),
        child: _buildContent(config, isIconOnly),
      ),
    );
  }

  Widget _buildContent(_ButtonSizeConfig config, bool isIconOnly) {
    if (isLoading) {
      return SizedBox(
        width: config.iconSize,
        height: config.iconSize,
        child: const CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }

    if (isIconOnly) {
      return _NaverIcon(size: config.iconSize);
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        _NaverIcon(size: config.iconSize),
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

/// 구글 로그인 버튼
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
    final config = _ButtonSizeConfig.fromSize(size);
    final isIconOnly = size == ButtonSize.icon;
    final effectiveHeight = height ?? config.height;
    final effectiveWidth = isIconOnly ? effectiveHeight : (width ?? double.infinity);

    return SizedBox(
      width: effectiveWidth,
      height: effectiveHeight,
      child: OutlinedButton(
        onPressed: (disabled || isLoading) ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF1F1F1F),
          disabledBackgroundColor: Colors.white.withValues(alpha: 0.6),
          disabledForegroundColor: const Color(0xFF1F1F1F).withValues(alpha: 0.6),
          side: BorderSide(
            color: disabled ? const Color(0xFFDADCE0).withValues(alpha: 0.6) : const Color(0xFFDADCE0),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          padding: config.padding,
          elevation: 0,
        ),
        child: _buildContent(config, isIconOnly),
      ),
    );
  }

  Widget _buildContent(_ButtonSizeConfig config, bool isIconOnly) {
    if (isLoading) {
      return SizedBox(
        width: config.iconSize,
        height: config.iconSize,
        child: const CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1F1F1F)),
        ),
      );
    }

    if (isIconOnly) {
      return _GoogleIcon(size: config.iconSize);
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        _GoogleIcon(size: config.iconSize),
        SizedBox(width: config.spacing),
        Text(
          text,
          style: TextStyle(
            fontSize: config.fontSize,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// 애플 로그인 버튼
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

  @override
  Widget build(BuildContext context) {
    final config = _ButtonSizeConfig.fromSize(size);
    final isIconOnly = size == ButtonSize.icon;
    final effectiveHeight = height ?? config.height;
    final effectiveWidth = isIconOnly ? effectiveHeight : (width ?? double.infinity);

    final bgColor = isDark ? Colors.black : Colors.white;
    final fgColor = isDark ? Colors.white : Colors.black;

    return SizedBox(
      width: effectiveWidth,
      height: effectiveHeight,
      child: ElevatedButton(
        onPressed: (disabled || isLoading) ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: fgColor,
          disabledBackgroundColor: bgColor.withValues(alpha: 0.6),
          disabledForegroundColor: fgColor.withValues(alpha: 0.6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            side: isDark ? BorderSide.none : const BorderSide(color: Colors.black),
          ),
          padding: config.padding,
          elevation: 0,
        ),
        child: _buildContent(config, isIconOnly, fgColor),
      ),
    );
  }

  Widget _buildContent(_ButtonSizeConfig config, bool isIconOnly, Color fgColor) {
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

    if (isIconOnly) {
      return _AppleIcon(isDark: isDark, size: config.iconSize);
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        _AppleIcon(isDark: isDark, size: config.iconSize),
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

/// 로그인 버튼 그룹 방향
enum ButtonGroupDirection {
  /// 세로 배치
  vertical,

  /// 가로 배치
  horizontal,
}

/// 로그인 버튼 그룹
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
    final buttons = providers.map((provider) {
      final isLoading = loadingStates[provider] ?? false;
      final isDisabled = disabledStates[provider] ?? false;

      switch (provider) {
        case AuthProvider.kakao:
          return KakaoLoginButton(
            onPressed: () => onPressed?.call(provider),
            size: buttonSize,
            isLoading: isLoading,
            disabled: isDisabled,
          );
        case AuthProvider.naver:
          return NaverLoginButton(
            onPressed: () => onPressed?.call(provider),
            size: buttonSize,
            isLoading: isLoading,
            disabled: isDisabled,
          );
        case AuthProvider.google:
          return GoogleLoginButton(
            onPressed: () => onPressed?.call(provider),
            size: buttonSize,
            isLoading: isLoading,
            disabled: isDisabled,
          );
        case AuthProvider.apple:
          return AppleLoginButton(
            onPressed: () => onPressed?.call(provider),
            size: buttonSize,
            isLoading: isLoading,
            disabled: isDisabled,
          );
      }
    }).toList();

    if (direction == ButtonGroupDirection.horizontal) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: buttons.map((button) {
          final index = buttons.indexOf(button);
          if (index < buttons.length - 1) {
            return Padding(
              padding: EdgeInsets.only(right: spacing),
              child: button,
            );
          }
          return button;
        }).toList(),
      );
    }

    return Column(
      children: buttons.map((button) {
        final index = buttons.indexOf(button);
        if (index < buttons.length - 1) {
          return Padding(
            padding: EdgeInsets.only(bottom: spacing),
            child: button,
          );
        }
        return button;
      }).toList(),
    );
  }
}

// ============================================
// 아이콘 위젯들
// ============================================

class _KakaoIcon extends StatelessWidget {
  final double size;

  const _KakaoIcon({this.size = 20});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: SvgPicture.asset(
        'lib/assets/icons/kakao.svg',
        package: 'k_auth',
        width: size,
        height: size,
      ),
    );
  }
}

class _NaverIcon extends StatelessWidget {
  final double size;

  const _NaverIcon({this.size = 20});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: SvgPicture.asset(
        'lib/assets/icons/naver.svg',
        package: 'k_auth',
        width: size,
        height: size,
      ),
    );
  }
}

class _GoogleIcon extends StatelessWidget {
  final double size;

  const _GoogleIcon({this.size = 20});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: SvgPicture.asset(
        'lib/assets/icons/google.svg',
        package: 'k_auth',
        width: size,
        height: size,
      ),
    );
  }
}

class _AppleIcon extends StatelessWidget {
  final bool isDark;
  final double size;

  const _AppleIcon({required this.isDark, this.size = 22});

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.apple,
      size: size,
      color: isDark ? Colors.white : Colors.black,
    );
  }
}
