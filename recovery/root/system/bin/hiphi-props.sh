#!/system/bin/sh
# Per-SKU device properties. The Android 14 TWRP/OrangeFox init has no
# vendor_load_properties() hook, so this replaces the former libinit_hiphi.
sku=$(getprop ro.boot.hardware.sku)
case "$sku" in
    XT2201-1)
        desc="hiphi-user 12 T1SH33.35-23-20-2 d71e3"
        fp="motorola/hiphi/hiphi:12/T1SHS33.35-23-20-2/d71e3:user/release-keys"
        device=hiphi; model="Motorola Edge 30 Pro" ;;
    XT2201-3)
        desc="hiphi-user 12 T1SH33.35-23-20-2 d71e3"
        fp="motorola/hiphi/hiphi:12/T1SHS33.35-23-20-2/d71e3:user/release-keys"
        device=hiphi; model="Motorola Edge Plus (2022)" ;;
    XT2201-4)
        desc="hiphi-user 12 T1SH33.35-23-20-2 d71e3"
        fp="motorola/hiphi/hiphi:12/T1SHS33.35-23-20-2/d71e3:user/release-keys"
        device=hiphi; model="Motorola Edge Plus 5G UW" ;;
    XT2201-2)
        desc="hiphic-user 12 S3SC32.7-42-20 02af5"
        fp="motorola/hiphic/hiphic:12/S3SC32.7-42-20/02af5:user/release-keys"
        device=hiphic; model="Motorola Edge X30" ;;
    XT2201-6)
        desc="hiphid-user 12 S3SF32.35-5-9 37351"
        fp="motorola/hiphid/hiphid:12/S3SF32.35-5-9/37351:user/release-keys"
        device=hiphid; model="Motorola Edge X30" ;;
    *)
        exit 0 ;;
esac

resetprop ro.build.description "$desc"
resetprop ro.build.fingerprint "$fp"
resetprop ro.build.product "$device"
resetprop ro.product.build.fingerprint "$fp"
resetprop ro.product.device "$device"
resetprop ro.product.name "$device"
resetprop ro.product.model "$model"
for part in odm odm_dlkm system vendor vendor_dlkm product system_ext; do
    resetprop "ro.product.$part.build.fingerprint" "$fp"
    resetprop "ro.product.$part.device" "$device"
    resetprop "ro.product.$part.name" "$device"
    resetprop "ro.product.$part.model" "$model"
done
exit 0
