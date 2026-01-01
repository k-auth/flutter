import 'dart:async';
import 'phone_config.dart';
import 'phone_state.dart';
import 'phone_result.dart';
import 'providers/phone_auth_provider.dart';
import 'providers/firebase_phone_provider.dart';
import 'providers/custom_phone_provider.dart';

/// 전화번호 인증 클래스
///
/// KAuth에 통합되어 `kAuth.phone`으로 접근합니다.
///
/// ## 기본 사용법
///
/// ```dart
/// // 인증번호 발송
/// await kAuth.phone.send('01012345678');
///
/// // 인증번호 확인
/// final result = await kAuth.phone.verify('123456');
/// result.fold(
///   ok: (user) => navigateToHome(),
///   err: (e) => showError(e.message),
/// );
/// ```
///
/// ## 상태 확인
///
/// ```dart
/// kAuth.phone.isVerified   // 인증 완료 여부
/// kAuth.phone.number       // 인증된 번호
/// kAuth.phone.state        // 현재 상태
/// kAuth.phone.canResend    // 재발송 가능 여부
/// kAuth.phone.resendIn     // 재발송까지 남은 시간
/// ```
///
/// ## 상태 스트림
///
/// ```dart
/// StreamBuilder<PhoneState>(
///   stream: kAuth.phone.stateChanges,
///   builder: (context, snapshot) {
///     return switch (snapshot.data) {
///       PhoneState.idle => PhoneInputScreen(),
///       PhoneState.codeSent => OtpInputScreen(),
///       PhoneState.verified => SuccessScreen(),
///       _ => LoadingScreen(),
///     };
///   },
/// )
/// ```
class KAuthPhone {
  final PhoneConfig _config;
  late final BasePhoneAuthProvider _provider;

  PhoneState _state = PhoneState.idle;
  String? _phoneNumber;
  String? _verificationId;
  PhoneUser? _verifiedUser;
  DateTime? _codeSentAt;
  Timer? _resendTimer;

  final _stateController = StreamController<PhoneState>.broadcast();
  final _resendTimerController = StreamController<Duration>.broadcast();

  KAuthPhone(this._config) {
    _provider = _createProvider();
  }

  BasePhoneAuthProvider _createProvider() {
    switch (_config.provider) {
      case PhoneProvider.firebase:
        return FirebasePhoneProvider(config: _config);
      case PhoneProvider.custom:
        return CustomPhoneProvider(config: _config);
    }
  }

  // ============================================
  // 핵심 메서드
  // ============================================

  /// 인증번호 발송
  ///
  /// 어떤 형식이든 자동으로 정규화합니다:
  /// - `010-1234-5678` → `01012345678`
  /// - `+82 10-1234-5678` → `+821012345678`
  ///
  /// ```dart
  /// final result = await kAuth.phone.send('010-1234-5678');
  /// result.fold(
  ///   ok: (_) => showOtpInput(),
  ///   err: (e) => showError(e.message),
  /// );
  /// ```
  Future<PhoneResult> send(String phoneNumber) async {
    final normalized = _normalizePhoneNumber(phoneNumber);

    _setState(PhoneState.sending);
    _phoneNumber = normalized;

    try {
      final result = await _provider.sendCode(normalized);

      if (result.ok) {
        _verificationId = result.verificationId;
        _codeSentAt = DateTime.now();
        _startResendTimer();
        _setState(PhoneState.codeSent);
      } else {
        _setState(PhoneState.error);
      }

      return result;
    } catch (e) {
      _setState(PhoneState.error);
      return PhoneResult.failure(
        code: 'SEND_FAILED',
        message: '인증번호 발송에 실패했습니다.',
        hint: e.toString(),
      );
    }
  }

  /// 인증번호 확인
  ///
  /// ```dart
  /// final result = await kAuth.phone.verify('123456');
  /// result.fold(
  ///   ok: (user) => navigateToHome(),
  ///   err: (e) => showError(e.message),
  /// );
  /// ```
  Future<PhoneResult> verify(String code) async {
    if (_phoneNumber == null) {
      return PhoneResult.failure(
        code: 'NO_PHONE_NUMBER',
        message: '먼저 인증번호를 발송해주세요.',
      );
    }

    _setState(PhoneState.verifying);

    try {
      final result = await _provider.verifyCode(
        phoneNumber: _phoneNumber!,
        code: code,
        verificationId: _verificationId,
      );

      if (result.ok) {
        _verifiedUser = result.user;
        _stopResendTimer();
        _setState(PhoneState.verified);
      } else {
        // 잘못된 코드면 codeSent 상태로 복귀 (재입력 가능)
        _setState(result.failure.isInvalidCode
            ? PhoneState.codeSent
            : PhoneState.error);
      }

      return result;
    } catch (e) {
      _setState(PhoneState.error);
      return PhoneResult.failure(
        code: 'VERIFY_FAILED',
        message: '인증번호 확인에 실패했습니다.',
        hint: e.toString(),
      );
    }
  }

  /// 상태 초기화
  ///
  /// 새로운 전화번호로 인증하거나 재시도할 때 사용합니다.
  void reset() {
    _phoneNumber = null;
    _verificationId = null;
    _verifiedUser = null;
    _codeSentAt = null;
    _stopResendTimer();
    _setState(PhoneState.idle);
  }

  // ============================================
  // 상태 Getter
  // ============================================

  /// 현재 상태
  PhoneState get state => _state;

  /// 상태 변화 스트림
  Stream<PhoneState> get stateChanges => _stateController.stream;

  /// 인증 완료 여부
  bool get isVerified => _state == PhoneState.verified;

  /// 인증된 전화번호
  String? get number => isVerified ? _phoneNumber : null;

  /// 인증된 사용자 정보
  PhoneUser? get user => _verifiedUser;

  /// 입력된 전화번호 (인증 전)
  String? get pendingNumber => _phoneNumber;

  // ============================================
  // 재발송 타이머
  // ============================================

  /// 재발송 가능 여부
  bool get canResend {
    if (_codeSentAt == null) return true;
    return DateTime.now().difference(_codeSentAt!) >= _config.resendDelay;
  }

  /// 재발송까지 남은 시간
  Duration get resendIn {
    if (_codeSentAt == null) return Duration.zero;
    final elapsed = DateTime.now().difference(_codeSentAt!);
    final remaining = _config.resendDelay - elapsed;
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// 재발송 타이머 스트림
  ///
  /// ```dart
  /// StreamBuilder<Duration>(
  ///   stream: kAuth.phone.resendTimer,
  ///   builder: (context, snapshot) {
  ///     final remaining = snapshot.data ?? Duration.zero;
  ///     if (remaining == Duration.zero) {
  ///       return TextButton(onPressed: _resend, child: Text('재발송'));
  ///     }
  ///     return Text('${remaining.inSeconds}초 후 재발송');
  ///   },
  /// )
  /// ```
  Stream<Duration> get resendTimer => _resendTimerController.stream;

  void _startResendTimer() {
    _stopResendTimer();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final remaining = resendIn;
      _resendTimerController.add(remaining);
      if (remaining == Duration.zero) {
        _stopResendTimer();
      }
    });
    // 즉시 첫 값 emit
    _resendTimerController.add(resendIn);
  }

  void _stopResendTimer() {
    _resendTimer?.cancel();
    _resendTimer = null;
  }

  // ============================================
  // Private 메서드
  // ============================================

  void _setState(PhoneState newState) {
    _state = newState;
    _stateController.add(newState);
  }

  /// 전화번호 정규화
  ///
  /// - 공백, 하이픈 제거
  /// - 한국 번호면 +82 접두사 추가 (Firebase용)
  String _normalizePhoneNumber(String phone) {
    // 공백, 하이픈, 괄호 제거
    var normalized = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    // 이미 +로 시작하면 그대로
    if (normalized.startsWith('+')) {
      return normalized;
    }

    // 한국 번호 처리 (010, 011 등)
    if (normalized.startsWith('01')) {
      return '+82${normalized.substring(1)}';
    }

    return normalized;
  }

  /// 리소스 해제
  void dispose() {
    _stopResendTimer();
    _stateController.close();
    _resendTimerController.close();
  }
}
