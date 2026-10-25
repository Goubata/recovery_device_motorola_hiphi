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
    while IFS= read -r needed; do
        if [[ "$needed" == *-ndk_platform.so ]]; then
            replacement=${needed/-ndk_platform.so/-ndk.so}
            printf '%s: %s -> %s\n' "$blob" "$needed" "$replacement"
            patchelf --replace-needed "$needed" "$replacement" "$blob"
        fi
    done < <(patchelf --print-needed "$blob")
done < <(find recovery/root/system/bin recovery/root/vendor -type f -print0)
