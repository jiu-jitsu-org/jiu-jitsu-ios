#!/bin/sh
# 오픈소스 라이선스 고지(iOS 설정 앱 › OSS › 오픈소스 라이선스)를 다시 만든다 (#371).
#
#   sh scripts/update-licenses.sh          목록을 다시 만들고 입력 지문을 갱신 → 결과를 커밋
#   sh scripts/update-licenses.sh --hash   입력 지문만 출력 (빌드 단계가 목록이 낡았는지 볼 때 씀)
#
# 패키지는 Tuist/Package.resolved + 내려받은 소스(Tuist/.build, `tuist install`)에서 읽어 망 없이 돈다.
# 폰트처럼 패키지가 아닌 것은 Licenses/license_plist.yml에 적는다.
# 결과(Settings.bundle)는 커밋해 두어, LicensePlist가 없는 기기 · Xcode Cloud도 같은 목록으로 빌드한다.
set -eu

cd "$(dirname "$0")/.."

BUNDLE="Targets/App/Resources/Settings.bundle"
HASH_FILE="Licenses/inputs.sha256"

inputs_hash() {
    cat Tuist/Package.resolved Licenses/license_plist.yml Licenses/manual/* | shasum -a 256 | cut -d ' ' -f 1
}

if [ "${1:-}" = "--hash" ]; then
    inputs_hash
    exit 0
fi

export PATH="/opt/homebrew/bin:/usr/local/bin:${PATH}"
if ! command -v license-plist > /dev/null; then
    echo "license-plist가 없습니다: brew install licenseplist" >&2
    exit 1
fi
if [ ! -d Tuist/.build/checkouts ]; then
    echo "패키지 소스가 없습니다: tuist install 먼저" >&2
    exit 1
fi

# 뺀 패키지의 항목이 남지 않게 지난 결과를 지우고 새로 만든다 (Root.plist는 손으로 쓴 것이라 둔다)
rm -rf "$BUNDLE/com.mono0926.LicensePlist" "$BUNDLE/com.mono0926.LicensePlist.plist"
license-plist \
    --package-path Tuist/Package.swift \
    --package-sources-path Tuist/.build \
    --config-path Licenses/license_plist.yml \
    --output-path "$BUNDLE" \
    --suppress-opening-directory \
    > /dev/null
# 다음 실행을 건너뛰기 위한 LicensePlist 캐시 — 앱에 넣지 않는다
rm -f "$BUNDLE/com.mono0926.LicensePlist.latest_result.txt"

inputs_hash > "$HASH_FILE"
echo "오픈소스 라이선스 목록 갱신: $(ls "$BUNDLE/com.mono0926.LicensePlist" | wc -l | tr -d ' ')개"
