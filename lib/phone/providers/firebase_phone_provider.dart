import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import '../phone_result.dart';
import 'phone_auth_provider.dart';

/// Firebase Phone Auth Provider
///
/// Firebase Phone Authentication을 사용하여 전화번호 인증을 처리합니다.
///
/// ## 사전 설정
///
/// 1. Firebase 프로젝트 생성 및 앱 등록
/// 2. Firebase Console에서 Phone Authentication 활성화
/// 3. `firebase_core` 초기화
///
/// ```dart
/// // main.dart
/// void main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///   await Firebase.initializeApp();
///
///   final kAuth = await KAuth.init(
///     phone: PhoneConfig.firebase(),
///   );
///
///   runApp(MyApp());
/// }
/// ```
///
/// ## Android 설정
///
/// `android/app/build.gradle`에서 SHA-1, SHA-256 인증서 등록 필요
///
/// ## iOS 설정
///
/// Xcode에서 Push Notifications capability 추가 필요
class FirebasePhoneProvider extends BasePhoneAuthProvider {
  final FirebaseAuth _auth;
  String? _verificationId;
  int? _resendToken;
  Completer<PhoneResult>? _completer;

  FirebasePhoneProvider({
    required super.config,
    FirebaseAuth? auth,
  }) : _auth = auth ?? FirebaseAuth.instance;

  @override
  String get name => 'firebase';

  @override
  Future<PhoneResult> sendCode(String phoneNumber) async {
    _completer = Completer<PhoneResult>();

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: _onVerificationCompleted,
        verificationFailed: _onVerificationFailed,
        codeSent: _onCodeSent,
        codeAutoRetrievalTimeout: _onCodeAutoRetrievalTimeout,
        forceResendingToken: _resendToken,
        timeout: config.codeExpiry,
      );

      return _completer!.future;
    } catch (e) {
      return PhoneResult.failure(
        code: 'FIREBASE_ERROR',
        message: _mapFirebaseError(e),
        hint: e.toString(),
      );
    }
  }

  /// 자동 인증 완료 (Android SMS 자동 읽기)
  void _onVerificationCompleted(PhoneAuthCredential credential) async {
    try {
      final result = await _auth.signInWithCredential(credential);
      final user = result.user;

      if (user != null) {
        _completer?.complete(PhoneResult.success(
          user: PhoneUser(
            phoneNumber: user.phoneNumber ?? '',
            uid: user.uid,
            verifiedAt: DateTime.now(),
            isNewUser: result.additionalUserInfo?.isNewUser ?? false,
          ),
        ));
      } else {
        _completer?.complete(PhoneResult.failure(
          code: 'AUTO_VERIFY_FAILED',
          message: '자동 인증에 실패했습니다.',
        ));
      }
    } catch (e) {
      _completer?.complete(PhoneResult.failure(
        code: 'AUTO_VERIFY_FAILED',
        message: _mapFirebaseError(e),
      ));
    }
  }

  /// 인증 실패
  void _onVerificationFailed(FirebaseAuthException e) {
    _completer?.complete(PhoneResult.failure(
      code: e.code,
      message: _mapFirebaseError(e),
      hint: e.message,
    ));
  }

  /// 코드 발송 완료
  void _onCodeSent(String verificationId, int? resendToken) {
    _verificationId = verificationId;
    _resendToken = resendToken;
    _completer?.complete(PhoneResult.success(
      verificationId: verificationId,
    ));
  }

  /// 자동 코드 읽기 타임아웃
  void _onCodeAutoRetrievalTimeout(String verificationId) {
    _verificationId = verificationId;
  }

  @override
  Future<PhoneResult> verifyCode({
    required String phoneNumber,
    required String code,
    String? verificationId,
  }) async {
    final vid = verificationId ?? _verificationId;
    if (vid == null) {
      return PhoneResult.failure(
        code: 'NO_VERIFICATION_ID',
        message: '인증 세션이 만료되었습니다.',
        hint: '인증번호를 다시 발송해주세요.',
      );
    }

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: vid,
        smsCode: code,
      );

      final result = await _auth.signInWithCredential(credential);
      final user = result.user;

      if (user != null) {
        return PhoneResult.success(
          user: PhoneUser(
            phoneNumber: user.phoneNumber ?? phoneNumber,
            uid: user.uid,
            verifiedAt: DateTime.now(),
            isNewUser: result.additionalUserInfo?.isNewUser ?? false,
          ),
        );
      }

      return PhoneResult.failure(
        code: 'VERIFY_FAILED',
        message: '인증에 실패했습니다.',
      );
    } on FirebaseAuthException catch (e) {
      return PhoneResult.failure(
        code: e.code,
        message: _mapFirebaseError(e),
        hint: e.message,
      );
    } catch (e) {
      return PhoneResult.failure(
        code: 'VERIFY_FAILED',
        message: _mapFirebaseError(e),
        hint: e.toString(),
      );
    }
  }

  /// Firebase 에러 메시지 매핑 (한글)
  String _mapFirebaseError(dynamic error) {
    String code = '';

    if (error is FirebaseAuthException) {
      code = error.code;
    } else {
      code = error.toString().toLowerCase();
    }

    // Firebase Phone Auth 에러 코드 매핑
    if (code.contains('invalid-phone-number')) {
      return '올바르지 않은 전화번호입니다.';
    }
    if (code.contains('invalid-verification-code')) {
      return '인증번호가 일치하지 않습니다.';
    }
    if (code.contains('session-expired')) {
      return '인증 세션이 만료되었습니다. 다시 시도해주세요.';
    }
    if (code.contains('too-many-requests')) {
      return '요청이 너무 많습니다. 잠시 후 다시 시도해주세요.';
    }
    if (code.contains('quota-exceeded')) {
      return '일일 인증 한도를 초과했습니다.';
    }
    if (code.contains('missing-phone-number')) {
      return '전화번호를 입력해주세요.';
    }
    if (code.contains('user-disabled')) {
      return '비활성화된 계정입니다.';
    }
    if (code.contains('operation-not-allowed')) {
      return '전화번호 인증이 비활성화되어 있습니다.';
    }
    if (code.contains('network')) {
      return '네트워크 연결을 확인해주세요.';
    }
    if (code.contains('app-not-authorized')) {
      return '앱이 Firebase에 등록되지 않았습니다.';
    }
    if (code.contains('captcha-check-failed')) {
      return 'reCAPTCHA 인증에 실패했습니다.';
    }
    if (code.contains('missing-client-identifier')) {
      return 'Firebase 설정을 확인해주세요.';
    }

    return '인증에 실패했습니다.';
  }
}
