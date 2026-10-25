#!/usr/bin/env bash
# Invoke from the synced Android source root.
set -eo pipefail
flavor=${1:?Usage: build-recovery.sh twrp|orangefox}
case "$flavor" in
    twrp) ;;
    orangefox)
        export FOX_BUILD_DEVICE=hiphi
        export OF_MAINTAINER=Goubata
        export FOX_VARIANT=AOSP
        ;;
    *) exit 2 ;;
esac
unset ALLOW_MISSING_DEPENDENCIES
export LC_ALL=C
source build/envsetup.sh
lunch twrp_hiphi-eng
mka recoveryimage -j"${BUILD_JOBS:-4}"
image=out/target/product/hiphi/recovery.img
test -s "$image"
size=$(stat -c %s "$image")
(( size <= 104857600 )) || { echo 'Recovery exceeds the physical partition'; exit 1; }
