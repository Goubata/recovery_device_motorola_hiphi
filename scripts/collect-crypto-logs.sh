#!/system/bin/sh
# Run in recovery: adb shell sh /tmp/collect-crypto-logs.sh > hiphi-crypto.txt
# Does not read keys, credentials, or locksettings databases.
echo '=== Recovery log ==='
cat /tmp/recovery.log
echo '=== HAL service status ==='
getprop | grep -E 'init.svc.*(key|gate|qsee|servicemanager)|crypto|keymaster_ver|security_patch|ro.boot.slot|ro.boot.hardware.sku'
echo '=== Binder HALs ==='
service list
lshal 2>/dev/null
echo '=== ROM encryption configuration ==='
for f in /vendor/etc/fstab.* /odm/etc/fstab.* /etc/additional.fstab; do
    [ -f "$f" ] && { echo "$f"; cat "$f"; }
done
echo '=== Kernel crypto errors ==='
dmesg | grep -iE 'fscrypt|dm-default-key|qsee|keymint|keymaster|f2fs|ext4' | tail -200
echo '=== Logcat ==='
logcat -b all -d -t 1000
