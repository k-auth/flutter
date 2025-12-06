/// K-Auth Widgetbook (Storybook for Flutter)
///
/// 모든 버튼 위젯을 Storybook처럼 확인할 수 있습니다.
///
/// 실행 방법:
/// ```bash
/// flutter run -t widgetbook/main.dart -d chrome
/// ```

import 'package:flutter/material.dart';
import 'package:k_auth/k_auth.dart';
import 'package:widgetbook/widgetbook.dart';

void main() {
  runApp(const WidgetbookApp());
}

class WidgetbookApp extends StatelessWidget {
  const WidgetbookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Widgetbook(
      addons: [
        MaterialThemeAddon(
          themes: [
            WidgetbookTheme(name: 'Light', data: ThemeData.light()),
            WidgetbookTheme(name: 'Dark', data: ThemeData.dark()),
          ],
        ),
        DeviceFrameAddon(devices: [
          Devices.ios.iPhone13,
          Devices.ios.iPad,
          Devices.android.samsungGalaxyS20,
        ]),
      ],
      directories: [
        // 카카오 버튼
        WidgetbookComponent(
          name: 'Kakao Login Button',
          useCases: [
            WidgetbookUseCase(
              name: 'Default',
              builder: (context) => _ButtonWrapper(
                child: KakaoLoginButton(
                  onPressed: () {},
                  size: context.knobs.list(
                    label: 'Size',
                    options: [
                      ButtonSize.small,
                      ButtonSize.medium,
                      ButtonSize.large,
                      ButtonSize.icon,
                    ],
                    initialOption: ButtonSize.large,
                    labelBuilder: (size) => size.toString().split('.').last,
                  ),
                  isLoading: context.knobs.boolean(
                    label: 'Loading',
                    initialValue: false,
                  ),
                  disabled: context.knobs.boolean(
                    label: 'Disabled',
                    initialValue: false,
                  ),
                  text: context.knobs.string(
                    label: 'Text',
                    initialValue: '카카오 로그인',
                  ),
                ),
              ),
            ),
            WidgetbookUseCase(
              name: 'Loading State',
              builder: (context) => _ButtonWrapper(
                child: KakaoLoginButton(
                  onPressed: () {},
                  isLoading: true,
                ),
              ),
            ),
            WidgetbookUseCase(
              name: 'Disabled State',
              builder: (context) => _ButtonWrapper(
                child: KakaoLoginButton(
                  onPressed: () {},
                  disabled: true,
                ),
              ),
            ),
            WidgetbookUseCase(
              name: 'Icon Only',
              builder: (context) => _ButtonWrapper(
                child: KakaoLoginButton(
                  onPressed: () {},
                  size: ButtonSize.icon,
                ),
              ),
            ),
            WidgetbookUseCase(
              name: 'All Sizes',
              builder: (context) => _ButtonWrapper(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    KakaoLoginButton(
                      onPressed: () {},
                      size: ButtonSize.small,
                      text: 'Small',
                    ),
                    const SizedBox(height: 12),
                    KakaoLoginButton(
                      onPressed: () {},
                      size: ButtonSize.medium,
                      text: 'Medium',
                    ),
                    const SizedBox(height: 12),
                    KakaoLoginButton(
                      onPressed: () {},
                      size: ButtonSize.large,
                      text: 'Large',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        // 네이버 버튼
        WidgetbookComponent(
          name: 'Naver Login Button',
          useCases: [
            WidgetbookUseCase(
              name: 'Default',
              builder: (context) => _ButtonWrapper(
                child: NaverLoginButton(
                  onPressed: () {},
                  size: context.knobs.list(
                    label: 'Size',
                    options: [
                      ButtonSize.small,
                      ButtonSize.medium,
                      ButtonSize.large,
                      ButtonSize.icon,
                    ],
                    initialOption: ButtonSize.large,
                    labelBuilder: (size) => size.toString().split('.').last,
                  ),
                  isLoading: context.knobs.boolean(
                    label: 'Loading',
                    initialValue: false,
                  ),
                  disabled: context.knobs.boolean(
                    label: 'Disabled',
                    initialValue: false,
                  ),
                  text: context.knobs.string(
                    label: 'Text',
                    initialValue: '네이버 로그인',
                  ),
                ),
              ),
            ),
            WidgetbookUseCase(
              name: 'Loading State',
              builder: (context) => _ButtonWrapper(
                child: NaverLoginButton(
                  onPressed: () {},
                  isLoading: true,
                ),
              ),
            ),
            WidgetbookUseCase(
              name: 'Disabled State',
              builder: (context) => _ButtonWrapper(
                child: NaverLoginButton(
                  onPressed: () {},
                  disabled: true,
                ),
              ),
            ),
            WidgetbookUseCase(
              name: 'Icon Only',
              builder: (context) => _ButtonWrapper(
                child: NaverLoginButton(
                  onPressed: () {},
                  size: ButtonSize.icon,
                ),
              ),
            ),
          ],
        ),

        // 구글 버튼
        WidgetbookComponent(
          name: 'Google Login Button',
          useCases: [
            WidgetbookUseCase(
              name: 'Default',
              builder: (context) => _ButtonWrapper(
                child: GoogleLoginButton(
                  onPressed: () {},
                  size: context.knobs.list(
                    label: 'Size',
                    options: [
                      ButtonSize.small,
                      ButtonSize.medium,
                      ButtonSize.large,
                      ButtonSize.icon,
                    ],
                    initialOption: ButtonSize.large,
                    labelBuilder: (size) => size.toString().split('.').last,
                  ),
                  isLoading: context.knobs.boolean(
                    label: 'Loading',
                    initialValue: false,
                  ),
                  disabled: context.knobs.boolean(
                    label: 'Disabled',
                    initialValue: false,
                  ),
                  text: context.knobs.string(
                    label: 'Text',
                    initialValue: 'Google로 로그인',
                  ),
                ),
              ),
            ),
            WidgetbookUseCase(
              name: 'Loading State',
              builder: (context) => _ButtonWrapper(
                child: GoogleLoginButton(
                  onPressed: () {},
                  isLoading: true,
                ),
              ),
            ),
            WidgetbookUseCase(
              name: 'Disabled State',
              builder: (context) => _ButtonWrapper(
                child: GoogleLoginButton(
                  onPressed: () {},
                  disabled: true,
                ),
              ),
            ),
            WidgetbookUseCase(
              name: 'Icon Only',
              builder: (context) => _ButtonWrapper(
                child: GoogleLoginButton(
                  onPressed: () {},
                  size: ButtonSize.icon,
                ),
              ),
            ),
          ],
        ),

        // 애플 버튼
        WidgetbookComponent(
          name: 'Apple Login Button',
          useCases: [
            WidgetbookUseCase(
              name: 'Default',
              builder: (context) => _ButtonWrapper(
                child: AppleLoginButton(
                  onPressed: () {},
                  size: context.knobs.list(
                    label: 'Size',
                    options: [
                      ButtonSize.small,
                      ButtonSize.medium,
                      ButtonSize.large,
                      ButtonSize.icon,
                    ],
                    initialOption: ButtonSize.large,
                    labelBuilder: (size) => size.toString().split('.').last,
                  ),
                  isDark: context.knobs.boolean(
                    label: 'Dark Mode',
                    initialValue: true,
                  ),
                  isLoading: context.knobs.boolean(
                    label: 'Loading',
                    initialValue: false,
                  ),
                  disabled: context.knobs.boolean(
                    label: 'Disabled',
                    initialValue: false,
                  ),
                  text: context.knobs.string(
                    label: 'Text',
                    initialValue: 'Apple로 로그인',
                  ),
                ),
              ),
            ),
            WidgetbookUseCase(
              name: 'Dark Mode',
              builder: (context) => _ButtonWrapper(
                child: AppleLoginButton(
                  onPressed: () {},
                  isDark: true,
                ),
              ),
            ),
            WidgetbookUseCase(
              name: 'Light Mode',
              builder: (context) => _ButtonWrapper(
                child: AppleLoginButton(
                  onPressed: () {},
                  isDark: false,
                ),
              ),
            ),
            WidgetbookUseCase(
              name: 'Loading State',
              builder: (context) => _ButtonWrapper(
                child: AppleLoginButton(
                  onPressed: () {},
                  isLoading: true,
                ),
              ),
            ),
            WidgetbookUseCase(
              name: 'Icon Only (Dark)',
              builder: (context) => _ButtonWrapper(
                child: AppleLoginButton(
                  onPressed: () {},
                  size: ButtonSize.icon,
                  isDark: true,
                ),
              ),
            ),
            WidgetbookUseCase(
              name: 'Icon Only (Light)',
              builder: (context) => _ButtonWrapper(
                child: AppleLoginButton(
                  onPressed: () {},
                  size: ButtonSize.icon,
                  isDark: false,
                ),
              ),
            ),
          ],
        ),

        // 버튼 그룹
        WidgetbookComponent(
          name: 'Login Button Group',
          useCases: [
            WidgetbookUseCase(
              name: 'Vertical (Default)',
              builder: (context) => _ButtonWrapper(
                child: LoginButtonGroup(
                  providers: const [
                    AuthProvider.kakao,
                    AuthProvider.naver,
                    AuthProvider.google,
                    AuthProvider.apple,
                  ],
                  onPressed: (provider) {},
                  buttonSize: context.knobs.list(
                    label: 'Button Size',
                    options: [
                      ButtonSize.small,
                      ButtonSize.medium,
                      ButtonSize.large,
                    ],
                    initialOption: ButtonSize.large,
                    labelBuilder: (size) => size.toString().split('.').last,
                  ),
                  spacing: context.knobs.double.slider(
                    label: 'Spacing',
                    initialValue: 12,
                    min: 0,
                    max: 32,
                  ),
                ),
              ),
            ),
            WidgetbookUseCase(
              name: 'Horizontal',
              builder: (context) => _ButtonWrapper(
                child: LoginButtonGroup(
                  providers: const [
                    AuthProvider.kakao,
                    AuthProvider.naver,
                    AuthProvider.google,
                    AuthProvider.apple,
                  ],
                  onPressed: (provider) {},
                  direction: ButtonGroupDirection.horizontal,
                  buttonSize: ButtonSize.icon,
                  spacing: context.knobs.double.slider(
                    label: 'Spacing',
                    initialValue: 12,
                    min: 0,
                    max: 32,
                  ),
                ),
              ),
            ),
            WidgetbookUseCase(
              name: 'Partial Providers',
              builder: (context) => _ButtonWrapper(
                child: LoginButtonGroup(
                  providers: const [
                    AuthProvider.kakao,
                    AuthProvider.google,
                  ],
                  onPressed: (provider) {},
                  buttonSize: ButtonSize.large,
                ),
              ),
            ),
            WidgetbookUseCase(
              name: 'With Loading States',
              builder: (context) => _ButtonWrapper(
                child: LoginButtonGroup(
                  providers: const [
                    AuthProvider.kakao,
                    AuthProvider.naver,
                    AuthProvider.google,
                  ],
                  onPressed: (provider) {},
                  buttonSize: ButtonSize.medium,
                  loadingStates: const {
                    AuthProvider.kakao: true,
                  },
                  disabledStates: const {
                    AuthProvider.naver: true,
                    AuthProvider.google: true,
                  },
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// 버튼 래퍼 (센터 정렬 + 패딩)
class _ButtonWrapper extends StatelessWidget {
  final Widget child;

  const _ButtonWrapper({required this.child});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SizedBox(
          width: 400,
          child: child,
        ),
      ),
    );
  }
}
