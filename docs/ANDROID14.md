# Android 14+ recovery bring-up (experimental)

This is a separate hiphi recovery project. Upstream device tree:
https://github.com/motorola-sm8450-devs/recovery_device_motorola_hiphi
Baseline: c92ac5f (twrp-12.1). Original vendor blobs and partition layout are retained.

## What changed

- TWRP workflow uses the official minimal `twrp-14.1` manifest (including its
  matching vold, keystore and legacy wrapped-key support). OrangeFox uses its
  official sync script with `--branch 14.1`, not a TWRP build with a renamed image.
- Translate old `*-ndk_platform.so` dependencies to the same interface version's
  `*-ndk.so` in a disposable copy of the vendor blobs. The repository's original
  blobs remain unchanged. Package KeyMint V1, SecureClock V1 and SharedSecret V1
  explicitly; use the Android 14 vibrator NDK module name.
- Fix the truncated EROFS system AVB key filename in recovery.fstab.
- Stop hiding missing device dependencies with ALLOW_MISSING_DEPENDENCIES.
- Save source revisions, sync/build logs, dependency checks, images and hashes.

## What is not established

No successful build or hardware decryption result is recorded yet. These changes
are a bring-up candidate, not proof that the reported Android 14 failure is fixed.
The old tree already enables FBE, metadata encryption, fscrypt v2, vendor-fstab
parsing and KeyMint. A version flag alone is not a decryption fix. Exact root cause
requires the failing recovery log and the ROM/vendor configuration.

The AIDL filename translation addresses library naming, not every possible ABI
change. CI checks dependency presence, not symbol resolution or successful TEE
communication. Android 15/16 and all custom ROMs are not automatically supported
by an Android 14 recovery. Firmware, vendor HALs, synthetic-password changes,
wrapped-key policy and the kernel must be compatible. Do not strip wrappedkey_v0
or change encryption flags to make an incompatible encrypted filesystem mount.

The upstream 2099 patch/version overrides are retained for initial bring-up.
They are not an Android 14 fix or a guarantee against key upgrades. KeyMint may
upgrade key blobs; testing recovery is not guaranteed to leave encrypted metadata
unchanged. Do not change security patch overrides casually.

## Build

GitHub Actions: select **Build TWRP (14.1)** or
**Build OrangeFox (14.1 experimental)**, then **Run workflow** on
`android-14-recovery`. Both workflows are manual to avoid unnecessary builds.
Artifacts are experimental; a green build does not prove decryption works.
Hosted runners may run out of disk/RAM; for that case use an x86_64 Ubuntu 22.04
host with at least 16 GiB RAM and 150 GiB free storage and run the same commands.
Workflow source manifests record exact revisions for each individual build;
future runs intentionally follow maintained upstream branches.

Local TWRP example (requires repo and Android build prerequisites):

```bash
mkdir android && cd android
repo init --depth=1 -u https://github.com/minimal-manifest-twrp/platform_manifest_twrp_aosp.git -b twrp-14.1
repo sync -c -j4 --no-clone-bundle --no-tags
git clone -b android-14-recovery https://github.com/Goubata/recovery_device_motorola_hiphi.git device/motorola/hiphi
bash device/motorola/hiphi/scripts/prepare-a14-blobs.sh
bash device/motorola/hiphi/scripts/build-recovery.sh twrp
```

OrangeFox: sync to a separate absolute directory using
https://gitlab.com/OrangeFox/sync (`--branch 14.1`), clone the same device branch,
run the blob preparation, then `build-recovery.sh orangefox` from the source root.
OrangeFox 14.1 is an experimental base. Do not mix build output directories.

## Hardware validation still required

Record exact model/SKU, ROM and Android version, firmware/vendor version, kernel,
build artifact SHA256 and lock type. Test metadata/DE access first, then PIN,
pattern/password CE unlock and reading a known file in internal storage. Include
F2FS/EXT4 only where actually used by a supported ROM. Verify touch, reboot,
sideload and MTP separately. Record Android 14/15/16 results individually.
Do not format data, delete locksettings, disable encryption, or flash unrelated
partitions to work around a failed decrypt. Use a backed-up test device/data set.

From the failing recovery, collect:

```sh
adb pull /tmp/recovery.log
adb push scripts/collect-crypto-logs.sh /tmp/
adb shell sh /tmp/collect-crypto-logs.sh > hiphi-crypto.txt
```

The collector does not read key material, passwords or locksettings databases,
but logs may include personal paths and identifiers: review before sharing.
Look for missing ELF libraries/symbols, unavailable KeyMint/Gatekeeper services,
metadata mount failures, unsupported synthetic-password formats and key errors.
