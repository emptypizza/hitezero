# HiteZero — AAB/APK 자동 빌드 (GitHub Actions)

> 직접 못 굽는 환경(Godot/SDK 없음)을 우회: **GitHub Actions가 서명된 AAB+APK를 뽑아
> 다운로드 아티팩트로 올려줍니다.** 워크플로: `.github/workflows/android.yml`.
> 너는 ① 키스토어를 시크릿으로 한 번 등록 → ② 버튼 누르기 → ③ 결과 내려받기. 끝.

---

## 1. (한 번만) 키스토어 시크릿 3개 등록

업로드 키는 `new_upload_key.jks`(가이드 `google_play_release.md` 1번). 본인 머신에서:

```bash
# alias 확인 (필요시 비밀번호 입력)
keytool -list -v -keystore new_upload_key.jks    # "Alias name:" 메모

# 키스토어를 base64 텍스트로 변환 (GitHub 시크릿은 바이너리 불가)
base64 -w0 new_upload_key.jks > key.b64           # macOS면: base64 -i new_upload_key.jks -o key.b64
```

GitHub → 레포 **Settings → Secrets and variables → Actions → New repository secret** 로 3개:

| 시크릿 이름 | 값 |
|---|---|
| `ANDROID_KEYSTORE_BASE64` | `key.b64` 파일 내용 전체 |
| `ANDROID_KEY_ALIAS` | 위에서 확인한 alias |
| `ANDROID_KEYSTORE_PASSWORD` | 키스토어 비밀번호 |

> ⚠️ 키 비밀번호와 키스토어 비밀번호가 **다르면** 알려줘 — 워크플로에 한 줄 더 넣어야 함.
> ⚠️ `.jks`/`key.b64`는 절대 깃에 올리지 마(.gitignore에 이미 막아둠).

---

## 2. (한 번만) Godot 버전 맞추기

`.github/workflows/android.yml` 상단:
```yaml
env:
  GODOT_VERSION: "4.6.0"
...
    container:
      image: barichello/godot-ci:4.6.0
```
**둘 다 네 에디터의 정확한 4.6.x로 맞춰라**(예: 4.6.1). 익스포트 템플릿은 버전 잠금이라
안 맞으면 "export templates version mismatch"로 실패한다. 이미지 태그가 없으면
[barichello/godot-ci 태그 목록](https://hub.docker.com/r/barichello/godot-ci/tags)에서 가장
가까운 4.6.x로.

---

## 3. 실행 → 다운로드

- GitHub → **Actions** 탭 → 왼쪽 **"Android (AAB + APK)"** → **Run workflow** 클릭
  (또는 `git tag v1.0.0 && git push --tags`)
- 끝나면 그 실행 페이지 하단 **Artifacts → `hitezero-android`** 다운로드
  → 안에 `hitezero.aab`(플레이용) + `hitezero.apk`(사이드로드 테스트용)

---

## 4. 받은 다음

- **`hitezero.aab`** → Play Console 내부 테스트 트랙에 업로드(제출 답안: `play_console_submission.md`)
- **`hitezero.apk`** → 폰에 직접 설치해 빠른 동작 확인(플레이 제출엔 안 씀)

---

## 5. 첫 실행이 빨갛게 나면 (CI 안드로이드는 1~2번 다듬는 게 정상)

| 증상 | 원인/조치 |
|---|---|
| 이미지 pull 실패 | `barichello/godot-ci:4.6.0` 태그 없음 → 2번에서 실제 4.6.x 태그로 변경 |
| `export templates ... mismatch` | `GODOT_VERSION`이 에디터 버전과 불일치 → 정확히 맞춤 |
| `Keystore ... not found` / 서명 실패 | 시크릿 3개 누락/오타, 또는 키 비번≠스토어 비번 |
| `Android build template not installed` | (워크플로가 설치하지만) 실패 시 로그 첨부해줘 |
| `No package name` 등 | 프리셋 `package/unique_name=com.gghf.hitezero` 확인 |

> Actions 로그(빨간 스텝) 캡처해서 보내면 내가 워크플로 고쳐줄게. 한 번 초록 만들면
> 이후엔 버튼만 누르면 매번 자동으로 뽑힌다.
