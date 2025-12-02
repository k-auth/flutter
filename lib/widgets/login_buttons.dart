import 'package:flutter/material.dart';

import '../models/auth_result.dart';

/// 카카오 로그인 버튼
class KakaoLoginButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String text;
  final double? width;
  final double height;
  final double borderRadius;

  const KakaoLoginButton({
    super.key,
    this.onPressed,
    this.text = '카카오 로그인',
    this.width,
    this.height = 48,
    this.borderRadius = 6,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFEE500),
          foregroundColor: const Color(0xFF000000),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _KakaoIcon(),
            const SizedBox(width: 8),
            Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 네이버 로그인 버튼
class NaverLoginButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String text;
  final double? width;
  final double height;
  final double borderRadius;

  const NaverLoginButton({
    super.key,
    this.onPressed,
    this.text = '네이버 로그인',
    this.width,
    this.height = 48,
    this.borderRadius = 6,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF03C75A),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _NaverIcon(),
            const SizedBox(width: 8),
            Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 구글 로그인 버튼
class GoogleLoginButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String text;
  final double? width;
  final double height;
  final double borderRadius;

  const GoogleLoginButton({
    super.key,
    this.onPressed,
    this.text = 'Google로 로그인',
    this.width,
    this.height = 48,
    this.borderRadius = 6,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF1F1F1F),
          side: const BorderSide(color: Color(0xFFDADCE0)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _GoogleIcon(),
            const SizedBox(width: 8),
            Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 애플 로그인 버튼
class AppleLoginButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String text;
  final double? width;
  final double height;
  final double borderRadius;
  final bool isDark;

  const AppleLoginButton({
    super.key,
    this.onPressed,
    this.text = 'Apple로 로그인',
    this.width,
    this.height = 48,
    this.borderRadius = 6,
    this.isDark = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isDark ? Colors.black : Colors.white,
          foregroundColor: isDark ? Colors.white : Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            side: isDark
                ? BorderSide.none
                : const BorderSide(color: Colors.black),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _AppleIcon(isDark: isDark),
            const SizedBox(width: 8),
            Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 로그인 버튼 그룹
class LoginButtonGroup extends StatelessWidget {
  final List<AuthProvider> providers;
  final void Function(AuthProvider provider)? onPressed;
  final double spacing;

  const LoginButtonGroup({
    super.key,
    required this.providers,
    this.onPressed,
    this.spacing = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: providers.map((provider) {
        Widget button;
        switch (provider) {
          case AuthProvider.kakao:
            button = KakaoLoginButton(
              onPressed: () => onPressed?.call(provider),
            );
            break;
          case AuthProvider.naver:
            button = NaverLoginButton(
              onPressed: () => onPressed?.call(provider),
            );
            break;
          case AuthProvider.google:
            button = GoogleLoginButton(
              onPressed: () => onPressed?.call(provider),
            );
            break;
          case AuthProvider.apple:
            button = AppleLoginButton(
              onPressed: () => onPressed?.call(provider),
            );
            break;
        }

        final index = providers.indexOf(provider);
        if (index < providers.length - 1) {
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

// 아이콘 위젯들
class _KakaoIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
      child: CustomPaint(painter: _KakaoIconPainter()),
    );
  }
}

class _KakaoIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF000000)
      ..style = PaintingStyle.fill;

    final path = Path();
    // 카카오 말풍선 아이콘 간소화 버전
    path.addOval(Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2 - 1),
      width: size.width * 0.9,
      height: size.height * 0.7,
    ));
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _NaverIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Text(
      'N',
      style: TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class _GoogleIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
      child: CustomPaint(painter: _GoogleIconPainter()),
    );
  }
}

class _GoogleIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 간소화된 G 로고
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    // 빨강
    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(
      Rect.fromLTWH(0, 0, size.width, size.height),
      -0.5,
      1.2,
      false,
      paint,
    );

    // 노랑
    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(
      Rect.fromLTWH(0, 0, size.width, size.height),
      0.7,
      1.2,
      false,
      paint,
    );

    // 초록
    paint.color = const Color(0xFF34A853);
    canvas.drawArc(
      Rect.fromLTWH(0, 0, size.width, size.height),
      1.9,
      1.2,
      false,
      paint,
    );

    // 파랑
    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(
      Rect.fromLTWH(0, 0, size.width, size.height),
      3.1,
      1.2,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _AppleIcon extends StatelessWidget {
  final bool isDark;

  const _AppleIcon({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.apple,
      size: 22,
      color: isDark ? Colors.white : Colors.black,
    );
  }
}
