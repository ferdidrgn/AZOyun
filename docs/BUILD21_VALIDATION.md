# Android bundle validation

Source: `e1ec4693c4a0b6fb21b37489282ddf16b5916a85`
AAB build: `44666860253`
Version code: `21`
SHA-256: `0f2dfce85428d13326a7f8fe0c453a0ddd6a9de04763b502e6d58009be8e3501`

Result: **PASS**

Bundle ZIP alignment requests 16 KB: **True**.
TV launcher present: **True**.
Touchscreen, fake touch and camera requirements checked in the compiled manifest.

| Native library | Minimum LOAD alignment | ELF result |
| --- | ---: | --- |
| `arm64-v8a/libapp.so` | 65536 | PASS |
| `arm64-v8a/libbarhopper_v3.so` | 16384 | PASS |
| `arm64-v8a/libdartjni.so` | 16384 | PASS |
| `arm64-v8a/libdatastore_shared_counter.so` | 16384 | PASS |
| `arm64-v8a/libflutter.so` | 65536 | PASS |
| `arm64-v8a/libimage_processing_util_jni.so` | 16384 | PASS |
| `arm64-v8a/libsurface_util_jni.so` | 16384 | PASS |
| `armeabi-v7a/libapp.so` | 16384 | 32-bit ABI |
| `armeabi-v7a/libbarhopper_v3.so` | 4096 | 32-bit ABI |
| `armeabi-v7a/libdartjni.so` | 16384 | 32-bit ABI |
| `armeabi-v7a/libdatastore_shared_counter.so` | 16384 | 32-bit ABI |
| `armeabi-v7a/libflutter.so` | 65536 | 32-bit ABI |
| `armeabi-v7a/libimage_processing_util_jni.so` | 16384 | 32-bit ABI |
| `armeabi-v7a/libsurface_util_jni.so` | 16384 | 32-bit ABI |
| `x86_64/libbarhopper_v3.so` | 16384 | 32-bit ABI |
| `x86_64/libdartjni.so` | 16384 | 32-bit ABI |
| `x86_64/libdatastore_shared_counter.so` | 16384 | 32-bit ABI |
| `x86_64/libimage_processing_util_jni.so` | 16384 | 32-bit ABI |
| `x86_64/libsurface_util_jni.so` | 16384 | 32-bit ABI |

## Findings

- No packaging or ELF-header errors found.

Physical 16 KB Android runtime, Chromecast remote control, clean install,
upgrade and two-device Saved Games tests remain separate requirements.

[Android page-size checks](https://developer.android.com/guide/practices/page-sizes)
