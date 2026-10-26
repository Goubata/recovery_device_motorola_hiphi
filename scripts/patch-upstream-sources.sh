#!/usr/bin/env bash
# Invoke from the synced Android source root, before building.
set -euo pipefail
flavor=${1:?Usage: patch-upstream-sources.sh twrp|orangefox}
case "$flavor" in
    twrp|orangefox) ;;
    *) exit 2 ;;
esac

patches=$(cd "$(dirname "$0")/source-patches" && pwd)

# Apply a patch to a git project once; a re-run finds it already applied.
apply_once() {
    local project=$1 patch=$2
    if git -C "$project" apply --reverse --check "$patch" 2>/dev/null; then
        echo "Already applied: $(basename "$patch")"
    else
        git -C "$project" apply --whitespace=nowarn "$patch"
        echo "Applied: $(basename "$patch")"
    fi
}

# TWRP android-14.1 bootable/recovery does not compile with crypto against
# the android-14.1 vold: libtar uses the fscrypt API of "libtar: dynamically
# choose fscrypt policy [1/2]" (97b849918) whose vold half exists only on
# android-12.1, and partition code still calls full-disk-encryption helpers
# that the Android 14 vold removed. Revert 97b849918 and drop the FDE-only
# calls, matching what OrangeFox fox_14.1 ships. FBE decryption is unchanged.
if [[ "$flavor" == twrp ]]; then
    apply_once bootable/recovery "$patches/twrp-bootable_recovery-a14-vold.patch"
fi

# TeamWin 54596c60b ("recovery: correct library names for 14") renamed the
# packaged libraries to the Android 14 "-ndk" AIDL backend, but left the
# link lines in these makefiles on the removed "-ndk_platform" backend.
# Soong no longer generates those modules, so ninja cannot load the graph.
if [[ "$flavor" == twrp ]]; then
    for mk in bootable/recovery/Android.mk bootable/recovery/libtar/Android.mk; do
        if grep -q -- '-ndk_platform\b' "$mk"; then
            # libvold is compiled against keystore2_use_latest_aidl_ndk_shared
            # (V4); link the same version it was built with, as OrangeFox does.
            sed -i -e 's/android\.system\.keystore2-V1-ndk_platform\b/android.system.keystore2-V4-ndk/g' \
                -e 's/-ndk_platform\b/-ndk/g' "$mk"
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
