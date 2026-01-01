import 'package:k_auth/k_auth.dart';

/// 테스트용 Mock Provider
class MockAuthProvider implements BaseAuthProvider {
  final AuthProvider provider;
  bool initializeCalled = false;
  bool signInCalled = false;
  bool signOutCalled = false;
  bool unlinkCalled = false;
  bool refreshTokenCalled = false;

  AuthResult? signInResult;
  AuthResult? signOutResult;
  AuthResult? unlinkResult;
  AuthResult? refreshTokenResult;

  /// 지연 시간 (네트워크 지연 시뮬레이션)
  Duration? delay;

  MockAuthProvider(this.provider);

  /// 성공하는 Mock Provider
  factory MockAuthProvider.success(AuthProvider provider, {KAuthUser? user}) {
    final mock = MockAuthProvider(provider);
    mock.signInResult = AuthResult.success(
      provider: provider,
      user: user ??
          KAuthUser(
            id: 'mock_user_id',
            name: 'Mock User',
            email: 'mock@test.com',
            provider: provider,
          ),
      accessToken: 'mock_access_token',
      refreshToken: 'mock_refresh_token',
      expiresAt: DateTime.now().add(Duration(hours: 1)),
    );
    return mock;
  }

  /// 실패하는 Mock Provider
  factory MockAuthProvider.failure(
    AuthProvider provider, {
    String? code,
    String? message,
  }) {
    final mock = MockAuthProvider(provider);
    mock.signInResult = AuthResult.failure(
      provider: provider,
      errorCode: code ?? ErrorCodes.loginFailed,
      errorMessage: message ?? '로그인 실패',
    );
    return mock;
  }

  @override
  Future<void> initialize() async {
    if (delay != null) await Future.delayed(delay!);
    initializeCalled = true;
  }

  @override
  Future<AuthResult> signIn() async {
    if (delay != null) await Future.delayed(delay!);
    signInCalled = true;
    return signInResult ??
        AuthResult.success(
          provider: provider,
          user: KAuthUser(
            id: 'mock_user_id',
            name: 'Mock User',
            email: 'mock@test.com',
            provider: provider,
          ),
          accessToken: 'mock_access_token',
          refreshToken: 'mock_refresh_token',
          expiresAt: DateTime.now().add(Duration(hours: 1)),
        );
  }

  @override
  Future<AuthResult> signOut() async {
    if (delay != null) await Future.delayed(delay!);
    signOutCalled = true;
    return signOutResult ?? AuthResult.success(provider: provider, user: null);
  }

  @override
  Future<AuthResult> unlink() async {
    if (delay != null) await Future.delayed(delay!);
    unlinkCalled = true;
    return unlinkResult ?? AuthResult.success(provider: provider, user: null);
  }

  @override
  Future<AuthResult> refreshToken() async {
    if (delay != null) await Future.delayed(delay!);
    refreshTokenCalled = true;
    return refreshTokenResult ??
        AuthResult.success(
          provider: provider,
          user: KAuthUser(
            id: 'mock_user_id',
            name: 'Mock User',
            email: 'mock@test.com',
            provider: provider,
          ),
          accessToken: 'new_access_token',
          refreshToken: 'new_refresh_token',
          expiresAt: DateTime.now().add(Duration(hours: 1)),
        );
  }

  void reset() {
    initializeCalled = false;
    signInCalled = false;
    signOutCalled = false;
    unlinkCalled = false;
    refreshTokenCalled = false;
    signInResult = null;
    signOutResult = null;
    unlinkResult = null;
    refreshTokenResult = null;
  }
}

/// 테스트용 세션 저장소
class TestSessionStorage implements KAuthSessionStorage {
  final Map<String, String> _data = {};
  bool saveError = false;
  bool readError = false;

  bool containsKey(String key) => _data.containsKey(key);

  @override
  Future<void> save(String key, String value) async {
    if (saveError) throw Exception('Save error');
    _data[key] = value;
  }

  @override
  Future<String?> read(String key) async {
    if (readError) throw Exception('Read error');
    return _data[key];
  }

  @override
  Future<void> delete(String key) async {
    _data.remove(key);
  }

  @override
  Future<void> clear() async {
    _data.clear();
  }
}

/// 테스트용 세션 시나리오
class SessionScenarios {
  /// 유효한 세션 (1시간 후 만료)
  static KAuthSession valid({AuthProvider? provider}) {
    return KAuthSession(
      provider: provider ?? AuthProvider.kakao,
      user: KAuthUser(
        id: 'test_user',
        name: 'Test User',
        email: 'test@test.com',
        provider: provider ?? AuthProvider.kakao,
      ),
      accessToken: 'valid_token',
      refreshToken: 'valid_refresh',
      expiresAt: DateTime.now().add(Duration(hours: 1)),
      savedAt: DateTime.now(),
    );
  }

  /// 만료 임박 세션 (3분 후 만료)
  static KAuthSession expiringSoon({AuthProvider? provider}) {
    return KAuthSession(
      provider: provider ?? AuthProvider.kakao,
      user: KAuthUser(
        id: 'test_user',
        name: 'Test User',
        email: 'test@test.com',
        provider: provider ?? AuthProvider.kakao,
      ),
      accessToken: 'expiring_token',
      refreshToken: 'expiring_refresh',
      expiresAt: DateTime.now().add(Duration(minutes: 3)),
      savedAt: DateTime.now(),
    );
  }

  /// 만료된 세션
  static KAuthSession expired({AuthProvider? provider}) {
    return KAuthSession(
      provider: provider ?? AuthProvider.kakao,
      user: KAuthUser(
        id: 'test_user',
        name: 'Test User',
        email: 'test@test.com',
        provider: provider ?? AuthProvider.kakao,
      ),
      accessToken: 'expired_token',
      refreshToken: 'expired_refresh',
      expiresAt: DateTime.now().subtract(Duration(hours: 1)),
      savedAt: DateTime.now().subtract(Duration(hours: 2)),
    );
  }

  /// 손상된 세션 데이터
  static String corrupted() => 'corrupted_data_not_json';
}

/// 테스트용 KAuth 생성 헬퍼
class TestKAuthFactory {
  /// Mock Provider로 KAuth 생성
  static KAuth withMockProviders({
    Map<AuthProvider, MockAuthProvider>? providers,
    KAuthSessionStorage? storage,
  }) {
    final kAuth = KAuth(
      config: KAuthConfig(
        kakao: KakaoConfig(appKey: 'test_key'),
        naver: NaverConfig(
          clientId: 'test_id',
          clientSecret: 'test_secret',
          appName: 'Test App',
        ),
        google: GoogleConfig(),
        apple: AppleConfig(),
      ),
      validateOnInitialize: false,
      storage: storage,
    );

    providers?.forEach((provider, mock) {
      kAuth.setProviderForTesting(provider, mock);
    });

    return kAuth;
  }

  /// 이미 로그인된 상태의 KAuth 생성
  static Future<KAuth> signedIn({
    AuthProvider provider = AuthProvider.kakao,
    KAuthUser? user,
    KAuthSessionStorage? storage,
  }) async {
    final mock = MockAuthProvider.success(provider, user: user);
    final kAuth = withMockProviders(
      providers: {provider: mock},
      storage: storage,
    );
    await kAuth.signIn(provider);
    return kAuth;
  }
}
