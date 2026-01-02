import 'package:flutter/widgets.dart';
import '../phone_state.dart';
import '../k_auth_phone.dart';

/// 전화번호 인증 상태에 따른 화면 전환 위젯
///
/// [KAuthBuilder]와 유사하게 상태에 따라 다른 위젯을 표시합니다.
///
/// ```dart
/// PhoneAuthBuilder(
///   phone: kAuth.phone,
///   idle: () => PhoneInputScreen(),
///   codeSent: () => OtpInputScreen(),
///   verified: (number) => Text('$number 인증 완료!'),
/// )
/// ```
///
/// ## 로딩 상태 처리
///
/// ```dart
/// PhoneAuthBuilder(
///   phone: kAuth.phone,
///   idle: () => PhoneInputScreen(),
///   sending: () => Center(child: CircularProgressIndicator()),
///   codeSent: () => OtpInputScreen(),
///   verifying: () => Center(child: CircularProgressIndicator()),
///   verified: (number) => SuccessScreen(number),
///   error: (state) => ErrorScreen(),
/// )
/// ```
class PhoneAuthBuilder extends StatelessWidget {
  /// KAuthPhone 인스턴스
  final KAuthPhone phone;

  /// 초기 상태 (전화번호 입력 화면)
  final Widget Function() idle;

  /// 인증번호 발송 중 (선택)
  final Widget Function()? sending;

  /// 인증번호 발송 완료 (OTP 입력 화면)
  final Widget Function() codeSent;

  /// 인증번호 확인 중 (선택)
  final Widget Function()? verifying;

  /// 인증 완료
  final Widget Function(String phoneNumber) verified;

  /// 에러 발생 (선택)
  final Widget Function(PhoneState state)? error;

  const PhoneAuthBuilder({
    super.key,
    required this.phone,
    required this.idle,
    this.sending,
    required this.codeSent,
    this.verifying,
    required this.verified,
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<PhoneState>(
      stream: phone.stateChanges,
      initialData: phone.state,
      builder: (context, snapshot) {
        final state = snapshot.data ?? PhoneState.idle;

        return switch (state) {
          PhoneState.idle => idle(),
          PhoneState.sending => sending?.call() ?? idle(),
          PhoneState.codeSent => codeSent(),
          PhoneState.verifying => verifying?.call() ?? codeSent(),
          PhoneState.verified => verified(phone.number ?? ''),
          PhoneState.error => error?.call(state) ?? idle(),
        };
      },
    );
  }
}

/// 간단한 전화번호 인증 위젯
///
/// 전화번호 입력과 OTP 입력을 한 위젯에서 처리합니다.
///
/// ```dart
/// PhoneAuthWidget(
///   phone: kAuth.phone,
///   onVerified: (number) => navigateToHome(),
/// )
/// ```
class PhoneAuthWidget extends StatefulWidget {
  /// KAuthPhone 인스턴스
  final KAuthPhone phone;

  /// 인증 완료 콜백
  final void Function(String phoneNumber) onVerified;

  /// 에러 콜백 (선택)
  final void Function(String message)? onError;

  /// 전화번호 입력 힌트
  final String phoneHint;

  /// OTP 입력 힌트
  final String otpHint;

  /// 발송 버튼 텍스트
  final String sendButtonText;

  /// 확인 버튼 텍스트
  final String verifyButtonText;

  /// 재발송 버튼 텍스트
  final String resendButtonText;

  const PhoneAuthWidget({
    super.key,
    required this.phone,
    required this.onVerified,
    this.onError,
    this.phoneHint = '휴대폰 번호',
    this.otpHint = '인증번호 6자리',
    this.sendButtonText = '인증번호 받기',
    this.verifyButtonText = '확인',
    this.resendButtonText = '재발송',
  });

  @override
  State<PhoneAuthWidget> createState() => _PhoneAuthWidgetState();
}

class _PhoneAuthWidgetState extends State<PhoneAuthWidget> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    if (_phoneController.text.isEmpty) return;

    setState(() => _isLoading = true);

    final result = await widget.phone.send(_phoneController.text);

    setState(() => _isLoading = false);

    result.onFailure((failure) {
      widget.onError?.call(failure.displayMessage);
    });
  }

  Future<void> _verifyCode() async {
    if (_otpController.text.isEmpty) return;

    setState(() => _isLoading = true);

    final result = await widget.phone.verify(_otpController.text);

    setState(() => _isLoading = false);

    result.fold(
      ok: (user) => widget.onVerified(user?.phoneNumber ?? ''),
      err: (failure) => widget.onError?.call(failure.displayMessage),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<PhoneState>(
      stream: widget.phone.stateChanges,
      initialData: widget.phone.state,
      builder: (context, snapshot) {
        final state = snapshot.data ?? PhoneState.idle;
        final isCodeSent =
            state == PhoneState.codeSent || state == PhoneState.verifying;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 전화번호 입력
            _buildPhoneInput(enabled: !isCodeSent),

            const SizedBox(height: 16),

            if (!isCodeSent)
              _buildSendButton()
            else ...[
              // OTP 입력
              _buildOtpInput(),
              const SizedBox(height: 16),
              _buildVerifyButton(),
              const SizedBox(height: 8),
              _buildResendButton(),
            ],
          ],
        );
      },
    );
  }

  Widget _buildPhoneInput({required bool enabled}) {
    // 기본 TextField 반환 (실제 사용 시 커스터마이징 가능)
    return SizedBox(
      height: 48,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE0E0E0)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: EditableText(
            controller: _phoneController,
            focusNode: FocusNode(),
            style: const TextStyle(fontSize: 16, color: Color(0xFF000000)),
            cursorColor: const Color(0xFF000000),
            backgroundCursorColor: const Color(0xFFE0E0E0),
            keyboardType: TextInputType.phone,
            readOnly: !enabled,
          ),
        ),
      ),
    );
  }

  Widget _buildOtpInput() {
    return SizedBox(
      height: 48,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE0E0E0)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: EditableText(
            controller: _otpController,
            focusNode: FocusNode(),
            style: const TextStyle(fontSize: 16, color: Color(0xFF000000)),
            cursorColor: const Color(0xFF000000),
            backgroundCursorColor: const Color(0xFFE0E0E0),
            keyboardType: TextInputType.number,
          ),
        ),
      ),
    );
  }

  Widget _buildSendButton() {
    return GestureDetector(
      onTap: _isLoading ? null : _sendCode,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: const Color(0xFF007AFF),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          _isLoading ? '발송 중...' : widget.sendButtonText,
          style: const TextStyle(
            color: Color(0xFFFFFFFF),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildVerifyButton() {
    return GestureDetector(
      onTap: _isLoading ? null : _verifyCode,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: const Color(0xFF007AFF),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          _isLoading ? '확인 중...' : widget.verifyButtonText,
          style: const TextStyle(
            color: Color(0xFFFFFFFF),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildResendButton() {
    return StreamBuilder<Duration>(
      stream: widget.phone.resendTimer,
      builder: (context, snapshot) {
        final remaining = snapshot.data ?? widget.phone.resendIn;
        final canResend = remaining == Duration.zero;

        return GestureDetector(
          onTap: canResend ? _sendCode : null,
          child: Text(
            canResend
                ? widget.resendButtonText
                : '${remaining.inSeconds}초 후 재발송',
            style: TextStyle(
              color:
                  canResend ? const Color(0xFF007AFF) : const Color(0xFF999999),
              fontSize: 14,
            ),
          ),
        );
      },
    );
  }
}
