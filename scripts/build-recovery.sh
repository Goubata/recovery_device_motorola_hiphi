#!/usr/bin/env bash
# Invoke from the synced Android source root.
set -eo pipefail
flavor=${1:?Usage: build-recovery.sh twrp|orangefox}
case "$flavor" in
    twrp) ;;
    orangefox)
        source device/motorola/hiphi/scripts/orangefox-config.sh
        ;;
    *) exit 2 ;;
esac
# Required by the official minimal recovery manifest; unused AOSP tests are absent.
export ALLOW_MISSING_DEPENDENCIES=true
export LC_ALL=C
source build/envsetup.sh
lunch twrp_hiphi-ap2a-eng
# Keep going after a failed action so one CI run reports every failure.
export NINJA_ARGS="${NINJA_ARGS:--k 0}"
mka recoveryimage -j"${BUILD_JOBS:-2}"
image=out/target/product/hiphi/recovery.img
test -s "$image"
size=$(stat -c %s "$image")
(( size <= 104857600 )) || { echo 'Recovery exceeds the physical partition'; exit 1; }
