import 'dart:async';
import '../models/auth_result.dart';
import '../models/k_auth_user.dart';
import '../models/k_auth_failure.dart';
import '../utils/token_utils.dart';

/// 테스트용 Mock KAuth
///
/// 실제 SDK 호출 없이 KAuth 동작을 시뮬레이션합니다.
/// Widget 테스트나 유닛 테스트에서 사용하세요.
///
/// ## 기본 사용법
///
/// ```dart
/// final mock = MockKAuth();
///
/// // 로그인 성공 설정
/// mock.mockUser = KAuthUser(
///   id: 'test_user_123',
///   provider: AuthProvider.kakao,
///   email: 'test@example.com',
/// );
///
/// final result = await mock.signIn(AuthProvider.kakao);
/// expect(result.success, true);
/// ```
///
/// ## 실패 시뮬레이션
///
/// ```dart
/// final mock = MockKAuth();
/// mock.setNetworkError();
///
/// final result = await mock.signIn(AuthProvider.kakao);
/// expect(result.failure, isA<NetworkError>());
/// ```
///
/// ## 토큰 만료 시뮬레이션
///
/// ```dart
/// final mock = MockKAuth.signedIn(user: testUser);
/// mock.expireAfter(Duration(seconds: 10));
///
/// // 10초 후 isExpired == true
/// ```
///
/// ## 호출 횟수 추적
///
/// ```dart
/// final mock = MockKAuth();
/// await mock.signIn(AuthProvider.kakao);
/// await mock.signIn(AuthProvider.kakao);
///
/// expect(mock.signInCount, 2);
/// expect(mock.signInCountFor(AuthProvider.kakao), 2);
/// ```
///
/// ## 연속 실패 후 성공
///
/// ```dart
/// final mock = MockKAuth();
/// mock.mockUser = testUser;
/// mock.failThenSucceed(times: 2);  // 2번 실패 후 성공
///
/// expect((await mock.signIn(AuthProvider.kakao)).success, false);
/// expect((await mock.signIn(AuthProvider.kakao)).success, false);
/// expect((await mock.signIn(AuthProvider.kakao)).success, true);
/// ```
class MockKAuth {
  /// Mock 사용자 (설정하면 signIn 성공)
  KAuthUser? mockUser;

  /// Mock 실패 (설정하면 signIn 실패)
  KAuthFailure? mockFailure;

  /// Mock 서버 토큰
  String? mockServerToken;

  /// 지연 시간 (네트워크 지연 시뮬레이션)
  Duration? delay;

  /// 설정된 Provider 목록
  List<AuthProvider> mockConfiguredProviders;

  /// 내부 상태
  KAuthUser? _currentUser;
  String? _serverToken;
  bool _initialized = false;
  DateTime? _expiresAt;
  final _authStateController = StreamController<KAuthUser?>.broadcast();

  // 호출 카운터
  int _signInCount = 0;
  int _signOutCount = 0;
  int _refreshCount = 0;
  int _unlinkCount = 0;
  final Map<AuthProvider, int> _signInCountByProvider = {};
  final Map<AuthProvider, int> _signOutCountByProvider = {};

  // 연속 실패 설정
  int _failuresRemaining = 0;
  KAuthFailure? _failureForRetry;

  /// MockKAuth 생성
  ///
  /// [mockUser]: 로그인 성공 시 반환할 사용자
  /// [mockFailure]: 로그인 실패 시 반환할 에러
  /// [delay]: 네트워크 지연 시뮬레이션
  /// [mockConfiguredProviders]: 설정된 Provider 목록
  MockKAuth({
    this.mockUser,
    this.mockFailure,
    this.mockServerToken,
    this.delay,
    this.mockConfiguredProviders = const [
      AuthProvider.kakao,
      AuthProvider.naver,
      AuthProvider.google,
      AuthProvider.apple,
    ],
  });

  /// 이미 로그인된 상태로 생성
  factory MockKAuth.signedIn({
    required KAuthUser user,
    String? serverToken,
    DateTime? expiresAt,
    List<AuthProvider> configuredProviders = const [
      AuthProvider.kakao,
      AuthProvider.naver,
      AuthProvider.google,
      AuthProvider.apple,
    ],
  }) {
    final mock = MockKAuth(
      mockUser: user,
      mockServerToken: serverToken,
      mockConfiguredProviders: configuredProviders,
    );
    mock._currentUser = user;
    mock._serverToken = serverToken;
    mock._expiresAt = expiresAt ?? DateTime.now().add(const Duration(hours: 1));
    mock._initialized = true;
    return mock;
  }

  /// 데모 모드로 생성
  ///
  /// API 키 없이 UI/UX를 테스트할 수 있습니다.
  /// 기본 데모 사용자로 시작하거나, 커스텀 사용자를 지정할 수 있습니다.
  ///
  /// ```dart
  /// // 기본 데모 사용자
  /// final kAuth = MockKAuth.demo();
  ///
  /// // 커스텀 데모 사용자
  /// final kAuth = MockKAuth.demo(
  ///   user: KAuthUser(id: 'demo', name: '데모 사용자'),
  /// );
  ///
  /// // 로그아웃 상태에서 시작
  /// final kAuth = MockKAuth.demo(signedIn: false);
  /// ```
  factory MockKAuth.demo({
    KAuthUser? user,
    bool signedIn = true,
    List<AuthProvider> configuredProviders = const [
      AuthProvider.kakao,
      AuthProvider.naver,
      AuthProvider.google,
      AuthProvider.apple,
    ],
  }) {
    final demoUser = user ??
        const KAuthUser(
          id: 'demo_user',
          provider: AuthProvider.kakao,
          email: 'demo@example.com',
          name: '데모 사용자',
          avatar: null,
        );

    final mock = MockKAuth(
      mockUser: demoUser,
      mockConfiguredProviders: configuredProviders,
    );

    if (signedIn) {
      mock._currentUser = demoUser;
      mock._expiresAt = DateTime.now().add(const Duration(hours: 24));
    }

    mock._initialized = true;
    return mock;
  }

  // ============================================
  // 호출 카운터
  // ============================================

  /// signIn 총 호출 횟수
  int get signInCount => _signInCount;

  /// signOut 총 호출 횟수
  int get signOutCount => _signOutCount;

  /// refreshToken 총 호출 횟수
  int get refreshCount => _refreshCount;

  /// unlink 총 호출 횟수
  int get unlinkCount => _unlinkCount;

  /// 특정 Provider의 signIn 호출 횟수
  int signInCountFor(AuthProvider provider) =>
      _signInCountByProvider[provider] ?? 0;

  /// 특정 Provider의 signOut 호출 횟수
  int signOutCountFor(AuthProvider provider) =>
      _signOutCountByProvider[provider] ?? 0;

  /// 모든 호출 카운터 초기화
  void resetCounters() {
    _signInCount = 0;
    _signOutCount = 0;
    _refreshCount = 0;
    _unlinkCount = 0;
    _signInCountByProvider.clear();
    _signOutCountByProvider.clear();
  }

  // ============================================
  // 토큰 만료 시뮬레이션
  // ============================================

  /// 토큰 만료 시간 설정
  ///
  /// 지정된 시간 후에 토큰이 만료됩니다.
  ///
  /// ```dart
  /// mock.expireAfter(Duration(seconds: 30));
  /// // 30초 후 mock.isExpired == true
  /// ```
  void expireAfter(Duration duration) {
    _expiresAt = DateTime.now().add(duration);
  }

  /// 토큰 즉시 만료
  void expireNow() {
    _expiresAt = DateTime.now().subtract(const Duration(seconds: 1));
  }

  /// 토큰 만료 시간
  DateTime? get expiresAt => _expiresAt;

  /// 토큰 남은 시간
  Duration get expiresIn => TokenUtils.timeUntilExpiry(_expiresAt);

  /// 토큰이 만료되었는지 확인
  bool get isExpired => TokenUtils.isExpired(_expiresAt);

  /// 토큰이 곧 만료되는지 확인 (기본 5분 전)
  bool isExpiringSoon([Duration threshold = const Duration(minutes: 5)]) =>
      TokenUtils.isExpiringSoon(_expiresAt, threshold);

  // ============================================
  // 연속 실패 시뮬레이션
  // ============================================

  /// N번 실패 후 성공하도록 설정
  ///
  /// ```dart
  /// mock.mockUser = testUser;
  /// mock.failThenSucceed(times: 2);
  ///
  /// // 처음 2번은 실패
  /// expect((await mock.signIn(AuthProvider.kakao)).success, false);
  /// expect((await mock.signIn(AuthProvider.kakao)).success, false);
  /// // 3번째는 성공
  /// expect((await mock.signIn(AuthProvider.kakao)).success, true);
  /// ```
  void failThenSucceed({
    int times = 1,
    KAuthFailure? failure,
  }) {
    _failuresRemaining = times;
    _failureForRetry = failure ??
        const NetworkError(
          code: 'NETWORK_ERROR',
          message: '네트워크 오류가 발생했습니다.',
          hint: '다시 시도해주세요.',
        );
  }

  // ============================================
  // Properties (KAuth 인터페이스)
  // ============================================

  /// 초기화 여부
  bool get isInitialized => _initialized;

  /// 현재 로그인된 사용자
  KAuthUser? get currentUser => _currentUser;

  /// 현재 사용자 ID
  String? get userId => _currentUser?.id;

  /// 현재 사용자 이름
  String? get name => _currentUser?.displayName;

  /// 현재 사용자 이메일
  String? get email => _currentUser?.email;

  /// 현재 사용자 프로필 이미지
  String? get avatar => _currentUser?.avatar;

  /// 로그인 여부
  bool get isSignedIn => _currentUser != null;

  /// 현재 로그인된 Provider
  AuthProvider? get currentProvider => _currentUser?.provider;

  /// 서버 토큰
  String? get serverToken => _serverToken;

  /// 인증 상태 변화 스트림
  Stream<KAuthUser?> get authStateChanges => _authStateController.stream;

  /// 설정된 Provider 목록
  List<AuthProvider> get configuredProviders => mockConfiguredProviders;

  // ============================================
  // Methods (KAuth 인터페이스)
  // ============================================

  /// 초기화
  Future<void> initialize({bool autoRestore = false}) async {
    if (delay != null) {
      await Future.delayed(delay!);
    }
    _initialized = true;
  }

  /// 소셜 로그인
  Future<AuthResult> signIn(AuthProvider provider) async {
    _signInCount++;
    _signInCountByProvider[provider] =
        (_signInCountByProvider[provider] ?? 0) + 1;

    if (delay != null) {
      await Future.delayed(delay!);
    }

    // 연속 실패 처리
    if (_failuresRemaining > 0) {
      _failuresRemaining--;
      return AuthResult.failure(
        provider: provider,
        errorMessage: _failureForRetry?.message ?? '실패',
        errorCode: _failureForRetry?.code,
        errorHint: _failureForRetry?.hint,
      );
    }

    // 실패 설정되어 있으면 실패 반환
    if (mockFailure != null) {
      return AuthResult.failure(
        provider: provider,
        errorMessage: mockFailure!.message ?? '로그인 실패',
        errorCode: mockFailure!.code,
        errorHint: mockFailure!.hint,
      );
    }

    // mockUser가 있으면 성공
    if (mockUser != null) {
      // provider 일치시키기
      final user = mockUser!.provider == provider
          ? mockUser!
          : KAuthUser(
              id: mockUser!.id,
              provider: provider,
              email: mockUser!.email,
              name: mockUser!.name,
              avatar: mockUser!.avatar,
              phone: mockUser!.phone,
              rawData: mockUser!.rawData,
            );

      _currentUser = user;
      _serverToken = mockServerToken;
      _expiresAt ??= DateTime.now().add(const Duration(hours: 1));
      _authStateController.add(user);

      return AuthResult.success(
        provider: provider,
        user: user,
        accessToken: 'mock_access_token',
        refreshToken: 'mock_refresh_token',
        expiresAt: _expiresAt,
      );
    }

    // 기본: 빈 사용자로 성공
    final user = KAuthUser(
      id: 'mock_user_${DateTime.now().millisecondsSinceEpoch}',
      provider: provider,
    );

    _currentUser = user;
    _serverToken = mockServerToken;
    _expiresAt ??= DateTime.now().add(const Duration(hours: 1));
    _authStateController.add(user);

    return AuthResult.success(
      provider: provider,
      user: user,
      accessToken: 'mock_access_token',
      expiresAt: _expiresAt,
    );
  }

  /// 카카오 로그인
  Future<AuthResult> signInWithKakao() => signIn(AuthProvider.kakao);

  /// 네이버 로그인
  Future<AuthResult> signInWithNaver() => signIn(AuthProvider.naver);

  /// 구글 로그인
  Future<AuthResult> signInWithGoogle() => signIn(AuthProvider.google);

  /// 애플 로그인
  Future<AuthResult> signInWithApple() => signIn(AuthProvider.apple);

  /// 로그아웃
  Future<AuthResult> signOut([AuthProvider? provider]) async {
    _signOutCount++;
    final targetProvider = provider ?? currentProvider ?? AuthProvider.kakao;
    _signOutCountByProvider[targetProvider] =
        (_signOutCountByProvider[targetProvider] ?? 0) + 1;

    if (delay != null) {
      await Future.delayed(delay!);
    }

    _currentUser = null;
    _serverToken = null;
    _expiresAt = null;
    _authStateController.add(null);

    return AuthResult.success(
      provider: targetProvider,
      user: null,
    );
  }

  /// 모든 Provider 로그아웃
  Future<List<AuthResult>> signOutAll() async {
    if (delay != null) {
      await Future.delayed(delay!);
    }

    _currentUser = null;
    _serverToken = null;
    _expiresAt = null;
    _authStateController.add(null);

    return configuredProviders
        .map((p) => AuthResult.success(provider: p, user: null))
        .toList();
  }

  /// 연결 해제
  Future<AuthResult> unlink(AuthProvider provider) async {
    _unlinkCount++;

    if (delay != null) {
      await Future.delayed(delay!);
    }

    if (!provider.supportsUnlink) {
      return AuthResult.failure(
        provider: provider,
        errorMessage: '${provider.displayName}은(는) 연결 해제를 지원하지 않습니다.',
        errorCode: 'PROVIDER_NOT_SUPPORTED',
      );
    }

    if (_currentUser?.provider == provider) {
      _currentUser = null;
      _serverToken = null;
      _expiresAt = null;
      _authStateController.add(null);
    }

    return AuthResult.success(
      provider: provider,
      user: null,
    );
  }

  /// 토큰 갱신
  Future<AuthResult> refreshToken([AuthProvider? provider]) async {
    _refreshCount++;

    if (delay != null) {
      await Future.delayed(delay!);
    }

    final targetProvider = provider ?? currentProvider;
    if (targetProvider == null) {
      return AuthResult.failure(
        provider: AuthProvider.kakao,
        errorMessage: '로그인된 상태가 아닙니다.',
        errorCode: 'REFRESH_FAILED',
      );
    }

    if (!targetProvider.supportsTokenRefresh) {
      return AuthResult.failure(
        provider: targetProvider,
        errorMessage: '${targetProvider.displayName}은(는) 토큰 갱신을 지원하지 않습니다.',
        errorCode: 'PROVIDER_NOT_SUPPORTED',
      );
    }

    if (_currentUser == null) {
      return AuthResult.failure(
        provider: targetProvider,
        errorMessage: '로그인된 상태가 아닙니다.',
        errorCode: 'REFRESH_FAILED',
      );
    }

    // 토큰 갱신 성공 - 만료 시간 연장
    _expiresAt = DateTime.now().add(const Duration(hours: 1));

    return AuthResult.success(
      provider: targetProvider,
      user: _currentUser,
      accessToken: 'mock_refreshed_access_token',
      refreshToken: 'mock_refreshed_refresh_token',
      expiresAt: _expiresAt,
    );
  }

  /// Provider가 설정되어 있는지 확인
  bool isConfigured(AuthProvider provider) {
    return configuredProviders.contains(provider);
  }

  /// 세션 삭제
  Future<void> clearSession() async {
    _currentUser = null;
    _serverToken = null;
    _expiresAt = null;
  }

  /// 리소스 해제
  void dispose() {
    _authStateController.close();
  }

  // ============================================
  // Mock 헬퍼 메서드
  // ============================================

  /// 상태 초기화
  void reset() {
    mockUser = null;
    mockFailure = null;
    mockServerToken = null;
    delay = null;
    _currentUser = null;
    _serverToken = null;
    _expiresAt = null;
    _initialized = false;
    _failuresRemaining = 0;
    _failureForRetry = null;
    resetCounters();
  }

  /// 로그인 성공으로 설정
  void setSignedIn(KAuthUser user, {String? serverToken, DateTime? expiresAt}) {
    mockUser = user;
    mockFailure = null;
    _currentUser = user;
    _serverToken = serverToken;
    _expiresAt = expiresAt ?? DateTime.now().add(const Duration(hours: 1));
    _initialized = true;
    _authStateController.add(user);
  }

  /// 로그아웃 상태로 설정
  void setSignedOut() {
    _currentUser = null;
    _serverToken = null;
    _expiresAt = null;
    _authStateController.add(null);
  }

  /// 실패로 설정
  void setFailure({
    String? code,
    String? message,
    String? hint,
  }) {
    mockFailure = KAuthFailure.create(
      code: code,
      message: message,
      hint: hint,
    );
    mockUser = null;
  }

  /// 취소로 설정
  void setCancelled() {
    mockFailure = const CancelledError(
      code: 'USER_CANCELLED',
      message: '사용자가 로그인을 취소했습니다.',
    );
    mockUser = null;
  }

  /// 네트워크 에러로 설정
  void setNetworkError() {
    mockFailure = const NetworkError(
      code: 'NETWORK_ERROR',
      message: '네트워크 오류가 발생했습니다.',
      hint: '인터넷 연결 상태를 확인해주세요.',
    );
    mockUser = null;
  }

  /// 타임아웃 에러로 설정
  void setTimeout() {
    mockFailure = const NetworkError(
      code: 'TIMEOUT',
      message: '요청 시간이 초과되었습니다.',
      hint: '다시 시도해주세요.',
    );
    mockUser = null;
  }

  /// 토큰 만료 에러로 설정
  void setTokenExpired() {
    mockFailure = const TokenError(
      code: 'TOKEN_EXPIRED',
      message: '인증 정보가 만료되었습니다.',
      hint: '다시 로그인해주세요.',
    );
    mockUser = null;
  }

  /// 설정 에러로 설정
  void setConfigError({String? message}) {
    mockFailure = ConfigError(
      code: 'PROVIDER_NOT_CONFIGURED',
      message: message ?? 'Provider가 설정되지 않았습니다.',
      hint: 'KAuthConfig에서 Provider를 설정해주세요.',
    );
    mockUser = null;
  }

  /// 상태 변경 이벤트 발생 (Widget 테스트용)
  ///
  /// ```dart
  /// await tester.pumpWidget(MyApp(kAuth: mockKAuth));
  ///
  /// mockKAuth.simulateAuthStateChange(newUser);
  /// await tester.pump();
  ///
  /// expect(find.byType(HomeScreen), findsOneWidget);
  /// ```
  void simulateAuthStateChange(KAuthUser? user) {
    _currentUser = user;
    _authStateController.add(user);
  }

  /// 토큰 만료 이벤트 시뮬레이션 (Widget 테스트용)
  ///
  /// ```dart
  /// mockKAuth.simulateTokenExpiry();
  /// await tester.pump();
  /// expect(find.byType(TokenBanner), findsOneWidget);
  /// ```
  void simulateTokenExpiry() {
    expireNow();
    // 상태는 유지하되 만료됨을 알림
    _authStateController.add(_currentUser);
  }
}
