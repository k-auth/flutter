import 'dart:async';
import '../phone_config.dart';
import '../phone_result.dart';
import 'phone_auth_provider.dart';

/// Firebase Phone Auth Provider
///
/// firebase_auth 패키지를 사용하여 전화번호 인증을 처리합니다.
///
/// ## 설정 방법
///
/// 1. Firebase 프로젝트 생성 및 앱 등록
/// 2. firebase_auth 패키지 추가
/// 3. FlutterFire CLI로 초기화
///
/// ```dart
/// // pubspec.yaml
/// dependencies:
///   firebase_core: ^2.24.0
///   firebase_auth: ^4.16.0
///
/// // main.dart
/// await Firebase.initializeApp();
/// ```
class FirebasePhoneProvider extends BasePhoneAuthProvider {
  // Firebase Auth 인스턴스는 런타임에 동적으로 로드
  dynamic _auth;
  String? _verificationId;
  int? _resendToken;
  Completer<PhoneResult>? _completer;

  FirebasePhoneProvider({required super.config});

  @override
  String get name => 'firebase';

  /// Firebase Auth 초기화 (lazy loading)
  Future<void> _ensureInitialized() async {
    if (_auth != null) return;

    try {
      // 동적 import로 firebase_auth 로드
      // 패키지가 없으면 에러 발생
      final firebaseAuth = await _loadFirebaseAuth();
      _auth = firebaseAuth;
    } catch (e) {
      throw StateError(
        'firebase_auth 패키지를 찾을 수 없습니다.\n'
        'pubspec.yaml에 firebase_auth를 추가하고 Firebase를 초기화하세요.\n'
        '자세한 내용: https://firebase.flutter.dev/docs/auth/phone',
      );
    }
  }

  /// firebase_auth 동적 로드
  Future<dynamic> _loadFirebaseAuth() async {
    // 런타임에 firebase_auth 패키지 확인
    // 이 방식은 패키지가 없어도 컴파일 에러가 나지 않음
    try {
      // ignore: depend_on_referenced_packages
      final auth = await Future.value(_getFirebaseAuthInstance());
      return auth;
    } catch (e) {
      rethrow;
    }
  }

  dynamic _getFirebaseAuthInstance() {
    // 실제 구현은 firebase_auth를 직접 import해야 함
    // 여기서는 플레이스홀더로 구현
    throw UnimplementedError(
      'Firebase Phone Auth를 사용하려면 firebase_auth 패키지를 추가하세요.',
    );
  }

  @override
  Future<PhoneResult> sendCode(String phoneNumber) async {
    try {
      await _ensureInitialized();

      _completer = Completer<PhoneResult>();

      // Firebase verifyPhoneNumber 호출
      // 실제 구현에서는 firebase_auth를 직접 사용
      await _verifyPhoneNumber(phoneNumber);

      return _completer!.future;
    } catch (e) {
      return PhoneResult.failure(
        code: 'FIREBASE_ERROR',
        message: _mapFirebaseError(e),
        hint: e.toString(),
      );
    }
  }

  Future<void> _verifyPhoneNumber(String phoneNumber) async {
    // Firebase Auth verifyPhoneNumber 호출
    // 이 메서드는 firebase_auth가 있을 때만 동작
    //
    // await _auth.verifyPhoneNumber(
    //   phoneNumber: phoneNumber,
    //   verificationCompleted: (credential) async {
    //     // 자동 인증 완료 (Android)
    //     final result = await _auth.signInWithCredential(credential);
    //     _completer?.complete(PhoneResult.success(
    //       user: PhoneUser(
    //         phoneNumber: phoneNumber,
    //         uid: result.user?.uid,
    //         verifiedAt: DateTime.now(),
    //         isNewUser: result.additionalUserInfo?.isNewUser ?? false,
    //       ),
    //     ));
    //   },
    //   verificationFailed: (e) {
    //     _completer?.complete(PhoneResult.failure(
    //       code: e.code,
    //       message: _mapFirebaseError(e),
    //     ));
    //   },
    //   codeSent: (verificationId, resendToken) {
    //     _verificationId = verificationId;
    //     _resendToken = resendToken;
    //     _completer?.complete(PhoneResult.success(
    //       verificationId: verificationId,
    //     ));
    //   },
    //   codeAutoRetrievalTimeout: (verificationId) {
    //     _verificationId = verificationId;
    //   },
    //   forceResendingToken: _resendToken,
    //   timeout: config.codeExpiry,
    // );

    // 임시 구현: 에러 반환
    _completer?.complete(PhoneResult.failure(
      code: 'NOT_IMPLEMENTED',
      message: 'Firebase Phone Auth가 아직 구현되지 않았습니다.',
      hint: 'firebase_auth 패키지를 추가하고 Firebase.initializeApp()을 호출하세요.',
    ));
  }

  @override
  Future<PhoneResult> verifyCode({
    required String phoneNumber,
    required String code,
    String? verificationId,
  }) async {
    try {
      await _ensureInitialized();

      final vid = verificationId ?? _verificationId;
      if (vid == null) {
        return PhoneResult.failure(
          code: 'NO_VERIFICATION_ID',
          message: '인증 세션이 만료되었습니다.',
          hint: '인증번호를 다시 발송해주세요.',
        );
      }

      // Firebase signInWithCredential 호출
      // final credential = PhoneAuthProvider.credential(
      //   verificationId: vid,
      //   smsCode: code,
      // );
      // final result = await _auth.signInWithCredential(credential);
      //
      // return PhoneResult.success(
      //   user: PhoneUser(
      //     phoneNumber: phoneNumber,
      //     uid: result.user?.uid,
      //     verifiedAt: DateTime.now(),
      //     isNewUser: result.additionalUserInfo?.isNewUser ?? false,
      //   ),
      // );

      // 임시 구현
      return PhoneResult.failure(
        code: 'NOT_IMPLEMENTED',
        message: 'Firebase Phone Auth가 아직 구현되지 않았습니다.',
      );
    } catch (e) {
      return PhoneResult.failure(
        code: 'VERIFY_FAILED',
        message: _mapFirebaseError(e),
        hint: e.toString(),
      );
    }
  }

  /// Firebase 에러 메시지 매핑
  String _mapFirebaseError(dynamic error) {
    final code = error.toString().toLowerCase();

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
    if (code.contains('network')) {
      return '네트워크 연결을 확인해주세요.';
    }

    return '인증에 실패했습니다.';
  }
}
