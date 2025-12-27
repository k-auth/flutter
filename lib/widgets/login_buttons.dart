import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../models/auth_result.dart';
import '../models/k_auth_user.dart';

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
class _SizeConfig {
  final double height;
  final double fontSize;
  final double iconSize;
  final double spacing;
  final EdgeInsets padding;

  const _SizeConfig({
    required this.height,
    required this.fontSize,
    required this.iconSize,
    required this.spacing,
    required this.padding,
  });

  static _SizeConfig of(ButtonSize size) {
    return switch (size) {
      ButtonSize.small => const _SizeConfig(
          height: 36,
          fontSize: 14,
          iconSize: 16,
          spacing: 6,
          padding: EdgeInsets.symmetric(horizontal: 12),
        ),
      ButtonSize.medium => const _SizeConfig(
          height: 48,
          fontSize: 16,
          iconSize: 20,
          spacing: 8,
          padding: EdgeInsets.symmetric(horizontal: 16),
        ),
      ButtonSize.large => const _SizeConfig(
          height: 56,
          fontSize: 18,
          iconSize: 24,
          spacing: 10,
          padding: EdgeInsets.symmetric(horizontal: 20),
        ),
      ButtonSize.icon => const _SizeConfig(
          height: 48,
          fontSize: 0,
          iconSize: 24,
          spacing: 0,
          padding: EdgeInsets.zero,
        ),
    };
  }
}

// ============================================
// 베이스 버튼 (내부용)
// ============================================

class _SocialButton extends StatelessWidget {
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

  const _SocialButton({
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
    final config = _SizeConfig.of(size);
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

  Widget _buildContent(_SizeConfig config, bool isIconOnly) {
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

// ============================================
// 공개 버튼 클래스들
// ============================================

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
    return _SocialButton(
      onPressed: onPressed,
      text: text,
      width: width,
      height: height,
      borderRadius: borderRadius,
      size: size,
      isLoading: isLoading,
      disabled: disabled,
      bgColor: const Color(0xFFFEE500),
      fgColor: const Color(0xFF000000),
      icon: _KakaoIcon(size: _SizeConfig.of(size).iconSize),
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
    return _SocialButton(
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
      icon: _NaverIcon(size: _SizeConfig.of(size).iconSize),
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
    return _SocialButton(
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
      borderColor: const Color(0xFFDADCE0),
      outlined: true,
      icon: _GoogleIcon(size: _SizeConfig.of(size).iconSize),
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
    final bgColor = isDark ? Colors.black : Colors.white;
    final fgColor = isDark ? Colors.white : Colors.black;

    return _SocialButton(
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
      icon: _AppleIcon(isDark: isDark, size: _SizeConfig.of(size).iconSize),
    );
  }
}

// ============================================
// 버튼 그룹
// ============================================

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
    final callback = () => onPressed?.call(provider);

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

// ============================================
// SVG 아이콘
// ============================================

const String _kakaoSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
  <path fill="#000000" d="M12 3C6.477 3 2 6.477 2 10.5c0 2.47 1.607 4.647 4.041 5.927l-.857 3.142a.5.5 0 0 0 .785.537l3.617-2.407c.795.132 1.6.201 2.414.201 5.523 0 10-3.477 10-7.5S17.523 3 12 3z"/>
</svg>
''';

const String _naverSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
  <path fill="#FFFFFF" d="M14.39 12.37L9.38 5H5v14h4.61v-7.37L14.62 19H19V5h-4.61z"/>
</svg>
''';

const String _googleSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
  <path fill="#4285F4" d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"/>
  <path fill="#34A853" d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"/>
  <path fill="#FBBC05" d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z"/>
  <path fill="#EA4335" d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z"/>
</svg>
''';

class _KakaoIcon extends StatelessWidget {
  final double size;
  const _KakaoIcon({this.size = 20});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: SvgPicture.string(_kakaoSvg, fit: BoxFit.contain),
    );
  }
}

class _NaverIcon extends StatelessWidget {
  final double size;
  const _NaverIcon({this.size = 20});

  @override
  Widget build(BuildContext context) {
    final s = size * 1.1;
    return SizedBox(
      width: size,
      height: size,
      child: SvgPicture.string(_naverSvg, width: s, height: s, fit: BoxFit.contain),
    );
  }
}

class _GoogleIcon extends StatelessWidget {
  final double size;
  const _GoogleIcon({this.size = 20});

  @override
  Widget build(BuildContext context) {
    final s = size * 0.95;
    return SizedBox(
      width: size,
      height: size,
      child: SvgPicture.string(_googleSvg, width: s, height: s, fit: BoxFit.contain),
    );
  }
}

class _AppleIcon extends StatelessWidget {
  final bool isDark;
  final double size;
  const _AppleIcon({required this.isDark, this.size = 20});

  @override
  Widget build(BuildContext context) {
    final color = isDark ? '#FFFFFF' : '#000000';
    final svg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
  <path fill="$color" d="M17.05 20.28c-.98.95-2.05.88-3.08.4-1.09-.5-2.08-.48-3.24 0-1.44.62-2.2.44-3.06-.4C2.79 15.25 3.51 7.59 9.05 7.31c1.35.07 2.29.74 3.08.8 1.18-.24 2.31-.93 3.57-.84 1.51.12 2.65.72 3.4 1.8-3.12 1.87-2.38 5.98.48 7.13-.57 1.5-1.31 2.99-2.53 4.08l-.3-.3v.3zM12.03 7.25c-.15-2.23 1.66-4.07 3.74-4.25.29 2.58-2.34 4.5-3.74 4.25z"/>
</svg>
''';
    final s = size * 1.05;
    return SizedBox(
      width: size,
      height: size,
      child: SvgPicture.string(svg, width: s, height: s, fit: BoxFit.contain),
    );
  }
}

// ============================================
// KAuthBuilder 위젯
// ============================================

/// 인증 상태에 따라 화면을 자동으로 전환하는 위젯
///
/// ```dart
/// KAuthBuilder(
///   stream: kAuth.authStateChanges,
///   signedIn: (user) => HomeScreen(user: user),
///   signedOut: () => LoginScreen(),
///   loading: () => SplashScreen(),
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

  /// 초기 사용자 (스트림 연결 전)
  final KAuthUser? initialUser;

  const KAuthBuilder({
    super.key,
    required this.stream,
    required this.signedIn,
    required this.signedOut,
    this.loading,
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

        final user = snapshot.data;
        if (user != null) return signedIn(user);
        return signedOut();
      },
    );
  }
}
