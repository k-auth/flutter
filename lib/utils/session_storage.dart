import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/auth_result.dart';
import '../models/k_auth_user.dart';

/// 세션 저장소 인터페이스
///
/// 자동 로그인을 위해 세션을 저장/복원합니다.
/// SharedPreferences, SecureStorage 등 원하는 구현체를 사용할 수 있습니다.
///
/// ## 예시: SharedPreferences 사용
///
/// ```dart
/// class SharedPrefsSessionStorage implements KAuthSessionStorage {
///   final SharedPreferences _prefs;
///   SharedPrefsSessionStorage(this._prefs);
///
///   @override
///   Future<void> save(String key, String value) async {
///     await _prefs.setString(key, value);
///   }
///
///   @override
///   Future<String?> read(String key) async {
///     return _prefs.getString(key);
///   }
///
///   @override
///   Future<void> delete(String key) async {
///     await _prefs.remove(key);
///   }
///
///   @override
///   Future<void> clear() async {
///     await _prefs.clear();
///   }
/// }
/// ```
///
/// ## 예시: SecureStorage 사용 (권장)
///
/// ```dart
/// class SecureSessionStorage implements KAuthSessionStorage {
///   final FlutterSecureStorage _storage = FlutterSecureStorage();
///
///   @override
///   Future<void> save(String key, String value) async {
///     await _storage.write(key: key, value: value);
///   }
///
///   @override
///   Future<String?> read(String key) async {
///     return await _storage.read(key: key);
///   }
///
///   @override
///   Future<void> delete(String key) async {
///     await _storage.delete(key: key);
///   }
///
///   @override
///   Future<void> clear() async {
///     await _storage.deleteAll();
///   }
/// }
/// ```
abstract class KAuthSessionStorage {
  /// 데이터 저장
  Future<void> save(String key, String value);

  /// 데이터 읽기
  Future<String?> read(String key);

  /// 데이터 삭제
  Future<void> delete(String key);

  /// 모든 데이터 삭제
  Future<void> clear();
}

/// 메모리 기반 세션 저장소
///
/// 앱이 종료되면 데이터가 사라집니다.
/// 테스트나 개발 환경에서 사용하세요.
///
/// ```dart
/// final kAuth = KAuth(
///   config: config,
///   storage: InMemorySessionStorage(),
/// );
/// ```
class InMemorySessionStorage implements KAuthSessionStorage {
  final Map<String, String> _storage = {};

  @override
  Future<void> save(String key, String value) async {
    _storage[key] = value;
  }

  @override
  Future<String?> read(String key) async {
    return _storage[key];
  }

  @override
  Future<void> delete(String key) async {
    _storage.remove(key);
  }

  @override
  Future<void> clear() async {
    _storage.clear();
  }
}

/// SecureStorage 기반 세션 저장소 (기본값)
///
/// 암호화된 저장소에 세션을 저장합니다.
/// iOS는 Keychain, Android는 EncryptedSharedPreferences를 사용합니다.
///
/// ```dart
/// final kAuth = await KAuth.init(
///   kakao: KakaoConfig(appKey: 'YOUR_APP_KEY'),
/// );
/// // SecureSessionStorage가 자동으로 사용됨
/// ```
class SecureSessionStorage implements KAuthSessionStorage {
  final FlutterSecureStorage _storage;

  /// SecureSessionStorage 생성
  ///
  /// [androidOptions] 또는 [iosOptions]를 통해 플랫폼별 설정을 커스터마이징할 수 있습니다.
  SecureSessionStorage({
    AndroidOptions? androidOptions,
    IOSOptions? iosOptions,
  }) : _storage = FlutterSecureStorage(
          aOptions: androidOptions ?? _defaultAndroidOptions,
          iOptions: iosOptions ?? _defaultIOSOptions,
        );

  static const _defaultAndroidOptions = AndroidOptions();

  static const _defaultIOSOptions = IOSOptions(
    accessibility: KeychainAccessibility.first_unlock_this_device,
  );

  @override
  Future<void> save(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  @override
  Future<String?> read(String key) async {
    return await _storage.read(key: key);
  }

  @override
  Future<void> delete(String key) async {
    await _storage.delete(key: key);
  }

  @override
  Future<void> clear() async {
    await _storage.deleteAll();
  }
}

/// 저장된 세션 데이터
class KAuthSession {
  /// Provider
  final AuthProvider provider;

  /// 사용자 정보
  final KAuthUser user;

  /// 액세스 토큰
  final String? accessToken;

  /// 리프레시 토큰
  final String? refreshToken;

  /// ID 토큰
  final String? idToken;

  /// 토큰 만료 시간
  final DateTime? expiresAt;

  /// 서버 토큰 (백엔드 JWT 등)
  final String? serverToken;

  /// 저장 시간
  final DateTime savedAt;

  const KAuthSession({
    required this.provider,
    required this.user,
    this.accessToken,
    this.refreshToken,
    this.idToken,
    this.expiresAt,
    this.serverToken,
    required this.savedAt,
  });

  /// 토큰이 만료되었는지 확인
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  /// JSON으로 변환
  Map<String, dynamic> toJson() => {
        'provider': provider.name,
        'user': user.toJson(),
        if (accessToken != null) 'accessToken': accessToken,
        if (refreshToken != null) 'refreshToken': refreshToken,
        if (idToken != null) 'idToken': idToken,
        if (expiresAt != null) 'expiresAt': expiresAt!.toIso8601String(),
        if (serverToken != null) 'serverToken': serverToken,
        'savedAt': savedAt.toIso8601String(),
      };

  /// JSON에서 생성
  factory KAuthSession.fromJson(Map<String, dynamic> json) {
    return KAuthSession(
      provider: AuthProvider.values.firstWhere(
        (p) => p.name == json['provider'],
        orElse: () => AuthProvider.kakao,
      ),
      user: KAuthUser.fromJson(json['user'] as Map<String, dynamic>),
      accessToken: json['accessToken'] as String?,
      refreshToken: json['refreshToken'] as String?,
      idToken: json['idToken'] as String?,
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'] as String)
          : null,
      serverToken: json['serverToken'] as String?,
      savedAt: DateTime.parse(json['savedAt'] as String),
    );
  }

  /// AuthResult에서 생성
  factory KAuthSession.fromAuthResult(
    AuthResult result, {
    String? serverToken,
  }) {
    if (!result.success || result.user == null) {
      throw ArgumentError('AuthResult must be successful with user');
    }

    return KAuthSession(
      provider: result.provider,
      user: result.user!,
      accessToken: result.accessToken,
      refreshToken: result.refreshToken,
      idToken: result.idToken,
      expiresAt: result.expiresAt,
      serverToken: serverToken,
      savedAt: DateTime.now(),
    );
  }

  /// JSON 문자열로 인코딩
  String encode() => jsonEncode(toJson());

  /// JSON 문자열에서 디코딩
  static KAuthSession decode(String encoded) {
    return KAuthSession.fromJson(jsonDecode(encoded) as Map<String, dynamic>);
  }

  @override
  String toString() =>
      'KAuthSession(provider: $provider, user: ${user.id}, expired: $isExpired)';
}
