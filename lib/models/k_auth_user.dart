/// K-Auth 표준화된 사용자 프로필
///
/// 모든 Provider에서 반환되는 사용자 정보를 통일된 형식으로 제공합니다.
class KAuthUser {
  /// Provider별 고유 사용자 ID
  final String id;

  /// 사용자 이름
  final String? name;

  /// 이메일 주소
  final String? email;

  /// 프로필 이미지 URL
  final String? image;

  /// 전화번호
  final String? phone;

  /// 생일 (MM-DD 형식)
  final String? birthday;

  /// 출생연도 (YYYY 형식)
  final String? birthyear;

  /// 성별 ('male', 'female', 'unknown')
  final String? gender;

  /// 연령대 ('0~9', '10~19', '20~29' 등)
  final String? ageRange;

  /// CI (연계정보, 카카오 비즈니스용)
  final String? ci;

  /// 로그인한 Provider
  final String provider;

  /// 원본 Provider 응답 데이터
  final Map<String, dynamic>? rawData;

  const KAuthUser({
    required this.id,
    required this.provider,
    this.name,
    this.email,
    this.image,
    this.phone,
    this.birthday,
    this.birthyear,
    this.gender,
    this.ageRange,
    this.ci,
    this.rawData,
  });

  /// Kakao 응답에서 KAuthUser 생성
  factory KAuthUser.fromKakao(Map<String, dynamic> data) {
    final account = data['kakao_account'] as Map<String, dynamic>? ?? {};
    final profile = account['profile'] as Map<String, dynamic>? ?? {};

    String? gender;
    if (account['gender'] != null) {
      gender = account['gender'] == 'male' ? 'male' : 'female';
    }

    return KAuthUser(
      id: data['id'].toString(),
      provider: 'kakao',
      name: profile['nickname'] as String?,
      email: account['email'] as String?,
      image: profile['profile_image_url'] as String?,
      phone: account['phone_number'] as String?,
      birthday: account['birthday'] as String?,
      birthyear: account['birthyear'] as String?,
      gender: gender,
      ageRange: account['age_range'] as String?,
      ci: account['ci'] as String?,
      rawData: data,
    );
  }

  /// Naver 응답에서 KAuthUser 생성
  factory KAuthUser.fromNaver(Map<String, dynamic> data) {
    final response = data['response'] as Map<String, dynamic>? ?? data;

    String? gender;
    if (response['gender'] != null) {
      gender = response['gender'] == 'M' ? 'male' : 'female';
    }

    return KAuthUser(
      id: response['id'] as String,
      provider: 'naver',
      name: response['name'] as String? ?? response['nickname'] as String?,
      email: response['email'] as String?,
      image: response['profile_image'] as String?,
      phone: response['mobile'] as String?,
      birthday: response['birthday'] as String?,
      birthyear: response['birthyear'] as String?,
      gender: gender,
      ageRange: response['age'] as String?,
      rawData: data,
    );
  }

  /// Google 응답에서 KAuthUser 생성
  factory KAuthUser.fromGoogle(Map<String, dynamic> data) {
    return KAuthUser(
      id: data['id'] as String? ?? data['sub'] as String,
      provider: 'google',
      name: data['name'] as String? ?? data['displayName'] as String?,
      email: data['email'] as String?,
      image: data['picture'] as String? ?? data['photoUrl'] as String?,
      rawData: data,
    );
  }

  /// Apple 응답에서 KAuthUser 생성
  factory KAuthUser.fromApple(Map<String, dynamic> data) {
    String? name;
    final givenName = data['givenName'] as String?;
    final familyName = data['familyName'] as String?;

    if (givenName != null || familyName != null) {
      name = [familyName, givenName].whereType<String>().join(' ').trim();
      if (name.isEmpty) name = null;
    }

    return KAuthUser(
      id: data['userIdentifier'] as String? ?? data['sub'] as String,
      provider: 'apple',
      name: name,
      email: data['email'] as String?,
      rawData: data,
    );
  }

  /// JSON으로 변환
  Map<String, dynamic> toJson() => {
        'id': id,
        'provider': provider,
        if (name != null) 'name': name,
        if (email != null) 'email': email,
        if (image != null) 'image': image,
        if (phone != null) 'phone': phone,
        if (birthday != null) 'birthday': birthday,
        if (birthyear != null) 'birthyear': birthyear,
        if (gender != null) 'gender': gender,
        if (ageRange != null) 'ageRange': ageRange,
        if (ci != null) 'ci': ci,
      };

  /// JSON에서 생성
  factory KAuthUser.fromJson(Map<String, dynamic> json) {
    return KAuthUser(
      id: json['id'] as String,
      provider: json['provider'] as String,
      name: json['name'] as String?,
      email: json['email'] as String?,
      image: json['image'] as String?,
      phone: json['phone'] as String?,
      birthday: json['birthday'] as String?,
      birthyear: json['birthyear'] as String?,
      gender: json['gender'] as String?,
      ageRange: json['ageRange'] as String?,
      ci: json['ci'] as String?,
      rawData: json['rawData'] as Map<String, dynamic>?,
    );
  }

  /// 표시할 이름 (name이 없으면 email의 @ 앞부분 사용)
  String? get displayName {
    if (name != null && name!.isNotEmpty) return name!;
    if (email != null && email!.contains('@')) {
      return email!.split('@').first;
    }
    return null;
  }

  /// 만 나이 계산 (birthyear가 있는 경우)
  int? get age {
    if (birthyear == null) return null;
    final year = int.tryParse(birthyear!);
    if (year == null) return null;
    return DateTime.now().year - year;
  }

  @override
  String toString() =>
      'KAuthUser(id: $id, provider: $provider, name: $name, email: $email)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KAuthUser &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          provider == other.provider;

  @override
  int get hashCode => id.hashCode ^ provider.hashCode;

  /// 복사본 생성 (일부 필드 수정)
  KAuthUser copyWith({
    String? id,
    String? provider,
    String? name,
    String? email,
    String? image,
    String? phone,
    String? birthday,
    String? birthyear,
    String? gender,
    String? ageRange,
    String? ci,
    Map<String, dynamic>? rawData,
  }) {
    return KAuthUser(
      id: id ?? this.id,
      provider: provider ?? this.provider,
      name: name ?? this.name,
      email: email ?? this.email,
      image: image ?? this.image,
      phone: phone ?? this.phone,
      birthday: birthday ?? this.birthday,
      birthyear: birthyear ?? this.birthyear,
      gender: gender ?? this.gender,
      ageRange: ageRange ?? this.ageRange,
      ci: ci ?? this.ci,
      rawData: rawData ?? this.rawData,
    );
  }
}
