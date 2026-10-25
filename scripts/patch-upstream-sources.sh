#!/usr/bin/env bash
# Invoke from the synced Android source root, before building.
set -euo pipefail
flavor=${1:?Usage: patch-upstream-sources.sh twrp|orangefox}
case "$flavor" in
    twrp|orangefox) ;;
    *) exit 2 ;;
esac

# TeamWin 54596c60b ("recovery: correct library names for 14") renamed the
# packaged libraries to the Android 14 "-ndk" AIDL backend, but left the
# link lines in these makefiles on the removed "-ndk_platform" backend.
# Soong no longer generates those modules, so ninja cannot load the graph.
if [[ "$flavor" == twrp ]]; then
    for mk in bootable/recovery/Android.mk bootable/recovery/libtar/Android.mk; do
        if grep -q -- '-ndk_platform\b' "$mk"; then
            sed -i 's/-ndk_platform\b/-ndk/g' "$mk"
            echo "Patched AIDL backend names in $mk"
        fi
    done
fi

# Fail early if any recovery build input still names the removed backend.
leftover=$(grep -rln --include=Android.mk --include=Android.bp --include='*.go' -- '-ndk_platform\b' \
    bootable/recovery system/vold system/security vendor/twrp device/qcom/twrp-common 2>/dev/null || true)
if [[ -n "$leftover" ]]; then
    echo 'Build inputs still reference *-ndk_platform modules:'
    echo "$leftover"
    exit 1
fi
echo 'No build input references *-ndk_platform modules.'
