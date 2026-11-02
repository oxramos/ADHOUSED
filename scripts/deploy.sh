#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT="$ROOT_DIR/ADHOUSED.xcodeproj"
SCHEME="ADHOUSED"
DERIVED_DATA="$ROOT_DIR/.derivedData-device"
ARCHIVE_PATH="$ROOT_DIR/.build-release/ADHOUSED.xcarchive"
EXPORT_PATH="$ROOT_DIR/.build-release/Export"
EXPORT_OPTIONS="$ROOT_DIR/Config/ExportOptions-AppStore.plist"
BUNDLE_ID="com.oxramos.adhoused"
DEFAULT_DEVICE_UDID="00008150-0005754E1A87801C"

MODE="${1:-both}"

AUTH_ARGS=()
if [[ -n "${ASC_KEY_PATH:-}" && -n "${ASC_KEY_ID:-}" && -n "${ASC_ISSUER_ID:-}" ]]; then
    echo "▸ Using App Store Connect API Key ($ASC_KEY_ID)"
    AUTH_ARGS=(
        -authenticationKeyPath "$ASC_KEY_PATH"
        -authenticationKeyID "$ASC_KEY_ID"
        -authenticationKeyIssuerID "$ASC_ISSUER_ID"
    )
fi

deploy_device() {
    local device_id="${DEVICE_UDID:-$DEFAULT_DEVICE_UDID}"
    echo "▸ Ensuring Xcode.app has refreshed provisioning profiles for $BUNDLE_ID..."
    open -g -a /Applications/Xcode.app "$PROJECT" || true

    echo "▸ Building & signing ADHOUSED for physical iPhone ($device_id)..."
    xcodebuild \
        -project "$PROJECT" \
        -scheme "$SCHEME" \
        -configuration Release \
        -destination "platform=iOS,id=$device_id" \
        -derivedDataPath "$DERIVED_DATA" \
        "${AUTH_ARGS[@]}" \
        build

    local app_path="$DERIVED_DATA/Build/Products/Release-iphoneos/ADHOUSED.app"
    echo "▸ Installing $app_path onto iPhone ($device_id)..."
    xcrun devicectl device install app --device "$device_id" "$app_path"

    echo "▸ Launching $BUNDLE_ID on iPhone (if unlocked)..."
    xcrun devicectl device process launch --device "$device_id" "$BUNDLE_ID" || \
        echo "ℹ App is installed! Unlock your iPhone and tap ADHOUSED on your Home Screen."
    echo "✓ Installed on iPhone!"
}

upload_testflight() {
    rm -rf "$ARCHIVE_PATH" "$EXPORT_PATH"
    mkdir -p "$(dirname "$ARCHIVE_PATH")"

    echo "▸ Archiving Release build for App Store Connect / TestFlight..."
    xcodebuild \
        -project "$PROJECT" \
        -scheme "$SCHEME" \
        -configuration Release \
        -destination "generic/platform=iOS" \
        -archivePath "$ARCHIVE_PATH" \
        -allowProvisioningUpdates \
        "${AUTH_ARGS[@]}" \
        archive

    echo "▸ Exporting & uploading IPA directly to App Store Connect / TestFlight..."
    xcodebuild \
        -exportArchive \
        -archivePath "$ARCHIVE_PATH" \
        -exportPath "$EXPORT_PATH" \
        -exportOptionsPlist "$EXPORT_OPTIONS" \
        -allowProvisioningUpdates \
        "${AUTH_ARGS[@]}"

    echo "✓ Uploaded to App Store Connect / TestFlight!"
}

case "$MODE" in
    device)
        deploy_device
        ;;
    testflight)
        upload_testflight
        ;;
    both)
        deploy_device
        upload_testflight
        ;;
    *)
        echo "Usage: $0 [device|testflight|both]"
        exit 1
        ;;
esac
