"""Inspect an AAB plus bundletool's config/manifest dumps, without installing it.

Usage: python scripts/check-android-bundle.py app.aab config.txt manifest.xml report.md
Reference: https://developer.android.com/guide/practices/page-sizes
This checks packaging and ELF headers, not runtime compatibility on a device.
"""

import hashlib
import os
from pathlib import Path
import struct
import sys
import xml.etree.ElementTree as ET
import zipfile


def headers(data):
    if data[:4] != b"\x7fELF" or data[5] != 1:
        raise ValueError("Expected a little-endian ELF library")
    if data[4] == 2:
        offset = struct.unpack_from("<Q", data, 32)[0]
        size, count = struct.unpack_from("<HH", data, 54)
        if size < 56:
            raise ValueError("Invalid ELF64 program header size")
        return [struct.unpack_from("<IIQQQQQQ", data, offset + i * size)
                for i in range(count)]
    if data[4] == 1:
        offset = struct.unpack_from("<I", data, 28)[0]
        size, count = struct.unpack_from("<HH", data, 42)
        if size < 32:
            raise ValueError("Invalid ELF32 program header size")
        result = []
        for i in range(count):
            kind, off, va, pa, fs, ms, flags, align = struct.unpack_from(
                "<IIIIIIII", data, offset + i * size)
            result.append((kind, flags, off, va, pa, fs, ms, align))
        return result
    raise ValueError("Unsupported ELF class")


def inspect(aab, config, manifest, report):
    errors = []
    rows = []
    with zipfile.ZipFile(aab) as archive:
        names = set(archive.namelist())
        for abi in ("armeabi-v7a", "arm64-v8a"):
            for library in ("libapp.so", "libflutter.so"):
                if f"base/lib/{abi}/{library}" not in names:
                    errors.append(f"Missing {abi}/{library}")
        for name in sorted(names):
            if not name.startswith("base/lib/") or not name.endswith(".so"):
                continue
            program = headers(archive.read(name))
            loads = [header for header in program if header[0] == 1]
            if not loads:
                errors.append(f"No LOAD segments: {name}")
                continue
            minimum = min(header[7] for header in loads)
            is64 = name.startswith("base/lib/arm64-v8a/")
            aligned = all(h[7] >= 16384 and (h[3] - h[2]) % 16384 == 0
                          for h in loads)
            relro_ok = True
            for relro in (h for h in program if h[0] == 0x6474E552):
                end = relro[3] + relro[6]
                relro_ok &= end % 16384 == 0 or any(
                    h[3] <= relro[3] and h[3] + h[6] == end for h in loads)
            if is64 and not (aligned and relro_ok):
                errors.append(f"16 KB ELF/RELRO check failed: {name}")
            result = ("PASS" if aligned and relro_ok else "FAIL") if is64 else "32-bit ABI"
            rows.append(f"| `{name.removeprefix('base/lib/')}` | {minimum} | {result} |")

    config16 = "PAGE_ALIGNMENT_16K" in Path(config).read_text(encoding="utf-8")
    if not config16:
        errors.append("Bundle config does not request PAGE_ALIGNMENT_16K")
    root = ET.parse(manifest).getroot()
    android = "{http://schemas.android.com/apk/res/android}"
    features = {node.get(android + "name"): node.get(android + "required", "true")
                for node in root.findall("uses-feature")}
    for feature in ("android.hardware.touchscreen", "android.hardware.faketouch",
                    "android.hardware.camera", "android.hardware.camera.autofocus"):
        if features.get(feature) != "false":
            errors.append(f"TV hardware must be optional: {feature}")
    tv_entry = any(node.get(android + "name") == "android.intent.category.LEANBACK_LAUNCHER"
                   for node in root.findall("./application/activity/intent-filter/category"))
    if not tv_entry:
        errors.append("No LEANBACK_LAUNCHER activity in the compiled manifest")
    digest = hashlib.sha256(Path(aab).read_bytes()).hexdigest()
    source = os.getenv("AAB_SOURCE_SHA", "local")
    run = os.getenv("AAB_RUN_ID", "unspecified")
    lines = ["# Android bundle validation", "", f"Source: `{source}`",
             f"AAB build: `{run}`", f"Version code: `{root.get(android + 'versionCode')}`",
             f"SHA-256: `{digest}`", "", f"Result: **{'FAIL' if errors else 'PASS'}**", "",
             f"Bundle ZIP alignment requests 16 KB: **{config16}**.",
             f"TV launcher present: **{tv_entry}**.",
             "Touchscreen, fake touch and camera requirements checked in the compiled manifest.", "",
             "| Native library | Minimum LOAD alignment | ELF result |",
             "| --- | ---: | --- |", *rows, "", "## Findings", ""]
    lines += [f"- {error}" for error in errors] or ["- No packaging or ELF-header errors found."]
    lines += ["", "Physical 16 KB Android runtime, Chromecast remote control, clean install,",
              "upgrade and two-device Saved Games tests remain separate requirements.", "",
              "[Android page-size checks](https://developer.android.com/guide/practices/page-sizes)", ""]
    Path(report).parent.mkdir(parents=True, exist_ok=True)
    Path(report).write_text("\n".join(lines), encoding="utf-8")
    print("\n".join(lines))
    return bool(errors)


if __name__ == "__main__":
    if len(sys.argv) != 5:
        sys.exit(__doc__)
    sys.exit(inspect(*sys.argv[1:]))
