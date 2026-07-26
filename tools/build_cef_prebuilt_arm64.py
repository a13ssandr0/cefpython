#!/usr/bin/env python3
"""
Build libcef_dll_wrapper for Linux ARM64 and create the prebuilt CEF directory
structure expected by CMakeLists.txt, WITHOUT building the CEF sample apps
(cefclient/cefsimple/ceftests).

This replaces 'python tools/automate.py --prebuilt-cef' for the ARM64 Linux case
to avoid compiling large sample apps under slow QEMU emulation.

Usage:
    python tools/build_cef_prebuilt_arm64.py
"""

import glob
import os
import re
import shutil
import subprocess
import sys

# Allow running from any directory
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import common

ROOT_DIR = common.ROOT_DIR
BUILD_DIR = common.BUILD_DIR


def log(msg):
    print("[build_cef_prebuilt_arm64] {}".format(msg))


def run(cmd, cwd=None):
    log("$ " + " ".join(cmd))
    subprocess.run(cmd, cwd=cwd, check=True)


def patch_cef_cmake_for_arm64(cef_src):
    """Remove x86_64-specific compiler/linker flags that are invalid on aarch64.

    The CEF binary distribution's cmake/cef_variables.cmake determines
    PROJECT_ARCH solely from sizeof(void*)==8, which is also true on ARM64,
    and then unconditionally adds -m64 / -march=x86-64.  Those flags do not
    exist in the ARM64 GCC toolchain and cause an immediate build failure.
    """
    cef_vars = os.path.join(cef_src, "cmake", "cef_variables.cmake")
    if not os.path.exists(cef_vars):
        log("WARNING: cmake/cef_variables.cmake not found, skipping patch")
        return

    with open(cef_vars, "r") as f:
        original = f.read()

    patched = original
    # Remove the two x86_64-only flags everywhere they appear
    patched = re.sub(r"[ \t]+-m64\b", "", patched)
    patched = re.sub(r"[ \t]+-march=x86-64\b", "", patched)

    if patched != original:
        with open(cef_vars, "w") as f:
            f.write(patched)
        log("Patched cmake/cef_variables.cmake: removed -m64 and -march=x86-64")
    else:
        log("cmake/cef_variables.cmake: x86_64 flags not found, no patch needed")


def main():
    import platform
    machine = platform.machine()
    if machine not in ("aarch64", "arm64"):
        log("ERROR: This script is intended for Linux ARM64 (aarch64). "
            "Current machine: {}".format(machine))
        sys.exit(1)

    # Locate the downloaded CEF standard distribution
    # download_cef.py extracts to: build/cef_binary_<version>_linuxarm64/
    pattern = os.path.join(BUILD_DIR, "cef_binary_*_linuxarm64")
    dirs = sorted(glob.glob(pattern))
    # Exclude any _minimal or _client etc. variants
    dirs = [d for d in dirs if not any(
        d.endswith(s) for s in ("_minimal", "_client", "_tools"))]

    if len(dirs) == 0:
        log("ERROR: No CEF binary dir found at {}".format(pattern))
        log("Run: python tools/download_cef.py")
        sys.exit(1)
    if len(dirs) > 1:
        log("WARNING: Multiple CEF binary dirs found, using the last one:")
        for d in dirs:
            log("  {}".format(d))

    cef_src = dirs[-1]
    log("Using CEF binary dir: {}".format(cef_src))

    # Read CEF version from the distribution's own header
    version_h = os.path.join(cef_src, "include", "cef_version.h")
    if not os.path.exists(version_h):
        log("ERROR: cef_version.h not found in: {}".format(cef_src))
        sys.exit(1)

    with open(version_h) as f:
        content = f.read()

    m_ver = re.search(r'#define CEF_VERSION "(.+?)"', content)
    m_major = re.search(r'#define CHROME_VERSION_MAJOR (\d+)', content)
    if not m_ver or not m_major:
        log("ERROR: Could not parse version from {}".format(version_h))
        sys.exit(1)

    cef_version = m_ver.group(1)
    chrome_major = m_major.group(1)
    log("CEF version: {}  Chrome major: {}".format(cef_version, chrome_major))

    # Patch the CEF cmake files before running cmake — the binary distribution
    # sets PROJECT_ARCH="x86_64" (based on sizeof(void*)==8, true on ARM64 too)
    # and then adds -m64 / -march=x86-64 which are invalid on aarch64 GCC.
    patch_cef_cmake_for_arm64(cef_src)

    # Build libcef_dll_wrapper
    wrapper_build_dir = os.path.join(cef_src, "build_wrapper")
    wrapper_lib = os.path.join(wrapper_build_dir, "libcef_dll_wrapper",
                               "libcef_dll_wrapper.a")

    if os.path.exists(wrapper_lib):
        log("Already built: {}".format(wrapper_lib))
    else:
        log("Building libcef_dll_wrapper...")
        os.makedirs(wrapper_build_dir, exist_ok=True)

        # Configure: target only the wrapper to keep build fast
        run([
            "cmake", "-G", "Ninja",
            "-DCMAKE_BUILD_TYPE=Release",
            # Suppress warnings from the CEF toolchain on GCC 11+
            "-DCMAKE_CXX_FLAGS=-Wno-self-move -Wno-deprecated-declarations",
            ".."
        ], cwd=wrapper_build_dir)

        # Build only the wrapper library, not the sample apps
        run(["ninja", "libcef_dll_wrapper"], cwd=wrapper_build_dir)
        log("OK: libcef_dll_wrapper built")

    assert os.path.exists(wrapper_lib), \
        "libcef_dll_wrapper.a not found after build: {}".format(wrapper_lib)

    # Set up prebuilt directory structure expected by CMakeLists.txt:
    #   build/cef{major}_{version}_linuxarm64/
    #     bin/      <- Release/ + Resources/
    #     lib/      <- libcef_dll_wrapper.a
    #     include/  <- CEF's public headers (cef_config.h, cef_api_versions.h,
    #                  cef_pack_resources.h, base/internal/cef_net_error_list.h,
    #                  etc.): platform-generated, not vendored in src/include,
    #                  and referenced via "${CEF_ROOT}" on the include path
    #                  (see the comment in the top-level CMakeLists.txt)
    prebuilt_name = "cef{}_{}_linuxarm64".format(chrome_major, cef_version)
    prebuilt_dir = os.path.join(BUILD_DIR, prebuilt_name)
    bin_dir = os.path.join(prebuilt_dir, "bin")
    lib_dir = os.path.join(prebuilt_dir, "lib")
    include_dir = os.path.join(prebuilt_dir, "include")

    if os.path.exists(prebuilt_dir):
        log("Prebuilt dir already exists: {}".format(prebuilt_dir))
        return

    log("Creating prebuilt dir: {}".format(prebuilt_dir))
    os.makedirs(bin_dir)
    os.makedirs(lib_dir)

    # Copy include/ -> include/
    include_src = os.path.join(cef_src, "include")
    if os.path.isdir(include_src):
        log("Copying include/ -> include/")
        shutil.copytree(include_src, include_dir)
    else:
        log("ERROR: include/ dir not found in {}".format(cef_src))
        sys.exit(1)

    # Copy Release/ -> bin/
    release_src = os.path.join(cef_src, "Release")
    if os.path.isdir(release_src):
        log("Copying Release/ -> bin/")
        for item in os.listdir(release_src):
            src = os.path.join(release_src, item)
            dst = os.path.join(bin_dir, item)
            if os.path.isdir(src):
                shutil.copytree(src, dst)
            else:
                shutil.copy2(src, dst)
    else:
        log("WARNING: Release/ dir not found in {}".format(cef_src))

    # Copy Resources/ -> bin/
    resources_src = os.path.join(cef_src, "Resources")
    if os.path.isdir(resources_src):
        log("Copying Resources/ -> bin/")
        for item in os.listdir(resources_src):
            src = os.path.join(resources_src, item)
            dst = os.path.join(bin_dir, item)
            if os.path.isdir(src):
                shutil.copytree(src, dst)
            else:
                shutil.copy2(src, dst)
    else:
        log("WARNING: Resources/ dir not found in {}".format(cef_src))

    # Copy libcef_dll_wrapper.a -> lib/
    log("Copying libcef_dll_wrapper.a -> lib/")
    shutil.copy2(wrapper_lib, lib_dir)

    # Copy README and LICENSE
    for fname in ("README.txt", "LICENSE.txt"):
        src = os.path.join(cef_src, fname)
        if os.path.exists(src):
            shutil.copy2(src, prebuilt_dir)

    # Copy cef_version.h for reference
    shutil.copy2(version_h, os.path.join(prebuilt_dir, "cef_version_linux.h"))

    log("OK: prebuilt dir ready at: {}".format(prebuilt_dir))


if __name__ == "__main__":
    main()
