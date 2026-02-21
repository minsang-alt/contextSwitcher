#!/bin/bash
set -e

APP_NAME="ContextSwitcher"
REPO="minsang-alt/contextSwitcher"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# 버전 인자 확인
VERSION="$1"
if [ -z "$VERSION" ]; then
    # Info.plist에서 현재 버전 읽기
    CURRENT=$(defaults read "${PROJECT_DIR}/ContextSwitcher/Resources/Info.plist" CFBundleShortVersionString)
    echo "사용법: ./scripts/release.sh <version>"
    echo "  예시: ./scripts/release.sh 1.1.0"
    echo ""
    echo "현재 버전: ${CURRENT}"
    exit 1
fi

TAG="v${VERSION}"
DMG_NAME="${APP_NAME}-${VERSION}-arm64.dmg"
DMG_PATH="/tmp/${DMG_NAME}"

# 이미 존재하는 태그인지 확인
if gh release view "$TAG" --repo "$REPO" &>/dev/null; then
    echo "ERROR: ${TAG} 릴리즈가 이미 존재합니다."
    exit 1
fi

# 1. Info.plist 버전 업데이트
echo "==> 버전 업데이트: ${VERSION}"
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString ${VERSION}" \
    "${PROJECT_DIR}/ContextSwitcher/Resources/Info.plist"

# 2. README 다운로드 링크 업데이트
sed -i '' "s/ContextSwitcher-[0-9.]*-arm64\.dmg/ContextSwitcher-${VERSION}-arm64.dmg/g" \
    "${PROJECT_DIR}/README.md"

# 3. 빌드 (install.sh 재사용)
echo "==> 빌드 중..."
"${SCRIPT_DIR}/install.sh"

# 4. DMG 생성
echo "==> ${DMG_NAME} 생성 중..."
rm -f "$DMG_PATH"
hdiutil create -volname "$APP_NAME" \
    -srcfolder "/Applications/${APP_NAME}.app" \
    -ov -format UDZO \
    "$DMG_PATH"

echo "==> DMG 크기: $(du -h "$DMG_PATH" | cut -f1)"

# 5. 변경사항 커밋
echo "==> 버전 커밋..."
git add "${PROJECT_DIR}/ContextSwitcher/Resources/Info.plist" "${PROJECT_DIR}/README.md"
git commit -m "Bump version to ${VERSION}" || true
git push

# 6. GitHub Release 생성
echo "==> GitHub Release ${TAG} 생성 중..."
gh release create "$TAG" "$DMG_PATH" \
    --repo "$REPO" \
    --title "${TAG}" \
    --generate-notes

echo ""
echo "==> 릴리즈 완료!"
echo "    https://github.com/${REPO}/releases/tag/${TAG}"