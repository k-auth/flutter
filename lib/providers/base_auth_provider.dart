import '../models/auth_result.dart';

/// 모든 소셜 로그인 Provider가 구현해야 하는 기본 인터페이스
abstract class BaseAuthProvider {
  /// Provider 초기화
  Future<void> initialize();

  /// 로그인 실행
  Future<AuthResult> signIn();

  /// 로그아웃 실행
  Future<void> signOut();

  /// 연결 해제 (탈퇴) 실행
  Future<void> unlink();

  /// 토큰 갱신 실행
  Future<AuthResult> refreshToken();
}
