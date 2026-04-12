# 카카오 개발자 콘솔 설정 가이드

카카오 로그인을 사용하려면 [카카오 개발자 콘솔](https://developers.kakao.com)에서 앱을 등록하고 설정해야 합니다.  
이 문서는 콘솔 설정 전 과정을 단계별로 안내합니다.

---

## 1. 애플리케이션 등록

1. [카카오 개발자 콘솔](https://developers.kakao.com)에 접속 후 로그인합니다.
2. 상단 메뉴에서 **내 애플리케이션**을 클릭합니다.
3. **애플리케이션 추가하기** 버튼을 클릭합니다.

<!-- TODO: 스크린샷 - 애플리케이션 추가하기 버튼 -->
<!-- ![애플리케이션 추가](docs/images/kakao-console/01-add-app.png) -->

4. **앱 이름**, **사업자명**을 입력하고 저장합니다.

<!-- TODO: 스크린샷 - 앱 이름/사업자명 입력 폼 -->
<!-- ![앱 정보 입력](docs/images/kakao-console/02-app-info.png) -->

5. 생성된 앱을 클릭하면 **앱 키** 페이지로 이동합니다.  
   여기서 **네이티브 앱 키**를 확인합니다. 이 키가 `{KAKAO_APP_KEY}`에 들어갈 값입니다.

<!-- TODO: 스크린샷 - 네이티브 앱 키 확인 화면 -->
<!-- ![앱 키 확인](docs/images/kakao-console/03-app-key.png) -->

---

## 2. 플랫폼 등록

앱 대시보드 좌측 메뉴에서 **앱 설정 > 플랫폼**으로 이동합니다.

<!-- TODO: 스크린샷 - 플랫폼 메뉴 위치 -->
<!-- ![플랫폼 메뉴](docs/images/kakao-console/04-platform-menu.png) -->

### iOS 플랫폼 등록

1. **iOS 플랫폼 등록** 버튼을 클릭합니다.
2. **번들 ID**를 입력합니다.  
   Xcode 프로젝트의 `TARGETS > General > Bundle Identifier` 값과 동일해야 합니다.

<!-- TODO: 스크린샷 - iOS 번들 ID 입력 -->
<!-- ![iOS 플랫폼 등록](docs/images/kakao-console/05-ios-platform.png) -->

3. **저장** 버튼을 클릭합니다.

### Android 플랫폼 등록

1. **Android 플랫폼 등록** 버튼을 클릭합니다.
2. **패키지명**을 입력합니다.  
   `android/app/build.gradle`의 `applicationId` 값과 동일해야 합니다.

<!-- TODO: 스크린샷 - Android 패키지명 입력 -->
<!-- ![Android 플랫폼 등록](docs/images/kakao-console/06-android-platform.png) -->

3. **키 해시**를 입력합니다. 아래 명령어로 추출할 수 있습니다.

**디버그 키 해시 (개발용)**

```sh
# macOS / Linux
keytool -exportcert -alias androiddebugkey -keystore ~/.android/debug.keystore -storepass android -keypass android | openssl sha1 -binary | openssl base64
```

```bat
:: Windows
keytool -exportcert -alias androiddebugkey -keystore %USERPROFILE%\.android\debug.keystore -storepass android -keypass android | openssl sha1 -binary | openssl base64
```

**릴리즈 키 해시 (배포용)**

```sh
keytool -exportcert -alias {KEY_ALIAS} -keystore {KEYSTORE_PATH} | openssl sha1 -binary | openssl base64
```

> [!NOTE]
> 개발 중에는 디버그 키 해시를, 스토어 배포 시에는 릴리즈 키 해시를 등록해야 합니다.  
> 두 키 해시를 모두 등록하면 개발과 배포 환경 모두 사용할 수 있습니다.

4. **저장** 버튼을 클릭합니다.

---

## 3. 카카오 로그인 활성화

1. 앱 대시보드 좌측 메뉴에서 **제품 설정 > 카카오 로그인**으로 이동합니다.
2. **카카오 로그인 활성화** 토글을 **ON**으로 설정합니다.

<!-- TODO: 스크린샷 - 카카오 로그인 활성화 토글 -->
<!-- ![카카오 로그인 활성화](docs/images/kakao-console/07-login-enable.png) -->

> [!WARNING]
> 활성화하지 않으면 로그인 시도 시 오류가 발생합니다.

---

## 4. 동의항목 설정

1. 앱 대시보드 좌측 메뉴에서 **제품 설정 > 카카오 로그인 > 동의항목**으로 이동합니다.
2. 앱에서 수집할 항목을 설정합니다.

<!-- TODO: 스크린샷 - 동의항목 목록 화면 -->
<!-- ![동의항목 설정](docs/images/kakao-console/08-consent-items.png) -->

| 항목               | 설명                     | 비고             |
| ------------------ | ------------------------ | ---------------- |
| 닉네임             | 카카오계정 닉네임        | 필수 동의 권장   |
| 프로필 사진        | 카카오계정 프로필 이미지 |                  |
| 카카오계정(이메일) | 이메일 주소              | 선택 동의        |
| 성별               | 사용자 성별              | 선택 동의        |
| 연령대             | 사용자 연령대            | 선택 동의        |
| 생일               | 생일 (MMDD)              | 선택 동의        |
| 출생 연도          | 출생 연도                | 선택 동의        |
| 전화번호           | 카카오계정 전화번호      | 사업자 등록 필요 |
| 이름               | 실명                     | 사업자 등록 필요 |
| 배송지             | 배송주소 목록            | 사업자 등록 필요 |

> [!NOTE] > **필수 동의** 항목은 사용자가 거부할 수 없으며, 카카오 검수가 필요합니다.  
> 개발 단계에서는 **선택 동의**로 설정하는 것을 권장합니다.

---

설정이 완료되면 [README](../README.md)로 돌아가 네이티브 설정을 진행하세요.
