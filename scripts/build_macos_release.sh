#!/usr/bin/env bash
set -euo pipefail

# Build and package local macOS release for Batterie
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="${REPO_ROOT}/dist"
APP_PATH="${REPO_ROOT}/build/macos/Build/Products/Release/batterie.app"

echo "==> Building macOS release binary..."
cd "${REPO_ROOT}"
flutter build macos --release

if [ ! -d "${APP_PATH}" ]; then
  echo "Error: App bundle not found at ${APP_PATH}" >&2
  exit 1
fi

mkdir -p "${DIST_DIR}"

echo "==> Packaging ${DIST_DIR}/batterie-macos.zip..."
ditto -c -k --sequesterRsrc --keepParent "${APP_PATH}" "${DIST_DIR}/batterie-macos.zip"

echo "==> Packaging ${DIST_DIR}/batterie-macos.dmg..."
DMG_TEMP="${DIST_DIR}/dmg_temp"
rm -rf "${DMG_TEMP}"
mkdir -p "${DMG_TEMP}"
cp -R "${APP_PATH}" "${DMG_TEMP}/"
ln -s /Applications "${DMG_TEMP}/Applications"

hdiutil create -volname "Batterie" -srcfolder "${DMG_TEMP}" -ov -format UDZO "${DIST_DIR}/batterie-macos.dmg"
rm -rf "${DMG_TEMP}"

echo "==> Build and packaging complete! Artifacts located in ${DIST_DIR}:"
ls -lh "${DIST_DIR}"
