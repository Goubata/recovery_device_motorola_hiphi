#!/usr/bin/env bash
# Run only in the disposable device checkout used for a 14.1 build.
set -euo pipefail
cd "$(dirname "$0")/.."
command -v patchelf >/dev/null
# Android 14 uses the NDK AIDL backend. Keep the vendor HAL's original
# interface version; only translate the obsolete backend library filename.
while IFS= read -r -d '' blob; do
    magic=$(od -An -tx1 -N4 "$blob" | tr -d ' \n')
    [[ "$magic" == 7f454c46 ]] || continue
    # Kernel modules are relocatable ELF objects, not dynamic executables.
    readelf -h "$blob" | grep -Eq 'Type:.*(DYN|EXEC)' || continue
    needed_list=$(patchelf --print-needed "$blob")
    while IFS= read -r needed; do
        if [[ "$needed" == android.*-ndk_platform.so ]]; then
            replacement=${needed/-ndk_platform.so/-ndk.so}
            printf '%s: %s -> %s\n' "$blob" "$needed" "$replacement"
            patchelf --replace-needed "$needed" "$replacement" "$blob"
        fi
        # Android 14 moved IRemotelyProvisionedComponent and its parcelables from
        # KeyMint V1 into android.hardware.security.rkp V1 (identical frozen API).
        if [[ "$needed" == android.hardware.security.keymint-V1-ndk*.so ]] &&
            ! grep -qx 'android.hardware.security.rkp-V1-ndk.so' <<< "$needed_list"; then
            printf '%s: + android.hardware.security.rkp-V1-ndk.so\n' "$blob"
            patchelf --add-needed android.hardware.security.rkp-V1-ndk.so "$blob"
        fi
    done <<< "$needed_list"
done < <(find recovery/root/system/bin recovery/root/vendor -type f -print0)
