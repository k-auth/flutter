# 플랫폼 설정 가이드

K-Auth를 사용하기 위한 iOS/Android 플랫폼별 설정 가이드입니다.

> **팁**: `dart run k_auth` CLI 도구를 사용하면 대부분의 설정을 자동으로 처리할 수 있습니다.

## 목차

- [iOS 설정](#ios-설정)
  - [Info.plist](#1-infoplist-설정)
  - [AppDelegate (네이버)](#2-appdelegate-설정-네이버)
  - [Apple Sign In (Xcode)](#3-apple-sign-in-설정-xcode)
- [Android 설정](#android-설정)
  - [strings.xml (네이버)](#1-stringsxml-설정-네이버)
  - [AndroidManifest.xml](#2-androidmanifestxml-설정)
  - [MainActivity (네이버)](#3-mainactivity-수정-네이버-필수)
  - [키 해시 등록 (카카오)](#4-키-해시-등록-카카오)

---

## iOS 설정

### 1. Info.plist 설정

`ios/Runner/Info.plist`에 다음을 추가:

```xml
<!-- URL Schemes (카카오, 네이버, 구글) -->
<key>CFBundleURLTypes</key>
<array>
  <!-- 카카오 -->
  <dict>
    <key>CFBundleTypeRole</key>
    <string>Editor</string>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>kakao{YOUR_NATIVE_APP_KEY}</string>
    </array>
  </dict>
  <!-- 네이버 -->
  <dict>
    <key>CFBundleTypeRole</key>
    <string>Editor</string>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>{YOUR_NAVER_URL_SCHEME}</string>
    </array>
  </dict>
  <!-- 구글 (역방향 클라이언트 ID) -->
  <dict>
    <key>CFBundleTypeRole</key>
    <string>Editor</string>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>com.googleusercontent.apps.{YOUR_CLIENT_ID}</string>
    </array>
  </dict>
</array>

<!-- 카카오/네이버 앱 호출을 위한 설정 -->
<key>LSApplicationQueriesSchemes</key>
<array>
  <!-- 카카오 -->
  <string>kakaokompassauth</string>
  <string>kakaolink</string>
  <string>kakaotalk</string>
  <!-- 네이버 -->
  <string>naversearchapp</string>
  <string>naversearchthirdlogin</string>
</array>

<!-- 네이버 로그인 설정 -->
<key>NidConsumerKey</key>
<string>{YOUR_NAVER_CLIENT_ID}</string>
<key>NidConsumerSecret</key>
<string>{YOUR_NAVER_CLIENT_SECRET}</string>
<key>NidAppName</key>
<string>{YOUR_APP_NAME}</string>
```

### 2. AppDelegate 설정 (네이버)

`ios/Runner/AppDelegate.swift`에서 네이버 URL 핸들링 추가:

```swift
import UIKit
import Flutter
import NidThirdPartyLogin  // 추가

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // 네이버 로그인 URL 핸들링 추가
  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey : Any] = [:]
  ) -> Bool {
    if NidOAuth.shared.handleURL(url) {
      return true
    }
    return super.application(app, open: url, options: options)
  }
}
```

### 3. Apple Sign In 설정 (Xcode)

1. Xcode에서 프로젝트 열기
2. **Runner** 타겟 선택
3. **Signing & Capabilities** 탭
4. **+ Capability** 클릭
5. **Sign in with Apple** 추가

---

## Android 설정

### 1. strings.xml 설정 (네이버)

`android/app/src/main/res/values/strings.xml` 파일 생성 또는 수정:

```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="client_id">{YOUR_NAVER_CLIENT_ID}</string>
    <string name="client_secret">{YOUR_NAVER_CLIENT_SECRET}</string>
    <string name="client_name">{YOUR_APP_NAME}</string>
</resources>
```

### 2. AndroidManifest.xml 설정

`android/app/src/main/AndroidManifest.xml`의 `<application>` 태그 안에 추가:

```xml
<!-- 네이버 로그인 메타데이터 -->
<meta-data
    android:name="com.naver.sdk.clientId"
    android:value="@string/client_id" />
<meta-data
    android:name="com.naver.sdk.clientSecret"
    android:value="@string/client_secret" />
<meta-data
    android:name="com.naver.sdk.clientName"
    android:value="@string/client_name" />

<!-- 카카오 로그인 -->
<activity
    android:name="com.kakao.sdk.flutter.AuthCodeCustomTabsActivity"
    android:exported="true">
    <intent-filter>
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />
        <data android:host="oauth"
              android:scheme="kakao{YOUR_NATIVE_APP_KEY}" />
    </intent-filter>
</activity>
```

### 3. MainActivity 수정 (네이버 필수)

`android/app/src/main/kotlin/.../MainActivity.kt`:

```kotlin
// 변경 전
import io.flutter.embedding.android.FlutterActivity

class MainActivity: FlutterActivity()

// 변경 후
import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity: FlutterFragmentActivity()
```

### 4. 키 해시 등록 (카카오)

디버그/릴리즈 키 해시를 카카오 개발자 콘솔에 등록:

```bash
# 디버그 키 해시
keytool -exportcert -alias androiddebugkey -keystore ~/.android/debug.keystore -storepass android -keypass android | openssl sha1 -binary | openssl base64

# 릴리즈 키 해시
keytool -exportcert -alias {YOUR_ALIAS} -keystore {YOUR_KEYSTORE_PATH} | openssl sha1 -binary | openssl base64
```

---

## 설정 진단

설정이 올바른지 확인하려면:

```bash
dart run k_auth doctor
```

또는 코드에서:

```dart
final result = await KAuthDiagnostic.run(kAuth.config);
print(result.prettyPrint());
```

---

[← README로 돌아가기](../README.md)
