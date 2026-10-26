# Compatibility target: Android 14, 15, 16 and 17

Goal: one hiphi recovery configuration usable across these ROM generations,
where the kernel, vendor firmware and encryption policy remain compatible.
**No version has passed a hardware decryption test in this project yet.**

| Installed ROM | Source audit | Build | Metadata/DE | Primary-user CE | Work/private profiles |
|---|---|---|---|---|---|
| Android 14 | AOSP r1 compared | CI pass (TWRP + OrangeFox) | Not tested | Not tested | Not tested |
| Android 15 | AOSP r1 compared | Same recovery candidate | Not tested | Not tested | Not tested |
| Android 16 | AOSP r1 compared | Same recovery candidate | Not tested | Not tested | Not tested |
| Android 17 | AOSP r1 compared | Same recovery candidate | Not tested | Not tested | Changed upstream; not implemented/tested |

Build base version and installed ROM version are different things. Compiling
against Android 14.1 does not alone establish compatibility with any installed ROM.

## Source observations (2026-10-25)

Compared `SyntheticPasswordManager.java`, `SyntheticPasswordCrypto.java`, and
`system/vold/KeyStorage.cpp` at each AOSP `android-14.0.0_r1` through
`android-17.0.0_r1` tag. This is an audit of those releases, not all QPRs or custom
ROM patches.

- The primary-user synthetic password remains version 3. The FBE subkey derivation
  still uses SP800 with the `fbe-key` personalization. The selected TeamWin vold
  source contains the v3 derivation path. This is evidence for possible shared
  support, not evidence of a successful decrypt.
- PasswordData keeps serialized scrypt parameters. Android 17 changes the default
  cost; recovery must use the parameters saved with the credential. TeamWin reads
  these parameters rather than hardcoding the Android 14 cost.
- Weaver service handling differs by release and vendor. OrangeFox's 14.1 sync
  includes its own Weaver patches; verify a ROM's actual vendor HAL and services.
- Android 17 adds a new unified-profile credential storage path. Do not infer
  work/private-profile support from primary-user internal-storage access.
- Android 17 removes legacy wrapped-storage helper functions from the reviewed
  vold file. This device originally uses wrappedkey_v0; retain the recovery
  upstream's legacy support and read the installed vendor fstab. Never globally
  remove wrapping flags to claim cross-ROM support.

Sources:

- [Android 14 SyntheticPasswordManager](https://android.googlesource.com/platform/frameworks/base/+/refs/tags/android-14.0.0_r1/services/core/java/com/android/server/locksettings/SyntheticPasswordManager.java)
- [Android 15 SyntheticPasswordManager](https://android.googlesource.com/platform/frameworks/base/+/refs/tags/android-15.0.0_r1/services/core/java/com/android/server/locksettings/SyntheticPasswordManager.java)
- [Android 16 SyntheticPasswordManager](https://android.googlesource.com/platform/frameworks/base/+/refs/tags/android-16.0.0_r1/services/core/java/com/android/server/locksettings/SyntheticPasswordManager.java)
- [Android 17 SyntheticPasswordManager](https://android.googlesource.com/platform/frameworks/base/+/refs/tags/android-17.0.0_r1/services/core/java/com/android/server/locksettings/SyntheticPasswordManager.java)
- [Android 17 SyntheticPasswordCrypto](https://android.googlesource.com/platform/frameworks/base/+/refs/tags/android-17.0.0_r1/services/core/java/com/android/server/locksettings/SyntheticPasswordCrypto.java)
- [Android 17 KeyStorage](https://android.googlesource.com/platform/system/vold/+/refs/tags/android-17.0.0_r1/KeyStorage.cpp)
- [AOSP FBE configuration](https://source.android.com/docs/security/features/encryption/file-based)

## hiphi ROM configuration cross-check

The hiphi lineage-24.0 device tree at 9dc514fa93a7c16764af10ad244961b29c073204
inherits sm8475-common. Its common fstab at
ae57de31cb45c021ce78dc0790dc43577e69278c still uses F2FS, fscrypt v2,
AES-256-XTS/AES-256-CTS, inlinecrypt_optimized and wrappedkey_v0 for /data,
and AES-256-XTS:wrappedkey_v0 for metadata encryption. These match this
recovery's fallback data encryption policy. This checks configuration only;
it does not verify KeyMint, firmware compatibility, boot or decryption.

The newer ROM tree also has different super-partition build dimensions from
the old recovery tree. This project builds only recovery.img, retains the
upstream recovery partition size, and relies on runtime logical-partition
metadata. It does not generate or flash super.img. Verify actual partition
sizes before extending the build to other image types.

- [hiphi Android 17 device configuration](https://github.com/motorola-sm8450-devs/android_device_motorola_hiphi/blob/9dc514fa93a7c16764af10ad244961b29c073204/BoardConfig.mk)
- [Inherited common fstab](https://github.com/LineageOS/android_device_motorola_sm8475-common/blob/ae57de31cb45c021ce78dc0790dc43577e69278c/init/fstab.qcom)

## Recording a result

For each test, record ROM name/build/version, hiphi SKU, firmware/vendor version,
kernel, filesystem/encryption policy, recovery flavor/commit/SHA256, lock type,
and separate metadata/DE, primary CE and additional-profile outcomes. Include
freshly installed and upgraded ROM cases where available. A green CI build is
never a hardware compatibility result. Use the log collector in `scripts/` when
any stage fails. Do not mark all Android versions or all ROMs supported based on
one Android 14 result.
