import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

// ============================================
// SVG 데이터
// ============================================

const String kakaoSvgData = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
  <path fill="#000000" d="M12 3C6.477 3 2 6.477 2 10.5c0 2.47 1.607 4.647 4.041 5.927l-.857 3.142a.5.5 0 0 0 .785.537l3.617-2.407c.795.132 1.6.201 2.414.201 5.523 0 10-3.477 10-7.5S17.523 3 12 3z"/>
</svg>
''';

const String naverSvgData = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
  <path fill="#FFFFFF" d="M14.39 12.37L9.38 5H5v14h4.61v-7.37L14.62 19H19V5h-4.61z"/>
</svg>
''';

/// 구글 공식 브랜드 색상:
/// - 파랑: #4285F4
/// - 초록: #34A853
/// - 노랑: #FBBC05
/// - 빨강: #EA4335
const String googleSvgData = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
  <path fill="#4285F4" d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"/>
  <path fill="#34A853" d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"/>
  <path fill="#FBBC05" d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z"/>
  <path fill="#EA4335" d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z"/>
</svg>
''';

String appleSvgData(bool isDark) => '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
  <path fill="${isDark ? '#FFFFFF' : '#000000'}" d="M17.05 20.28c-.98.95-2.05.88-3.08.4-1.09-.5-2.08-.48-3.24 0-1.44.62-2.2.44-3.06-.4C2.79 15.25 3.51 7.59 9.05 7.31c1.35.07 2.29.74 3.08.8 1.18-.24 2.31-.93 3.57-.84 1.51.12 2.65.72 3.4 1.8-3.12 1.87-2.38 5.98.48 7.13-.57 1.5-1.31 2.99-2.53 4.08l-.3-.3v.3zM12.03 7.25c-.15-2.23 1.66-4.07 3.74-4.25.29 2.58-2.34 4.5-3.74 4.25z"/>
</svg>
''';

// ============================================
// 아이콘 위젯
// ============================================

/// 카카오 말풍선 아이콘
class KakaoIcon extends StatelessWidget {
  final double size;
  const KakaoIcon({super.key, this.size = 20});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: SvgPicture.string(kakaoSvgData, fit: BoxFit.contain),
    );
  }
}

/// 네이버 N 아이콘
class NaverIcon extends StatelessWidget {
  final double size;
  const NaverIcon({super.key, this.size = 20});

  @override
  Widget build(BuildContext context) {
    final s = size * 1.1;
    return SizedBox(
      width: size,
      height: size,
      child: SvgPicture.string(naverSvgData,
          width: s, height: s, fit: BoxFit.contain),
    );
  }
}

/// 구글 G 아이콘 (4색 공식 로고)
class GoogleIcon extends StatelessWidget {
  final double size;
  const GoogleIcon({super.key, this.size = 20});

  @override
  Widget build(BuildContext context) {
    final s = size * 0.95;
    return SizedBox(
      width: size,
      height: size,
      child: SvgPicture.string(googleSvgData,
          width: s, height: s, fit: BoxFit.contain),
    );
  }
}

/// 애플 로고 아이콘
class AppleIcon extends StatelessWidget {
  final bool isDark;
  final double size;
  const AppleIcon({super.key, required this.isDark, this.size = 20});

  @override
  Widget build(BuildContext context) {
    final s = size * 1.05;
    return SizedBox(
      width: size,
      height: size,
      child: SvgPicture.string(appleSvgData(isDark),
          width: s, height: s, fit: BoxFit.contain),
    );
  }
}
