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

# Gene - Oct, 07, 2026: Enhanced release script to sign binaries with Developer ID Application, enable Hardened Runtime, sign DMG, and automate Apple Notarization & stapling
# Previous implementation:
# mkdir -p "${DIST_DIR}"
# 
# echo "==> Packaging ${DIST_DIR}/batterie-macos.zip..."
# ditto -c -k --sequesterRsrc --keepParent "${APP_PATH}" "${DIST_DIR}/batterie-macos.zip"
# 
# echo "==> Packaging ${DIST_DIR}/batterie-macos.dmg..."
# DMG_TEMP="${DIST_DIR}/dmg_temp"
# rm -rf "${DMG_TEMP}"
# mkdir -p "${DMG_TEMP}"
# cp -R "${APP_PATH}" "${DMG_TEMP}/"
# ln -s /Applications "${DMG_TEMP}/Applications"
# 
# hdiutil create -volname "Batterie" -srcfolder "${DMG_TEMP}" -ov -format UDZO "${DIST_DIR}/batterie-macos.dmg"
# rm -rf "${DMG_TEMP}"
# 
# echo "==> Build and packaging complete! Artifacts located in ${DIST_DIR}:"
# ls -lh "${DIST_DIR}"

SIGNING_IDENTITY="Developer ID Application: Gene Ray Medel (T7LB768N2Z)"
ENTITLEMENTS="${REPO_ROOT}/macos/Runner/Release.entitlements"
NOTARY_PROFILE="${NOTARY_PROFILE:-batterie-notary}"

echo "==> Code signing nested frameworks with Hardened Runtime..."
find "${APP_PATH}/Contents/Frameworks" -type d -name "*.framework" | while read -r framework; do
  echo "    Signing ${framework}..."
  codesign --force --verbose --options runtime --timestamp --sign "${SIGNING_IDENTITY}" "${framework}"
done

echo "==> Code signing main application bundle..."
codesign --force --verbose --options runtime --timestamp --entitlements "${ENTITLEMENTS}" --sign "${SIGNING_IDENTITY}" "${APP_PATH}"

echo "==> Verifying signature integrity..."
codesign --verify --deep --strict --verbose=2 "${APP_PATH}"

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

echo "==> Code signing DMG..."
codesign --force --sign "${SIGNING_IDENTITY}" --timestamp "${DIST_DIR}/batterie-macos.dmg"

# Check if notarytool profile is available for automated notarization
if xcrun notarytool history --keychain-profile "${NOTARY_PROFILE}" >/dev/null 2>&1; then
  echo "==> Submitting DMG to Apple Notary Service using profile '${NOTARY_PROFILE}'..."
  xcrun notarytool submit "${DIST_DIR}/batterie-macos.dmg" --keychain-profile "${NOTARY_PROFILE}" --wait
  
  echo "==> Stapling notarization ticket to DMG..."
  xcrun stapler staple "${DIST_DIR}/batterie-macos.dmg"
  xcrun stapler staple "${APP_PATH}"
  echo "==> Successfully notarized and stapled!"
else
  echo ""
  echo "==> NOTE: Apple Notary credentials profile '${NOTARY_PROFILE}' not found in Keychain."
  echo "    To enable automatic notarization, run once in your terminal:"
  echo "    xcrun notarytool store-credentials \"${NOTARY_PROFILE}\" --apple-id \"bluegene37@outlook.com\" --team-id \"T7LB768N2Z\" --password \"<your-app-specific-password>\""
  echo ""
fi

echo "==> Build and packaging complete! Artifacts located in ${DIST_DIR}:"
ls -lh "${DIST_DIR}"
