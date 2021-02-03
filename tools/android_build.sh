#!/bin/bash

set -e

ROOT=${PWD}

if [ $# -eq 0 ]
then
  echo "Requires a path to the Android NDK"
  echo "Usage: android_build.sh <path_to_ndk> [target_arch] [target_api]"
  exit
fi

SCRIPT_DIR="$(dirname "$BASH_SOURCE")"
cd "$SCRIPT_DIR"
SCRIPT_DIR=${PWD}

cd "$ROOT"
cd "$1"
ANDROID_NDK_PATH=${PWD}
cd "$SCRIPT_DIR"
cd ../

BUILD_ARCH() {
  TARGET_ARCH="$1"
  TARGET_API="$2"

  make clean
  # Clean previous toolchain.
  rm -rf android-toolchain/
  source ./android-configure "$ANDROID_NDK_PATH" "$TARGET_ARCH" "$TARGET_API"
  make -j $(getconf _NPROCESSORS_ONLN)
  TARGET_ARCH_FOLDER="$TARGET_ARCH"
  if [ "$TARGET_ARCH_FOLDER" == "arm" ]; then
    # Use the Android NDK ABI name.
    TARGET_ARCH_FOLDER="armeabi-v7a"
  elif [ "$TARGET_ARCH_FOLDER" == "arm64" ]; then
    # Use the Android NDK ABI name.
    TARGET_ARCH_FOLDER="arm64-v8a"
  fi
  mkdir -p "out_android/$TARGET_ARCH_FOLDER/"
  cp "out/Release/lib.target/libnode.so" "out_android/$TARGET_ARCH_FOLDER/libnode.so"
}

# Usage: android_build.sh <path_to_ndk> [target_arch] [target_api]

# https://developer.android.com/ndk/guides/standalone_toolchain
# The minimum API level supported by NDK toolchains is currently 16 for 32-bit architectures, and 21 for 64-bit architectures.
MIN_TARGET_API_32bit='19'
MIN_TARGET_API_64bit='21'

if [ $# -eq 3 ]; then
  BUILD_ARCH "$2" "$3"
elif [ $# -eq 2 ]; then
  PARAM="$2"
  if [ ! -z "${PARAM##*[!0-9]*}" ]; then
    # 2nd param is API (integer)
    if [ "$PARAM" -ge "$MIN_TARGET_API_32bit" ]; then
      BUILD_ARCH "arm" "$PARAM"
      BUILD_ARCH "x86" "$PARAM"
    else
      BUILD_ARCH "arm" "$MIN_TARGET_API_32bit"
      BUILD_ARCH "x86" "$MIN_TARGET_API_32bit"
    fi
    if [ "$PARAM" -ge "$MIN_TARGET_API_64bit" ]; then
      BUILD_ARCH "arm64"  "$PARAM"
      BUILD_ARCH "x86_64" "$PARAM"
    else
      BUILD_ARCH "arm64"  "$MIN_TARGET_API_64bit"
      BUILD_ARCH "x86_64" "$MIN_TARGET_API_64bit"
    fi
  else
    # 2nd param is ARCH
    if [ "arm" == "$PARAM" -o "x86" == "$PARAM" ]; then
      BUILD_ARCH "$PARAM" "$MIN_TARGET_API_32bit"
    else
      BUILD_ARCH "$PARAM" "$MIN_TARGET_API_64bit"
    fi
  fi
else
  BUILD_ARCH "arm"    "$MIN_TARGET_API_32bit"
  BUILD_ARCH "x86"    "$MIN_TARGET_API_32bit"
  BUILD_ARCH "arm64"  "$MIN_TARGET_API_64bit"
  BUILD_ARCH "x86_64" "$MIN_TARGET_API_64bit"
fi

cd "$ROOT"
