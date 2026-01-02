import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// OTP 입력 위젯
///
/// 각 자리를 개별 박스로 표시하는 인증번호 입력 위젯입니다.
///
/// ```dart
/// OtpInput(
///   length: 6,
///   onComplete: (code) => kAuth.phone.verify(code),
/// )
/// ```
///
/// ## 커스터마이징
///
/// ```dart
/// OtpInput(
///   length: 6,
///   onComplete: (code) => kAuth.phone.verify(code),
///   boxSize: 50,
///   spacing: 12,
///   borderRadius: 12,
///   borderColor: Colors.grey,
///   focusedBorderColor: Colors.blue,
///   filledBorderColor: Colors.green,
///   textStyle: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
/// )
/// ```
class OtpInput extends StatefulWidget {
  /// 인증번호 길이 (기본: 6)
  final int length;

  /// 입력 완료 콜백
  final void Function(String code) onComplete;

  /// 입력 변경 콜백 (선택)
  final void Function(String code)? onChange;

  /// 각 박스 크기 (기본: 48)
  final double boxSize;

  /// 박스 간격 (기본: 8)
  final double spacing;

  /// 박스 테두리 radius (기본: 8)
  final double borderRadius;

  /// 기본 테두리 색상
  final Color borderColor;

  /// 포커스된 테두리 색상
  final Color focusedBorderColor;

  /// 입력된 박스 테두리 색상
  final Color filledBorderColor;

  /// 에러 테두리 색상
  final Color errorBorderColor;

  /// 텍스트 스타일
  final TextStyle? textStyle;

  /// 자동 포커스 여부
  final bool autoFocus;

  /// 에러 상태
  final bool hasError;

  /// 숫자만 입력 가능 여부 (기본: true)
  final bool digitsOnly;

  const OtpInput({
    super.key,
    this.length = 6,
    required this.onComplete,
    this.onChange,
    this.boxSize = 48,
    this.spacing = 8,
    this.borderRadius = 8,
    this.borderColor = const Color(0xFFE0E0E0),
    this.focusedBorderColor = const Color(0xFF007AFF),
    this.filledBorderColor = const Color(0xFF007AFF),
    this.errorBorderColor = const Color(0xFFFF3B30),
    this.textStyle,
    this.autoFocus = true,
    this.hasError = false,
    this.digitsOnly = true,
  });

  @override
  State<OtpInput> createState() => _OtpInputState();
}

class _OtpInputState extends State<OtpInput> {
  late List<TextEditingController> _controllers;
  late List<FocusNode> _focusNodes;
  String _currentValue = '';

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      widget.length,
      (_) => TextEditingController(),
    );
    _focusNodes = List.generate(
      widget.length,
      (_) => FocusNode(),
    );

    if (widget.autoFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNodes[0].requestFocus();
      });
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _onChanged(int index, String value) {
    if (value.isNotEmpty) {
      // 여러 글자 붙여넣기 처리
      if (value.length > 1) {
        _handlePaste(value);
        return;
      }

      // 다음 칸으로 이동
      if (index < widget.length - 1) {
        _focusNodes[index + 1].requestFocus();
      }
    }

    _updateValue();
  }

  void _handlePaste(String value) {
    final chars = value.split('');
    for (var i = 0; i < widget.length && i < chars.length; i++) {
      _controllers[i].text = chars[i];
    }

    // 마지막 입력된 칸으로 포커스
    final lastIndex =
        chars.length >= widget.length ? widget.length - 1 : chars.length;
    _focusNodes[lastIndex].requestFocus();

    _updateValue();
  }

  void _onKeyDown(int index, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace) {
      if (_controllers[index].text.isEmpty && index > 0) {
        // 현재 칸이 비어있으면 이전 칸으로 이동
        _focusNodes[index - 1].requestFocus();
        _controllers[index - 1].clear();
      }
      _updateValue();
    }
  }

  void _updateValue() {
    final value = _controllers.map((c) => c.text).join();
    _currentValue = value;

    widget.onChange?.call(value);

    if (value.length == widget.length) {
      widget.onComplete(value);
    }
  }

  /// 현재 입력값
  String get value => _currentValue;

  /// 입력값 초기화
  void clear() {
    for (final controller in _controllers) {
      controller.clear();
    }
    _currentValue = '';
    _focusNodes[0].requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(widget.length, (index) {
        final hasValue = _controllers[index].text.isNotEmpty;
        final isFocused = _focusNodes[index].hasFocus;

        Color borderColor;
        if (widget.hasError) {
          borderColor = widget.errorBorderColor;
        } else if (hasValue) {
          borderColor = widget.filledBorderColor;
        } else if (isFocused) {
          borderColor = widget.focusedBorderColor;
        } else {
          borderColor = widget.borderColor;
        }

        return Container(
          margin: EdgeInsets.only(
            right: index < widget.length - 1 ? widget.spacing : 0,
          ),
          width: widget.boxSize,
          height: widget.boxSize,
          decoration: BoxDecoration(
            border: Border.all(color: borderColor, width: 2),
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
          child: KeyboardListener(
            focusNode: FocusNode(),
            onKeyEvent: (event) => _onKeyDown(index, event),
            child: TextField(
              controller: _controllers[index],
              focusNode: _focusNodes[index],
              textAlign: TextAlign.center,
              keyboardType:
                  widget.digitsOnly ? TextInputType.number : TextInputType.text,
              inputFormatters: widget.digitsOnly
                  ? [FilteringTextInputFormatter.digitsOnly]
                  : null,
              maxLength: 1,
              style: widget.textStyle ??
                  const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
              decoration: const InputDecoration(
                counterText: '',
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (value) => _onChanged(index, value),
            ),
          ),
        );
      }),
    );
  }
}

/// 간단한 OTP 입력 위젯 (한 줄 TextField)
///
/// 개별 박스 대신 하나의 TextField를 사용합니다.
///
/// ```dart
/// SimpleOtpInput(
///   length: 6,
///   onComplete: (code) => kAuth.phone.verify(code),
/// )
/// ```
class SimpleOtpInput extends StatefulWidget {
  /// 인증번호 길이
  final int length;

  /// 입력 완료 콜백
  final void Function(String code) onComplete;

  /// 입력 변경 콜백 (선택)
  final void Function(String code)? onChange;

  /// 자동 포커스
  final bool autoFocus;

  /// 힌트 텍스트
  final String? hintText;

  /// 입력 decoration
  final InputDecoration? decoration;

  /// 텍스트 스타일
  final TextStyle? textStyle;

  const SimpleOtpInput({
    super.key,
    this.length = 6,
    required this.onComplete,
    this.onChange,
    this.autoFocus = true,
    this.hintText,
    this.decoration,
    this.textStyle,
  });

  @override
  State<SimpleOtpInput> createState() => _SimpleOtpInputState();
}

class _SimpleOtpInputState extends State<SimpleOtpInput> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    if (widget.autoFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    widget.onChange?.call(value);

    if (value.length == widget.length) {
      widget.onComplete(value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      maxLength: widget.length,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: widget.textStyle ??
          const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            letterSpacing: 8,
          ),
      decoration: widget.decoration ??
          InputDecoration(
            counterText: '',
            hintText: widget.hintText ?? '● ' * widget.length,
            hintStyle: TextStyle(
              color: Colors.grey[400],
              letterSpacing: 8,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
      onChanged: _onChanged,
    );
  }
}
