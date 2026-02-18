#!/bin/bash
set -e

APP_NAME="ContextSwitcher"
BUNDLE_DIR="/Applications/${APP_NAME}.app"
CONTENTS_DIR="${BUNDLE_DIR}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "==> Building ${APP_NAME} (release)..."
cd "$PROJECT_DIR"
swift build -c release 2>&1 | tail -5

BINARY_PATH="${PROJECT_DIR}/.build/release/${APP_NAME}"

if [ ! -f "$BINARY_PATH" ]; then
    echo "ERROR: Build failed, binary not found at ${BINARY_PATH}"
    exit 1
fi

echo "==> Creating app bundle at ${BUNDLE_DIR}..."

# 기존 앱 제거
if [ -d "$BUNDLE_DIR" ]; then
    rm -rf "$BUNDLE_DIR"
fi

mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

# 바이너리 복사
cp "$BINARY_PATH" "$MACOS_DIR/${APP_NAME}"

# Info.plist 복사
cp "${PROJECT_DIR}/ContextSwitcher/Resources/Info.plist" "$CONTENTS_DIR/Info.plist"

# 아이콘이 있으면 복사
if [ -f "${PROJECT_DIR}/ContextSwitcher/Resources/AppIcon.icns" ]; then
    cp "${PROJECT_DIR}/ContextSwitcher/Resources/AppIcon.icns" "$RESOURCES_DIR/AppIcon.icns"
fi

# entitlements (Accessibility 권한용)
cat > "/tmp/${APP_NAME}-entitlements.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.app-sandbox</key>
    <false/>
</dict>
</plist>
EOF

# ad-hoc 서명
echo "==> Signing app bundle..."
codesign --force --deep --sign - \
    --entitlements "/tmp/${APP_NAME}-entitlements.plist" \
    "$BUNDLE_DIR"

rm "/tmp/${APP_NAME}-entitlements.plist"

# 접근성 권한 리셋 (재빌드 시 서명이 바뀌므로 필요)
echo "==> Resetting accessibility permission..."
tccutil reset Accessibility com.minsang.ContextSwitcher 2>/dev/null || true

# 실행 중이면 종료 후 재시작
if pgrep -x "$APP_NAME" > /dev/null; then
    echo "==> Restarting ${APP_NAME}..."
    pkill -x "$APP_NAME"
    sleep 0.5
fi

open "$BUNDLE_DIR"
echo ""
echo "==> Done! ${APP_NAME}.app installed and launched."
echo ""
echo "⚠️  재빌드 후에는 손쉬운 사용 권한을 다시 설정해야 합니다:"
echo "    시스템 설정 → 개인정보 보호 및 보안 → 손쉬운 사용"
echo "    → ContextSwitcher OFF → 다시 ON"
