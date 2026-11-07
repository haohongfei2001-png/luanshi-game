#!/usr/bin/env python3
"""Verify archive integrity, Info.plist, PCK and both universal Mach-O slices.

Static inspection only. This does not claim native execution or code signing.
"""
import plistlib
import struct
import sys
import zipfile

with zipfile.ZipFile(sys.argv[1]) as archive:
    assert archive.testzip() is None, "Invalid ZIP member"
    names = archive.namelist()
    plist_name = next(n for n in names if n.endswith(".app/Contents/Info.plist"))
    info = plistlib.loads(archive.read(plist_name))
    executable = plist_name.removesuffix("Info.plist") + "MacOS/" + info["CFBundleExecutable"]
    data = archive.read(executable)
    assert struct.unpack_from(">I", data)[0] == 0xCAFEBABE, "Not a universal Mach-O"
    count = struct.unpack_from(">I", data, 4)[0]
    cpus = {struct.unpack_from(">I", data, 8 + i * 20)[0] for i in range(count)}
    assert 0x0100000C in cpus, "Missing arm64"
    assert 0x01000007 in cpus, "Missing x86_64"
    assert any(n.endswith(".pck") and archive.getinfo(n).file_size > 1000 for n in names)
    assert archive.getinfo(executable).external_attr >> 16 & 0o111, "Executable permission missing"
    print("MACOS_ARCHIVE_PASS arm64+x86_64 bundle=%s version=%s signing=not-verified runtime=not-tested" % (
        info["CFBundleIdentifier"], info["CFBundleShortVersionString"]))
