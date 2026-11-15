#!/usr/bin/env python3
"""Prepare only hash-pinned official Godot source. No network or installs."""
import argparse
import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import shutil
import subprocess
import tarfile
import tempfile

ROOT = Path(__file__).resolve().parent
TAG = "4.6.3-stable"
COMMIT = "35e80b3a8822a9df9be390814b62f44c0a9c69e8"
ARCHIVE_SHA256 = "fa22b5f974125057087c9ef725eae582dbc5e39385dc377e8d5dbc295b367e1c"
ARCHIVE_BYTES = 66058610
SOURCE_ROOT = "godot-4.6.3-stable"
RECEIPT = ".local_surfaceless_source.json"


def digest(path):
    h = hashlib.sha256()
    with Path(path).open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            h.update(block)
    return h.hexdigest()


def verified_archive(path):
    path = Path(path).resolve()
    if path.stat().st_size != ARCHIVE_BYTES or digest(path) != ARCHIVE_SHA256:
        raise ValueError("Not the pinned official Godot archive; refusing extraction.")
    return path


def validate_member(member):
    path = PurePosixPath(member.name)
    if path.is_absolute() or ".." in path.parts or not path.parts or path.parts[0] != SOURCE_ROOT:
        raise ValueError("Unsafe or unexpected archive path.")
    if not (member.isfile() or member.isdir()):
        raise ValueError("Only regular files/directories are accepted in this exact archive.")


def patch_command(source, patch, *, dry_run=False, reverse=False):
    command = ["patch", "--batch", "--fuzz=0", "-p1", "--directory", str(source)]
    command += ["--reverse"] if reverse else ["--forward"]
    if dry_run:
        command.append("--dry-run")
    with Path(patch).open("rb") as stream:
        return subprocess.run(command, stdin=stream, check=False).returncode


def apply_patch(source, name):
    patch = ROOT / name
    if patch_command(source, patch, dry_run=True) != 0:
        raise ValueError(f"Patch does not apply cleanly: {name}")
    if patch_command(source, patch) != 0:
        raise ValueError(f"Patch failed: {name}; preserve the staged source for inspection.")


def write_receipt(source, tangent):
    patches = ["surfaceless.patch"] + (["gles3-tangent.patch"] if tangent else [])
    receipt = {"tag": TAG, "commit": COMMIT, "archive_sha256": ARCHIVE_SHA256,
               "patches": {name: digest(ROOT / name) for name in patches}, "tangent": tangent}
    temporary = source / (RECEIPT + ".tmp")
    temporary.write_text(json.dumps(receipt, indent=2) + "\n", encoding="utf-8")
    os.replace(temporary, source / RECEIPT)


def prepare(archive, destination, tangent=False):
    archive = verified_archive(archive)
    destination = Path(destination).resolve()
    if destination.exists():
        raise ValueError("Destination already exists. Never overwrite an existing source tree.")
    destination.parent.mkdir(parents=True, exist_ok=True)
    if shutil.disk_usage(destination.parent).free < 1024**3:
        raise ValueError("Require at least 1 GiB free before source extraction.")
    stage = Path(tempfile.mkdtemp(prefix="." + destination.name + ".prepare-", dir=destination.parent))
    try:
        with tarfile.open(archive, "r:gz") as package:
            for member in package:
                validate_member(member)
                target = stage.joinpath(*PurePosixPath(member.name).parts)
                if member.isdir():
                    target.mkdir(parents=True, exist_ok=True)
                else:
                    target.parent.mkdir(parents=True, exist_ok=True)
                    with package.extractfile(member) as src, target.open("xb") as out:
                        shutil.copyfileobj(src, out)
                    target.chmod(member.mode & 0o777)
        source = stage / SOURCE_ROOT
        apply_patch(source, "surfaceless.patch")
        if tangent:
            apply_patch(source, "gles3-tangent.patch")
        write_receipt(source, tangent)
        os.replace(source, destination)
        stage.rmdir()
    except Exception:
        print(f"Preparation stopped; newly staged source retained at {stage}")
        raise
    print(f"Prepared {TAG} ({COMMIT}) at {destination}")


def add_tangent(source):
    source = Path(source).resolve()
    receipt = json.loads((source / RECEIPT).read_text(encoding="utf-8"))
    if receipt.get("commit") != COMMIT or receipt.get("archive_sha256") != ARCHIVE_SHA256:
        raise ValueError("Source receipt does not match the pinned upstream.")
    if receipt.get("patches", {}).get("surfaceless.patch") != digest(ROOT / "surfaceless.patch"):
        raise ValueError("Backend patch receipt differs from this checkpoint.")
    if receipt.get("tangent"):
        raise ValueError("Tangent patch is already recorded; no changes made.")
    patch = ROOT / "gles3-tangent.patch"
    if patch_command(source, patch, dry_run=True) == 0:
        if patch_command(source, patch) != 0:
            raise ValueError("Tangent patch stopped; inspect source before retry.")
    elif patch_command(source, patch, dry_run=True, reverse=True) != 0:
        raise ValueError("Source is neither cleanly applicable nor fully patched; do not repeat blindly.")
    # A complete reverse dry-run also recovers interruption after patching but before receipt save.
    write_receipt(source, True)
    print("Tangent patch recorded. Preserve the baseline binary before incremental rebuild.")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--archive", type=Path)
    parser.add_argument("--destination", type=Path)
    parser.add_argument("--tangent", action="store_true")
    parser.add_argument("--check-only", action="store_true")
    parser.add_argument("--apply-tangent", type=Path)
    args = parser.parse_args()
    if not shutil.which("patch"):
        parser.error("An existing patch executable is required; nothing is installed automatically.")
    if args.apply_tangent:
        if args.archive or args.destination or args.tangent or args.check_only:
            parser.error("--apply-tangent is a separate operation.")
        add_tangent(args.apply_tangent)
    elif not args.archive or (not args.check_only and not args.destination):
        parser.error("Use --archive and --destination, or --archive --check-only.")
    elif args.check_only:
        archive = verified_archive(args.archive)
        with tarfile.open(archive, "r:gz") as package:
            count = 0
            for member in package:
                validate_member(member)
                count += 1
        print(f"PASS pinned archive: {count} safe members; no files extracted.")
    else:
        prepare(args.archive, args.destination, args.tangent)


if __name__ == "__main__":
    main()
