/// 토큰 만료 관련 유틸리티
///
/// 토큰 만료 시간 계산 로직을 중앙화합니다.
class TokenUtils {
  TokenUtils._();

  /// 토큰이 만료되었는지 확인
  static bool isExpired(DateTime? expiresAt) {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt);
  }

  /// 토큰이 곧 만료되는지 확인
  ///
  /// [threshold] 이내에 만료되면 true (기본 5분)
  static bool isExpiringSoon(
    DateTime? expiresAt, [
    Duration threshold = const Duration(minutes: 5),
  ]) {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt.subtract(threshold));
  }

  /// 만료까지 남은 시간
  ///
  /// 만료 시간이 없거나 이미 만료되었으면 [Duration.zero] 반환
  static Duration timeUntilExpiry(DateTime? expiresAt) {
    if (expiresAt == null) return Duration.zero;
    final remaining = expiresAt.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }
}
