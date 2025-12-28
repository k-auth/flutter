import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_auth/k_auth.dart';

void main() {
  // ============================================
  // ButtonSize 테스트
  // ============================================
  group('ButtonSize', () {
    test('모든 사이즈가 존재한다', () {
      expect(ButtonSize.values, contains(ButtonSize.small));
      expect(ButtonSize.values, contains(ButtonSize.medium));
      expect(ButtonSize.values, contains(ButtonSize.large));
      expect(ButtonSize.values, contains(ButtonSize.icon));
      expect(ButtonSize.values.length, 4);
    });
  });

  // ============================================
  // SizeConfig 테스트
  // ============================================
  group('SizeConfig', () {
    test('small 사이즈 설정', () {
      final config = SizeConfig.of(ButtonSize.small);

      expect(config.height, 36);
      expect(config.fontSize, 14);
      expect(config.iconSize, 16);
      expect(config.spacing, 6);
      expect(config.padding, const EdgeInsets.symmetric(horizontal: 12));
    });

    test('medium 사이즈 설정', () {
      final config = SizeConfig.of(ButtonSize.medium);

      expect(config.height, 48);
      expect(config.fontSize, 16);
      expect(config.iconSize, 20);
      expect(config.spacing, 8);
      expect(config.padding, const EdgeInsets.symmetric(horizontal: 16));
    });

    test('large 사이즈 설정', () {
      final config = SizeConfig.of(ButtonSize.large);

      expect(config.height, 56);
      expect(config.fontSize, 18);
      expect(config.iconSize, 24);
      expect(config.spacing, 10);
      expect(config.padding, const EdgeInsets.symmetric(horizontal: 20));
    });

    test('icon 사이즈 설정', () {
      final config = SizeConfig.of(ButtonSize.icon);

      expect(config.height, 48);
      expect(config.fontSize, 0);
      expect(config.iconSize, 24);
      expect(config.spacing, 0);
      expect(config.padding, EdgeInsets.zero);
    });
  });
}
