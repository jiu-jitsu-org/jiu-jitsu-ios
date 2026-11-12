#!/bin/sh
# Xcode Cloud가 레포를 clone한 직후 실행한다. 워크스페이스 위치(JiuJitsuConnect/) 옆의 ci_scripts/에 있어야 한다.
# 하는 일: 시크릿 파일 배치 → tuist 설치 → 의존성 설치 → 프로젝트 생성
#
# Xcode Cloud 워크플로 환경 변수 (Secret으로 표시)
#   SECRETS_XCCONFIG_BASE64          Configs/Secrets.xcconfig 내용 (base64)
#   GOOGLE_SERVICE_INFO_PLIST_BASE64 Secrets/GoogleService-Info.plist 내용 (base64)
#   만들기: base64 -i Configs/Secrets.xcconfig | pbcopy
set -eu

# mise.toml 핀(4.46.1)으로 generate하면 빌드가 깨져서 실빌드 확인된 버전을 쓴다 (CLAUDE.md §10.5)
TUIST_VERSION="4.203.3"

PROJECT_DIR="$CI_PRIMARY_REPOSITORY_PATH/JiuJitsuConnect"
cd "$PROJECT_DIR"

# 1) 시크릿
: "${SECRETS_XCCONFIG_BASE64:?Xcode Cloud 환경 변수 SECRETS_XCCONFIG_BASE64가 없습니다}"
: "${GOOGLE_SERVICE_INFO_PLIST_BASE64:?Xcode Cloud 환경 변수 GOOGLE_SERVICE_INFO_PLIST_BASE64가 없습니다}"
mkdir -p Configs Secrets
printf '%s' "$SECRETS_XCCONFIG_BASE64" | base64 --decode > Configs/Secrets.xcconfig
printf '%s' "$GOOGLE_SERVICE_INFO_PLIST_BASE64" | base64 --decode > Secrets/GoogleService-Info.plist

# 2) 매크로(TCA 등)·패키지 플러그인은 Xcode Cloud에서 신뢰 확인 창을 띄울 수 없어 검증을 건너뛴다
defaults write com.apple.dt.Xcode IDESkipMacroFingerprintValidation -bool YES
defaults write com.apple.dt.Xcode IDESkipPackagePluginFingerprintValidatation -bool YES

# 3) tuist
curl -fsSL https://mise.run | sh
export PATH="$HOME/.local/bin:$PATH"
mise trust "$PROJECT_DIR/mise.toml"
mise install "tuist@$TUIST_VERSION"

mise exec "tuist@$TUIST_VERSION" -- tuist install
mise exec "tuist@$TUIST_VERSION" -- tuist generate --no-open
