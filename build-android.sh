#!/usr/bin/env bash
#
# build-android
#
# This source file is part of the Swift.org open source project
#
# Copyright (c) 2014 - 2017 Apple Inc. and the Swift project authors
# Licensed under Apache License v2.0 with Runtime Library Exception
#
# See https://swift.org/LICENSE.txt for license information
# See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors

set -e

SWIFT_PATH="$( cd "$(dirname $0)/.." && pwd )" 

ANDROID_NDK_PATH="${ANDROID_NDK_PATH:?Please set the Android NDK path in the ANDROID_NDK_PATH environment variable}"
ANDROID_ICU_PATH=${SWIFT_PATH}/libiconv-libicu-android

SWIFT_ANDROID_TOOLCHAIN_PATH="${SWIFT_PATH}/swift-android-toolchain"
SWIFT_ANDROID_BUILD_PATH="${SWIFT_PATH}/build/Ninja-ReleaseAssert"

cd ${SWIFT_PATH}/swift-corelibs-libdispatch

mkdir -p $SWIFT_ANDROID_BUILD_PATH/libdispatch-android-linux-armv7

ANDROID_STANDALONE_TOOLCHAIN=$SWIFT_PATH/build/android-standalone-toolchain
ANDROID_STANDALONE_SYSROOT=$ANDROID_STANDALONE_TOOLCHAIN/sysroot

export PATH=$ANDROID_STANDALONE_TOOLCHAIN/bin:$PATH
export CC=$ANDROID_STANDALONE_TOOLCHAIN/bin/arm-linux-androideabi-clang
export CXX=$ANDROID_STANDALONE_TOOLCHAIN/bin/arm-linux-androideabi-clang++
export ARCH_LINK="-march=armv7-a -Wl,--fix-cortex-a8 -L$ANDROID_ICU_PATH/armeabi-v7a/ -L$ANDROID_STANDALONE_TOOLCHAIN/lib/gcc/arm-linux-androideabi/4.9.x/ -lgcc"
export LDFLAGS=" ${ARCH_LINK} "

if [ ! -f libdispatch.so ]; then
    pushd $ANDROID_STANDALONE_SYSROOT
        pushd $SWIFT_PATH
            pushd $SWIFT_ANDROID_BUILD_PATH/libdispatch-android-linux-armv7
                cmake \
                    -G Ninja \
                    -DINSTALL_LIBDIR="$SWIFT_ANDROID_TOOLCHAIN_PATH/usr/lib" \
                    -DCMAKE_SWIFT_COMPILER="$SWIFT_ANDROID_BUILD_PATH/swift-linux-x86_64/bin/swiftc" \
                    -DCMAKE_C_COMPILER="$CC" \
                    -DCMAKE_C_COMPILER_TARGET="armv7-none-linux-androideabi" \
                    -DCMAKE_CXX_COMPILER="$CXX" \
                    -DCMAKE_C_FLAGS="--sysroot=$ANDROID_STANDALONE_SYSROOT -I$ANDROID_STANDALONE_SYSROOT/usr/include -I$ANDROID_ICU_PATH/armeabi-v7a/include -I${SDKROOT}/lib/swift" \
                    -DCMAKE_SWIFT_FLAGS="-I$ANDROID_STANDALONE_SYSROOT/usr/include" \
                    -DCMAKE_SYSTEM_NAME=Android \
                    -DCMAKE_SYSTEM_PROCESSOR=armv7l \
                    -DENABLE_SWIFT=1 \
                    -DENABLE_TESTING=1 \
                    -DDISPATCH_ENABLE_ASSERTS=0 \
                    $SWIFT_PATH/swift-corelibs-libdispatch

                cp -r /usr/include/uuid $ANDROID_STANDALONE_SYSROOT/usr/include 
                sed -i~ "s/-I.\/ -I\/usr\/include\/x86_64-linux-gnu  -I\/usr\/include\/x86_64-linux-gnu    -I\/usr\/include\/libxml2//" build.ninja
                sed -i~ "s/-licui18n/-licui18nswift/g" build.ninja
                sed -i~ "s/-licuuc/-licuucswift/g" build.ninja
                sed -i~ "s/-licudata/-licudataswift/g" build.ninja

                ninja && ninja install

            popd
        popd
    popd
fi

