# Android 14+ recovery bring-up (experimental)

This is a separate hiphi recovery project. Upstream device tree:
https://github.com/motorola-sm8450-devs/recovery_device_motorola_hiphi
Baseline: upstream twrp-13 b9f2700, with OrangeFox-specific settings from
fox_13 9453279. The first bring-up commit started from c92ac5f (twrp-12.1);
the follow-up imports every twrp-13 file difference except the release label.
Vendor blobs are the upstream Android 13 versions; the partition layout is retained.

## What changed

- Import the Android 13 branch's kernel modules, vendor/KeyMint libraries,
  task profiles, and Android 13 device fingerprints. Preserve fox_13's A/B recovery
  partition flags, supported device names, display geometry and notch layout,
  while dropping obsolete FOX_VERSION and setting minimal-manifest dependency mode
  explicitly in the shared build script.
- TWRP workflow uses the official minimal `twrp-14.1` manifest (including its
  matching vold, keystore and legacy wrapped-key support). OrangeFox uses its
  official sync script with `--branch 14.1`, not a TWRP build with a renamed image.
- Translate old Android `*-ndk_platform.so` dependencies to the same interface version's
  `*-ndk.so` in a disposable copy of the vendor blobs. The repository's original
  blobs remain unchanged. Private vendor AIDL library filenames stay unchanged.
  Package KeyMint V1, SecureClock V1 and SharedSecret V1
  explicitly; use the Android 14 vibrator NDK module name.
- Fix the truncated EROFS system AVB key filename in recovery.fstab.
- Use the official minimal-manifest ALLOW_MISSING_DEPENDENCIES=true setting;
  validate the generated crypto ELF dependency closure before publishing artifacts.
  The earlier strict setting rejected unused AOSP test modules during Soong analysis.
- Save source revisions, sync/build logs, dependency checks, images and hashes.
- TWRP 14.1 upstream (TeamWin 54596c60b) renamed its packaged keystore AIDL
  libraries to `-ndk` but left `Android.mk` and `libtar/Android.mk` linking the
  removed `-ndk_platform` modules, so ninja failed before compiling. CI rewrites
  those link names after sync (`scripts/patch-upstream-sources.sh`) and fails if
  any recovery build input still references `-ndk_platform`.
- `prebuilt/kernel` is an empty placeholder. Android 14 QPR extracts the kernel
  version for VINTF and the userfaultfd-GC build property; the device disables
  both (`PRODUCT_OTA_ENFORCE_VINTF_KERNEL_REQUIREMENTS`, `PRODUCT_ENABLE_UFFD_GC`).
- TeamWin/OrangeFox 14 init has no `vendor_load_properties()` hook, so
  libinit_hiphi was never called. Per-SKU device/model/fingerprint props moved to
  `hiphi-props.sh` (resetprop, `on init`). Removing BoardConfig's
  `TARGET_RECOVERY_DEVICE_MODULES := libinit_hiphi` also stops it from wiping the
  device.mk KeyMint/vibrator module list.
- Density 400 made build/make generate the stock AOSP recovery text PNGs with
  a host Java tool that needs guava (absent from the minimal manifest).
  `TARGET_RECOVERY_UI_SCREEN_WIDTH :=` disables those unused images.
- Android 14 moved IRemotelyProvisionedComponent and its parcelables out of
  KeyMint V1 into `android.hardware.security.rkp` V1 (same frozen API). The
  Android 12 KeyMint service and libqtikeymint would fail to link; the blob
  preparation adds `android.hardware.security.rkp-V1-ndk.so` and the device
  packages it. Unused Wi-Fi keystore blobs (missing Android 14 deps) removed.
- TWRP links keystore2 V4 (the version libvold is compiled with), like OrangeFox.
- TWRP android-14.1 `bootable/recovery` does not compile with crypto against the
  android-14.1 vold: libtar uses the API of 97b849918 ("dynamically choose
  fscrypt policy [1/2]") whose vold half exists only on android-12.1, and the
  partition code still calls FDE helpers removed from the Android 14 vold.
  `scripts/source-patches/twrp-bootable_recovery-a14-vold.patch` reverts
  97b849918 and drops the unreachable FDE calls, matching OrangeFox fox_14.1.
  The FBE decryption path is unchanged. The patch also links libvold's own
  dependencies into libtar/recovery and makes `twrp_ramdisk` require
  `task_profiles.json`, which its post-install step copies (a build-order race).
- TWRP 14.1 packages only the Android 12 keystore AIDL libraries, but its
  Android 14 keystore2 needs KeyMint V3, RKP V3, suspend, confirmationui and
  aaid libraries; without them keystore2 cannot start. device.mk packages them.
- The ramdisk check resolves every ELF's NEEDED closure and every executable's
  undefined dynamic symbols, including the patchelf-translated vendor blobs.

## What is not established

Both flavors build in CI as of 2026-10-26 (TWRP run 40268460044 at d804057,
OrangeFox run 40266096685 at 24d2fb3); every ELF in both final ramdisks has its
dependencies present and executable symbols resolved. No hardware decryption
result is recorded yet. These changes
are a bring-up candidate, not proof that the reported Android 14 failure is fixed.
The old tree already enables FBE, metadata encryption, fscrypt v2, vendor-fstab
parsing and KeyMint. A version flag alone is not a decryption fix. Exact root cause
requires the failing recovery log and the ROM/vendor configuration.

The AIDL filename translation addresses library naming, not every possible ABI
change. CI checks dependency presence, not symbol resolution or successful TEE
communication. Android 15/16/17 and all custom ROMs are not automatically supported
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
Both current manifests use release configuration `ap2a`; the lunch target is
`twrp_hiphi-ap2a-eng` (product-release-variant).
Artifacts are experimental; a green build does not prove decryption works.
Hosted builds use two parallel jobs, a 6 GiB Go memory limit, 12 GiB extra swap
and periodic memory/disk diagnostics. An earlier OrangeFox run lost runner
communication during compilation, without a saved compiler error; its exact
cause is unconfirmed. Hosted runners may still run out of disk/RAM; for that case use an x86_64 Ubuntu 22.04
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
sideload and MTP separately. Record Android 14/15/16/17 results individually in [the compatibility matrix](COMPATIBILITY.md).
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
