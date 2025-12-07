/// K-Auth Button Gallery (Storybook 스타일)
///
/// 모든 버튼 위젯을 Storybook처럼 확인할 수 있습니다.
///
/// 실행 방법:
/// ```bash
/// flutter run -t widgetbook/main.dart -d chrome
/// ```

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:k_auth/k_auth.dart';

void main() {
  runApp(const ButtonGalleryApp());
}

// SVG 아이콘 정의
class BrandIcons {
  static const String kakao = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
  <path fill="#000000" d="M12 3C6.477 3 2 6.477 2 10.5c0 2.47 1.607 4.647 4.041 5.927l-.857 3.142a.5.5 0 0 0 .785.537l3.617-2.407c.795.132 1.6.201 2.414.201 5.523 0 10-3.477 10-7.5S17.523 3 12 3z"/>
</svg>
''';

  static const String naver = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
  <path fill="#FFFFFF" d="M14.39 12.37L9.38 5H5v14h4.61v-7.37L14.62 19H19V5h-4.61z"/>
</svg>
''';

  static const String google = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
  <path fill="#4285F4" d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"/>
  <path fill="#34A853" d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"/>
  <path fill="#FBBC05" d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z"/>
  <path fill="#EA4335" d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z"/>
</svg>
''';

  static const String apple = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
  <path fill="currentColor" d="M17.05 20.28c-.98.95-2.05.88-3.08.4-1.09-.5-2.08-.48-3.24 0-1.44.62-2.2.44-3.06-.4C2.79 15.25 3.51 7.59 9.05 7.31c1.35.07 2.29.74 3.08.8 1.18-.24 2.31-.93 3.57-.84 1.51.12 2.65.72 3.4 1.8-3.12 1.87-2.38 5.98.48 7.13-.57 1.5-1.31 2.99-2.53 4.08l-.3-.3v.3zM12.03 7.25c-.15-2.23 1.66-4.07 3.74-4.25.29 2.58-2.34 4.5-3.74 4.25z"/>
</svg>
''';
}

class ButtonGalleryApp extends StatelessWidget {
  const ButtonGalleryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'K-Auth Button Gallery',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const GalleryPage(),
    );
  }
}

class GalleryPage extends StatefulWidget {
  const GalleryPage({super.key});

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  bool _isDarkMode = false;
  String _selectedProvider = 'Kakao';
  ButtonSize _selectedSize = ButtonSize.large;
  bool _isLoading = false;
  bool _isDisabled = false;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: _isDarkMode ? ThemeData.dark() : ThemeData.light(),
      child: Scaffold(
        backgroundColor: _isDarkMode ? Colors.grey[900] : Colors.grey[50],
        body: Row(
          children: [
            // 왼쪽: 컴포넌트 목록
            Container(
              width: 250,
              decoration: BoxDecoration(
                color: _isDarkMode ? Colors.grey[850] : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(2, 0),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 헤더
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: _isDarkMode ? Colors.grey[700]! : Colors.grey[200]!,
                        ),
                      ),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'K-Auth Gallery',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Button Components',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 컴포넌트 리스트
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      children: [
                        _buildMenuItemWithSvg('Kakao', BrandIcons.kakao),
                        _buildMenuItemWithSvg('Naver', BrandIcons.naver),
                        _buildMenuItemWithSvg('Google', BrandIcons.google),
                        _buildMenuItemWithSvg('Apple', BrandIcons.apple),
                        const Divider(),
                        _buildMenuItem('Button Group', Icons.view_agenda),
                        _buildMenuItem('All Sizes', Icons.format_size),
                        _buildMenuItem('All States', Icons.toggle_on),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 중앙: 프리뷰
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.all(40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 타이틀
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$_selectedProvider Login Button',
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '공식 디자인 가이드라인을 따르는 로그인 버튼',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        // 다크모드 토글
                        IconButton(
                          icon: Icon(_isDarkMode ? Icons.light_mode : Icons.dark_mode),
                          onPressed: () {
                            setState(() => _isDarkMode = !_isDarkMode);
                          },
                          tooltip: '다크모드 전환',
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),

                    // 프리뷰 영역
                    Expanded(
                      child: Center(
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 400),
                          child: _buildPreview(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 오른쪽: 컨트롤 패널
            Container(
              width: 280,
              decoration: BoxDecoration(
                color: _isDarkMode ? Colors.grey[850] : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(-2, 0),
                  ),
                ],
              ),
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  const Text(
                    'Controls',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Size 선택
                  const Text('Size', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  SegmentedButton<ButtonSize>(
                    segments: const [
                      ButtonSegment(value: ButtonSize.small, label: Text('S')),
                      ButtonSegment(value: ButtonSize.medium, label: Text('M')),
                      ButtonSegment(value: ButtonSize.large, label: Text('L')),
                      ButtonSegment(value: ButtonSize.icon, label: Icon(Icons.apps)),
                    ],
                    selected: {_selectedSize},
                    onSelectionChanged: (Set<ButtonSize> newSelection) {
                      setState(() => _selectedSize = newSelection.first);
                    },
                  ),
                  const SizedBox(height: 20),

                  // Loading 스위치
                  SwitchListTile(
                    title: const Text('Loading', style: TextStyle(fontSize: 14)),
                    value: _isLoading,
                    onChanged: (value) {
                      setState(() => _isLoading = value);
                    },
                  ),

                  // Disabled 스위치
                  SwitchListTile(
                    title: const Text('Disabled', style: TextStyle(fontSize: 14)),
                    value: _isDisabled,
                    onChanged: (value) {
                      setState(() => _isDisabled = value);
                    },
                  ),

                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 20),

                  // 스펙 정보
                  const Text(
                    'Specifications',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  _buildSpec('Height', _getHeightText()),
                  _buildSpec('Font Size', _getFontSizeText()),
                  _buildSpec('Icon Size', _getIconSizeText()),
                  if (_selectedProvider == 'Kakao') ...[
                    const SizedBox(height: 12),
                    _buildSpec('Background', '#FEE500'),
                    _buildSpec('Text Color', '#000000'),
                  ] else if (_selectedProvider == 'Naver') ...[
                    const SizedBox(height: 12),
                    _buildSpec('Background', '#03C75A'),
                    _buildSpec('Text Color', '#FFFFFF'),
                  ] else if (_selectedProvider == 'Google') ...[
                    const SizedBox(height: 12),
                    _buildSpec('Background', '#FFFFFF'),
                    _buildSpec('Border', '#DADCE0'),
                  ] else if (_selectedProvider == 'Apple') ...[
                    const SizedBox(height: 12),
                    _buildSpec('Background', 'Dark: #000000, Light: #FFFFFF'),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(String title, IconData icon) {
    final isSelected = _selectedProvider == title ||
                       (title == 'Button Group' && _selectedProvider == 'Button Group') ||
                       (title == 'All Sizes' && _selectedProvider == 'All Sizes') ||
                       (title == 'All States' && _selectedProvider == 'All States');

    return ListTile(
      dense: true,
      leading: SizedBox(
        width: 20,
        height: 20,
        child: Icon(
          icon,
          size: 18,
          color: _isDarkMode ? Colors.grey[400] : Colors.grey[700],
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      onTap: () {
        setState(() {
          _selectedProvider = title;
          // 리셋
          _isLoading = false;
          _isDisabled = false;
        });
      },
    );
  }

  Widget _buildMenuItemWithSvg(String title, String svgString) {
    final isSelected = _selectedProvider == title;
    final textColor = _isDarkMode ? Colors.white : Colors.black;

    return ListTile(
      dense: true,
      leading: Container(
        width: 20,
        height: 20,
        decoration: title == 'Kakao'
            ? BoxDecoration(
                color: const Color(0xFFFEE500),
                borderRadius: BorderRadius.circular(4),
              )
            : title == 'Naver'
                ? BoxDecoration(
                    color: const Color(0xFF03C75A),
                    borderRadius: BorderRadius.circular(4),
                  )
                : null,
        child: Center(
          child: ColorFiltered(
            colorFilter: ColorFilter.mode(
              title == 'Apple' ? textColor : Colors.transparent,
              title == 'Apple' ? BlendMode.srcIn : BlendMode.dst,
            ),
            child: SvgPicture.string(
              svgString,
              width: title == 'Kakao' || title == 'Naver' ? 12 : 20,
              height: title == 'Kakao' || title == 'Naver' ? 12 : 20,
            ),
          ),
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      onTap: () {
        setState(() {
          _selectedProvider = title;
          // 리셋
          _isLoading = false;
          _isDisabled = false;
        });
      },
    );
  }

  Widget _buildPreview() {
    if (_selectedProvider == 'Button Group') {
      return LoginButtonGroup(
        providers: const [
          AuthProvider.kakao,
          AuthProvider.naver,
          AuthProvider.google,
          AuthProvider.apple,
        ],
        onPressed: (provider) {},
        buttonSize: _selectedSize == ButtonSize.icon ? ButtonSize.icon : ButtonSize.large,
        direction: _selectedSize == ButtonSize.icon
            ? ButtonGroupDirection.horizontal
            : ButtonGroupDirection.vertical,
      );
    }

    if (_selectedProvider == 'All Sizes') {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          KakaoLoginButton(onPressed: () {}, size: ButtonSize.small, text: 'Small'),
          const SizedBox(height: 12),
          KakaoLoginButton(onPressed: () {}, size: ButtonSize.medium, text: 'Medium'),
          const SizedBox(height: 12),
          KakaoLoginButton(onPressed: () {}, size: ButtonSize.large, text: 'Large'),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              KakaoLoginButton(onPressed: () {}, size: ButtonSize.icon),
              const SizedBox(width: 12),
              const Text('Icon Only'),
            ],
          ),
        ],
      );
    }

    if (_selectedProvider == 'All States') {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          KakaoLoginButton(onPressed: () {}, text: 'Normal'),
          const SizedBox(height: 12),
          KakaoLoginButton(onPressed: () {}, isLoading: true, text: 'Loading'),
          const SizedBox(height: 12),
          KakaoLoginButton(onPressed: () {}, disabled: true, text: 'Disabled'),
        ],
      );
    }

    switch (_selectedProvider) {
      case 'Kakao':
        return KakaoLoginButton(
          onPressed: () {},
          size: _selectedSize,
          isLoading: _isLoading,
          disabled: _isDisabled,
        );
      case 'Naver':
        return NaverLoginButton(
          onPressed: () {},
          size: _selectedSize,
          isLoading: _isLoading,
          disabled: _isDisabled,
        );
      case 'Google':
        return GoogleLoginButton(
          onPressed: () {},
          size: _selectedSize,
          isLoading: _isLoading,
          disabled: _isDisabled,
        );
      case 'Apple':
        return AppleLoginButton(
          onPressed: () {},
          size: _selectedSize,
          isLoading: _isLoading,
          disabled: _isDisabled,
          isDark: _isDarkMode,
        );
      default:
        return const Text('Select a component');
    }
  }

  Widget _buildSpec(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getHeightText() {
    switch (_selectedSize) {
      case ButtonSize.small:
        return '36px';
      case ButtonSize.medium:
        return '48px';
      case ButtonSize.large:
        return '56px';
      case ButtonSize.icon:
        return '48px';
    }
  }

  String _getFontSizeText() {
    switch (_selectedSize) {
      case ButtonSize.small:
        return '14px';
      case ButtonSize.medium:
        return '16px';
      case ButtonSize.large:
        return '18px';
      case ButtonSize.icon:
        return '-';
    }
  }

  String _getIconSizeText() {
    switch (_selectedSize) {
      case ButtonSize.small:
        return '16px';
      case ButtonSize.medium:
        return '20px';
      case ButtonSize.large:
        return '24px';
      case ButtonSize.icon:
        return '24px';
    }
  }
}
