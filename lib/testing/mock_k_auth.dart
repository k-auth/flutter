import 'dart:async';
import '../models/auth_result.dart';
import '../models/k_auth_user.dart';
import '../models/k_auth_failure.dart';

/// 테스트용 Mock KAuth
///
/// 실제 SDK 호출 없이 KAuth 동작을 시뮬레이션합니다.
/// Widget 테스트나 유닛 테스트에서 사용하세요.
///
/// ## 기본 사용법
///
/// ```dart
/// // 테스트에서 MockKAuth 생성
/// final mockKAuth = MockKAuth();
///
/// // 로그인 성공 설정
/// mockKAuth.mockUser = KAuthUser(
///   id: 'test_user_123',
///   provider: AuthProvider.kakao,
///   email: 'test@example.com',
///   name: 'Test User',
/// );
///
/// // 로그인 실행 (자동으로 mockUser 반환)
/// final result = await mockKAuth.signIn(AuthProvider.kakao);
/// expect(result.success, true);
/// expect(result.user?.id, 'test_user_123');
/// ```
///
/// ## 실패 시뮬레이션
///
/// ```dart
/// final mockKAuth = MockKAuth();
///
/// // 실패 설정
/// mockKAuth.mockFailure = KAuthFailure(
///   code: 'USER_CANCELLED',
///   message: '사용자가 로그인을 취소했습니다',
/// );
///
/// // 로그인 실행
/// final result = await mockKAuth.signIn(AuthProvider.kakao);
/// expect(result.success, false);
/// expect(result.errorCode, 'USER_CANCELLED');
/// ```
///
/// ## 이미 로그인된 상태로 시작
///
/// ```dart
/// final mockKAuth = MockKAuth.signedIn(
///   user: KAuthUser(
///     id: 'test_123',
///     provider: AuthProvider.kakao,
///   ),
/// );
///
/// expect(mockKAuth.isSignedIn, true);
/// expect(mockKAuth.userId, 'test_123');
/// ```
///
/// ## Widget 테스트 예시
///
/// ```dart
/// testWidgets('shows home screen when signed in', (tester) async {
///   final mockKAuth = MockKAuth.signedIn(
///     user: KAuthUser(id: 'user_123', provider: AuthProvider.kakao),
///   );
///
///   await tester.pumpWidget(
///     MaterialApp(
///       home: KAuthBuilder(
///         stream: mockKAuth.authStateChanges,
///         signedIn: (user) => HomeScreen(user: user),
///         signedOut: () => LoginScreen(),
///       ),
///     ),
///   );
///
///   expect(find.byType(HomeScreen), findsOneWidget);
/// });
/// ```
class MockKAuth {
  /// Mock 사용자 (설정하면 signIn 성공)
  KAuthUser? mockUser;

  /// Mock 실패 (설정하면 signIn 실패)
  KAuthFailure? mockFailure;

  /// Mock 서버 토큰
  String? mockServerToken;

  /// 지연 시간 (네트워크 지연 시뮬레이션)
  Duration? mockDelay;

  /// 설정된 Provider 목록
  List<AuthProvider> mockConfiguredProviders;

  /// 내부 상태
  KAuthUser? _currentUser;
  String? _serverToken;
  bool _initialized = false;
  final _authStateController = StreamController<KAuthUser?>.broadcast();

  /// MockKAuth 생성
  ///
  /// [mockUser]: 로그인 성공 시 반환할 사용자
  /// [mockFailure]: 로그인 실패 시 반환할 에러
  /// [mockDelay]: 네트워크 지연 시뮬레이션
  /// [mockConfiguredProviders]: 설정된 Provider 목록
  MockKAuth({
    this.mockUser,
    this.mockFailure,
    this.mockServerToken,
    this.mockDelay,
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
    mock._initialized = true;
    return mock;
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
    if (mockDelay != null) {
      await Future.delayed(mockDelay!);
    }
    _initialized = true;
  }

  /// 소셜 로그인
  Future<AuthResult> signIn(AuthProvider provider) async {
    if (mockDelay != null) {
      await Future.delayed(mockDelay!);
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
      _authStateController.add(user);

      return AuthResult.success(
        provider: provider,
        user: user,
        accessToken: 'mock_access_token',
        refreshToken: 'mock_refresh_token',
      );
    }

    // 기본: 빈 사용자로 성공
    final user = KAuthUser(
      id: 'mock_user_${DateTime.now().millisecondsSinceEpoch}',
      provider: provider,
    );

    _currentUser = user;
    _serverToken = mockServerToken;
    _authStateController.add(user);

    return AuthResult.success(
      provider: provider,
      user: user,
      accessToken: 'mock_access_token',
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
    if (mockDelay != null) {
      await Future.delayed(mockDelay!);
    }

    final targetProvider = provider ?? currentProvider ?? AuthProvider.kakao;

    _currentUser = null;
    _serverToken = null;
    _authStateController.add(null);

    return AuthResult.success(
      provider: targetProvider,
      user: null,
    );
  }

  /// 모든 Provider 로그아웃
  Future<List<AuthResult>> signOutAll() async {
    if (mockDelay != null) {
      await Future.delayed(mockDelay!);
    }

    _currentUser = null;
    _serverToken = null;
    _authStateController.add(null);

    return configuredProviders
        .map((p) => AuthResult.success(provider: p, user: null))
        .toList();
  }

  /// 연결 해제
  Future<AuthResult> unlink(AuthProvider provider) async {
    if (mockDelay != null) {
      await Future.delayed(mockDelay!);
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
      _authStateController.add(null);
    }

    return AuthResult.success(
      provider: provider,
      user: null,
    );
  }

  /// 토큰 갱신
  Future<AuthResult> refreshToken([AuthProvider? provider]) async {
    if (mockDelay != null) {
      await Future.delayed(mockDelay!);
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

    return AuthResult.success(
      provider: targetProvider,
      user: _currentUser,
      accessToken: 'mock_refreshed_access_token',
      refreshToken: 'mock_refreshed_refresh_token',
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
    mockDelay = null;
    _currentUser = null;
    _serverToken = null;
    _initialized = false;
  }

  /// 로그인 성공으로 설정
  void setSignedIn(KAuthUser user, {String? serverToken}) {
    mockUser = user;
    mockFailure = null;
    _currentUser = user;
    _serverToken = serverToken;
    _initialized = true;
    _authStateController.add(user);
  }

  /// 로그아웃 상태로 설정
  void setSignedOut() {
    _currentUser = null;
    _serverToken = null;
    _authStateController.add(null);
  }

  /// 실패로 설정
  void setFailure({
    String? code,
    String? message,
    String? hint,
  }) {
    mockFailure = KAuthFailure(
      code: code,
      message: message,
      hint: hint,
    );
    mockUser = null;
  }

  /// 취소로 설정
  void setCancelled() {
    setFailure(
      code: 'USER_CANCELLED',
      message: '사용자가 로그인을 취소했습니다.',
    );
  }

  /// 네트워크 에러로 설정
  void setNetworkError() {
    setFailure(
      code: 'NETWORK_ERROR',
      message: '네트워크 오류가 발생했습니다.',
      hint: '인터넷 연결 상태를 확인해주세요.',
    );
  }
}
