# HiteZero — 구글 플레이 출고 가이드 (Android AAB)

> 작성 2026-06-13. 대상: `com.gghf.hitezero`, Godot 6000.x / 4.6.
> 핵심: 플레이 스토어는 **웹 빌드(.zip)를 못 받습니다.** 서명된 **Android App
> Bundle(.aab)** 만 받습니다. 이 .aab는 **본인 keystore + Android SDK가 있는
> 본인 머신/에디터에서** 빌드·서명해야 합니다(서명 키는 비밀이라 에이전트가
> 대신 못 만듭니다).

이미 끝난 것: `godot/export_presets.cfg`의 Android 프리셋을 **AAB + gradle 커스텀
빌드**로 전환해 뒀습니다 (`export_format=1`, `use_gradle_build=true`,
`min_sdk=24`, `target_sdk=35`, `export_path=../build/android/hitezero.aab`).
keystore 칸은 **일부러 비워** 뒀습니다 — 비밀번호/키 경로를 cfg에 적으면 git에
시크릿이 커밋되기 때문. 키는 에디터나 환경변수로 빌드 때 주입합니다.

---

## 0. 큰 그림 (한 번만 이해하면 됨)

- **업로드 키(upload key)**: 내가 만드는 keystore. .aab에 이 키로 서명해서
  Play Console에 올린다.
- **Play 앱 서명(Play App Signing)**: 구글이 보관하는 진짜 배포 키. 내 업로드
  키로 올리면 구글이 자기 키로 다시 서명해 사용자에게 배포한다. → **업로드 키를
  잃어버려도 복구 가능**(구글에 재설정 요청). 그래서 요즘은 거의 무조건 켠다.
- 즉 내가 관리할 건 **업로드 keystore 파일 1개 + 비밀번호**. 이거 잃어버리면
  앱 업데이트가 막히니(재설정은 가능하지만 번거로움) **안전한 곳에 백업**.

---

## 1. 업로드 keystore — 이미 보유 (새로 안 만들어도 됨)

2026-06-13에 기존 키 파일을 확인했습니다. **새로 생성할 필요 없음.**

| 파일 | 종류 | 공개 인증서(SHA-256) | 유효기간 |
|---|---|---|---|
| `new_upload_key.jks` | keystore(개인키, 비밀) | 아래 .pem 중 하나와 매칭 확인 필요 | — |
| `kangmomo_2025build_key.jks` | keystore(개인키, 비밀) | 다른 앱(kangmomo)용으로 추정 | — |
| `upload_certificate.pem` | 공개 인증서 | `D9:EC:9F:BA:…:20:DF` | 2025-05-20 ~ 2050 |
| `upload_cert.pem` | 공개 인증서 | `87:12:C7:59:…:D7:62` | 2025-05-12 ~ 2075 |

→ **HiteZero 업로드 키 = `new_upload_key.jks`** (파일명 기준 추정).

### 1-1. 짝 맞추기 + alias 확인 (본인 머신에서, 비번은 채팅 금지)
```bash
keytool -list -v -keystore new_upload_key.jks
# 비밀번호 입력 후:
#  - "SHA256:" 지문을 위 표의 D9:EC… / 87:12… 와 비교 → 짝인 .pem 확정
#  - "Alias name:" 메모 (CLI 빌드의 RELEASE_USER 값)
```

- ⚠️ `.jks`와 비밀번호는 **절대 git/`dist`에 커밋 금지.** repo 바깥
  (`~/keystores/` 등)에 두고 **백업**.
- `kangmomo_2025build_key.jks`는 다른 앱 키로 보이니 **HiteZero에 재사용 금지**
  (의도한 게 아니라면).

> 만약 위 키가 다른 앱 전용이고 HiteZero용 새 업로드 키가 필요하다면, 그때만
> 새로 생성: `keytool -genkeypair -v -keystore ~/keystores/hitezero-upload.jks
> -alias hitezero-upload -keyalg RSA -keysize 2048 -validity 10000`.

---

## 2. Godot에서 Android 빌드 환경 준비 (최초 1회)

AAB는 gradle 커스텀 빌드라서 Android SDK가 필요합니다.

1. **OpenJDK 17** 설치 (Godot 4.6 Android 빌드 요구).
2. **Android SDK** — 가장 쉬운 길은 Android Studio 설치 후 SDK Manager에서
   Platform 35 + Build-Tools + Platform-Tools 설치. (CLI만 원하면 commandline
   -tools + `sdkmanager`.)
3. Godot 에디터: **Editor → Editor Settings → Export → Android** 에서
   - `Android Sdk Path` 를 설치한 SDK 경로로 지정
   - (JDK 경로 항목이 있으면) JDK 17 경로 지정
4. Godot 에디터: **Project → Install Android Build Template…** 실행
   → `res://android/build/` 에 gradle 소스가 깔립니다. (프리셋의
   `use_gradle_build=true`가 이 폴더를 씁니다.)
5. **Export 템플릿**: **Editor → Manage Export Templates → Download** 로 현재
   에디터 버전과 **정확히 같은 버전**의 템플릿을 받아둡니다.

> 검증: Project → Export → Android 프리셋에서 상단 경고(빨간 글씨)가 사라지면
> 환경 준비 완료.

---

## 3. 프리셋에 keystore 연결 + 버전 확인

**Project → Export → Android 프리셋 → Options** 에서:

- **Keystore → Release**: `new_upload_key.jks` 선택 (repo 바깥 보관 경로)
- **Release User**: 1-1에서 확인한 **alias**
- **Release Password**: keystore 비밀번호
  (에디터에 입력해도 export_presets.cfg에는 저장되지만 git에 올리지 마세요.
  더 안전하게 하려면 4-B의 CLI + 환경변수 방식 사용.)
- **Version Code / Version Name**: 첫 출시는 `code=1`, `name="1.0.0"` 그대로
  OK. **업데이트마다 `version/code`를 반드시 +1** (스토어가 코드로 버전 구분).

---

## 4. AAB 빌드

### 4-A. 에디터에서 (가장 쉬움)
Project → Export → **Export Project…** → Android 프리셋 → `hitezero.aab`로 저장.
"Export With Debug" **체크 해제**(릴리스 서명 AAB여야 함).
→ `godot/build/android/hitezero.aab` 생성.

### 4-B. 커맨드라인 (CI/재현용, 비밀번호를 파일에 안 남김)
```bash
cd godot
export GODOT_ANDROID_KEYSTORE_RELEASE_PATH="$HOME/keystores/new_upload_key.jks"
export GODOT_ANDROID_KEYSTORE_RELEASE_USER="<1-1에서 확인한 alias>"
export GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD="••••••"   # 셸 히스토리 주의
godot --headless --export-release "Android" ../build/android/hitezero.aab
```
환경변수를 쓰면 keystore 경로/비번을 cfg에 안 적어도 됩니다(권장).

> 빌드 후 `build/android/hitezero.aab` 가 나오면 성공. APK가 아니라 **.aab**
> 인지 확인.

---

## 5. Play Console 첫 등록 체크리스트

개발자 계정($25 1회) 가입 후, 새 앱 생성 → 아래를 준비:

- **앱 번들**: 4번의 `hitezero.aab` 업로드 (내부 테스트 트랙부터 권장)
- **Play 앱 서명**: 첫 업로드 시 자동 안내 → **켜기**(1단계 키가 업로드 키가 됨)
- **스토어 등록정보**: 앱 이름, 짧은/긴 설명, **아이콘 512×512**,
  **피처 그래픽 1024×500**, **스크린샷**(폰 최소 2장 — 위 셀 비주얼 캡처 활용)
- **콘텐츠 등급** 설문, **타깃 연령**, **개인정보 처리방침 URL**
  (네 Netlify 사이트에 한 페이지 추가하면 됨)
- **데이터 안전(Data safety)** 양식
- **타깃 API 레벨**: 프리셋 `target_sdk=35`. 플레이의 신규 앱 타깃 API 요구는
  매년 오르니, 등록 직전 Play Console이 요구하는 최신 레벨을 확인하고 필요시
  `target_sdk` 상향(현 설정은 2024~25 기준 안전선).

---

## 6. 자주 막히는 곳

- **"웹 zip 올렸는데 거부됨"** → 당연. .aab만 됩니다.
- **버전 코드 충돌** → 같은 `version/code` 재업로드 불가. 항상 +1.
- **서명 안 된 빌드 거부** → 4-A에서 Debug 체크가 켜져 있었음. 해제 후 재빌드.
- **AAB 대신 APK가 나옴** → 프리셋 `export_format`이 0으로 되돌아간 것. 1(AAB).
- **업로드 키 분실** → Play Console에서 업로드 키 재설정 요청 가능(앱 서명 키는
  구글이 보관하므로 앱은 안 죽음). 그래도 .jks는 백업하세요.

---

## 부록: 지금 상태 요약

| 항목 | 상태 |
|---|---|
| 비주얼(CEL 2.5D, 적 포함) | ✅ 적용·웹 재빌드 완료 |
| Netlify(웹) | ✅ `dist/` 갱신, 커밋+푸시로 배포 |
| Android 프리셋 | ✅ AAB+gradle로 전환(이 작업) |
| Android SDK/빌드템플릿 | ⬜ 본인 머신에서 2번 수행 |
| 업로드 keystore | ⬜ 본인이 1번 수행(비밀) |
| 서명된 .aab | ⬜ 본인이 4번 수행 |
| Play Console 등록 | ⬜ 5번 |

git 커밋은 사람이 합니다. `export_presets.cfg` 변경은 커밋 대상이지만,
keystore 경로/비밀번호가 cfg에 들어갔다면 커밋 전에 비워 두세요.
