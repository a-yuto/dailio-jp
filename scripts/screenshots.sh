#!/bin/bash
#
# App Store スクリーンショットを自動生成する。
#
#   ./scripts/screenshots.sh
#
# ScreenshotUITests を必須 2 機種（iPhone 6.9" / iPad 13"）で実行し、
# xcresult から添付を取り出して screenshots/<機種>/NN-名前.png に整理する。
# 生成物は App Store Connect に手動アップロードする（リポジトリには含めない）。
#
set -euo pipefail

export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode-26.4.1.app/Contents/Developer}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
OUT="$ROOT/screenshots"

# Apple 現行必須: iPhone 6.9"（17 Pro Max）+ iPad 13"。小型機は自動縮小される。
DEVICES=(
  "iPhone 17 Pro Max"
  "iPad Pro 13-inch (M5)"
)

mkdir -p "$OUT"
for dev in "${DEVICES[@]}"; do
  slug="$(echo "$dev" | tr ' ' '_' | tr -d '()')"
  result="/tmp/shots_${slug}.xcresult"
  destdir="$OUT/$slug"
  rm -rf "$result" "$destdir"
  mkdir -p "$destdir"

  echo "▶ $dev — シミュレータ起動..."
  # コールドブート直後の xctrunner 起動失敗（FBSOpenApplication）を避けるため
  # 事前にブート完了まで待つ
  udid="$(xcrun simctl list devices available | grep -F "$dev (" | head -1 | sed -E 's/.*\(([0-9A-F-]{36})\).*/\1/')"
  if [ -n "${udid:-}" ]; then
    xcrun simctl boot "$udid" 2>/dev/null || true
    xcrun simctl bootstatus "$udid" 2>/dev/null || true
  fi

  echo "▶ $dev — UITest 実行中..."
  # 各ショットは独立テスト。失敗時は最大3回までリトライ（起動フレーク対策）
  xcodebuild test \
    -project dailio-jp.xcodeproj -scheme dailio-jp \
    -destination "platform=iOS Simulator,name=$dev" \
    -only-testing:dailio-jpUITests/ScreenshotUITests \
    -resultBundlePath "$result" \
    -retry-tests-on-failure -test-iterations 3 \
    -configuration Debug CODE_SIGNING_ALLOWED=NO >/dev/null || true

  tmpx="$(mktemp -d)"
  xcrun xcresulttool export attachments --path "$result" --output-path "$tmpx" >/dev/null
  python3 - "$tmpx" "$destdir" <<'PY'
import json, os, re, shutil, sys
src, dst = sys.argv[1], sys.argv[2]
manifest = json.load(open(os.path.join(src, "manifest.json")))
# manifest は新しい順。リトライで同名が複数出るので「最初に出た＝最新」を採用。
seen = set()
for entry in manifest:
    for a in entry.get("attachments", []):
        raw = a["suggestedHumanReadableName"]
        if not raw.endswith(".png"):
            continue  # スクショ以外（ログ等）は無視
        name = re.sub(r'_\d+(_[0-9A-Fa-f-]{36})?\.png$', '', raw)
        name += ".png"
        if name in seen:
            continue
        seen.add(name)
        shutil.copyfile(os.path.join(src, a["exportedFileName"]),
                        os.path.join(dst, name))
PY
  rm -rf "$tmpx"
  echo "  → $destdir"
  ls "$destdir"
done

echo
echo "完了。screenshots/ の PNG を App Store Connect にアップロードしてください。"
