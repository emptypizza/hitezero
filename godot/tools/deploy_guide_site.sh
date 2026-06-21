#!/usr/bin/env bash
# deploy_guide_site.sh — hitezero-guide.netlify.app(매뉴얼 허브 + APK 다운로드 안내)
# 를 docs/ 정본에서 재구성해 배포한다. APK 자체는 GitHub Releases가 호스팅하므로
# 이 배포는 가벼운 정적 HTML 몇 개뿐이다.
#
# 배경: 2026-06-21 86MB APK를 무료 팀(starofdark)에 반복 업로드하다 월 사용량
# 한도를 초과 → 새 배포가 Forbidden으로 차단됨. 사용주기는 매월 27일 전후 리셋.
# 리셋(≈2026-06-27) 이후 이 스크립트를 한 번 실행하면 랜딩의 APK 링크까지 반영된다.
#
# 사용:
#   bash godot/tools/deploy_guide_site.sh
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SITE_ID="d8e7aa04-f6a6-4db8-a478-f0d4c28e8428"   # hitezero-guide.netlify.app
OUT="$REPO_ROOT/dist/guide-site"
APK_URL="https://github.com/emptypizza/hitezero/releases/download/apk-testbuild-20260622/hitezero-v1.0.0.apk"

[[ -f "$REPO_ROOT/docs/manuals_index.html" ]] || { echo "ERROR: docs/manuals_index.html 없음" >&2; exit 1; }

echo "guide-site 재구성 → $OUT"
rm -rf "$OUT"; mkdir -p "$OUT/download"
cp "$REPO_ROOT/docs/manuals_index.html"                "$OUT/index.html"
cp "$REPO_ROOT/docs/google_play_registration_manual.html" "$OUT/"
cp "$REPO_ROOT/docs/google_admin_manual.html"             "$OUT/"
cp "$REPO_ROOT/docs/guide_download.html"                  "$OUT/download/index.html"

cat > "$OUT/netlify.toml" <<'TOML'
[build]
  publish = "."
TOML

echo "Netlify 배포 → site $SITE_ID"
if ! netlify deploy --prod --dir "$OUT" --site "$SITE_ID"; then
  cat >&2 <<'MSG'

배포 실패. 가장 흔한 원인은 무료 팀 월 사용량 한도(2026-06 초과분).
- 사용주기 리셋(≈매월 27일) 이후 재시도하세요.
- 상태 확인:  netlify api getAccount --data '{"account_id":"starofdark"}'
              → grace_topup_granted_at / current_usage_period_start 참고
MSG
  exit 1
fi

echo "배포 완료. 확인:"
echo "  https://hitezero-guide.netlify.app/            (랜딩 + 📱 APK 바)"
echo "  https://hitezero-guide.netlify.app/download/   (설치 안내)"
echo "  APK(GitHub): $APK_URL"
