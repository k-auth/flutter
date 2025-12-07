import '../models/auth_result.dart';

/// 모든 소셜 로그인 Provider가 구현해야 하는 기본 인터페이스
abstract class BaseAuthProvider {
  /// Provider 초기화
  Future<void> initialize();

  /// 로그인 실행
  /// 성공 시 사용자 정보와 토큰을 포함한 AuthResult 반환
  Future<AuthResult> signIn();

  /// 로그아웃 실행
  /// 성공 시 AuthResult.success (user: null), 실패 시 AuthResult.failure 반환
  Future<AuthResult> signOut();

  /// 연결 해제 (탈퇴) 실행
  /// 성공 시 AuthResult.success (user: null), 실패 시 AuthResult.failure 반환
  Future<AuthResult> unlink();

  /// 토큰 갱신 실행
  /// 성공 시 갱신된 토큰 정보를 포함한 AuthResult 반환
  Future<AuthResult> refreshToken();
}
