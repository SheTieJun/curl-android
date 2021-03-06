#!/usr/bin/env bash
#export ANDROID_NDK_ROOT="/mnt/c/other/ndk/android-ndk-r20"
export opensslDir=$(pwd)/android-lib-openssl/$AOSP_ABI

if [ ! -d $opensslDir  ];then
 mkdir -p $opensslDir
fi

export openssl_lib=$opensslDir/lib

if [ ! -d $openssl_lib  ];then
 mkdir -p $openssl_lib
fi
cd  openssl

#here are android-arm, android-arm64, android-mips, android-mip64, android-x86 and android-x86_64 (*MIPS targets are no longer supported with NDK R20+).

PATH=$ANDROID_NDK_ROOT/toolchains/llvm/prebuilt/linux-x86_64/bin:$ANDROID_NDK_ROOT/toolchains/arm-linux-androideabi-4.9/prebuilt/linux-x86_64/bin:$PATH
./Configure android-x86 --release -latomic --libdir=$openssl_lib no-asm shared no-cast no-idea no-camellia no-comp -D__ANDROID_API__=21 --prefix=$opensslDir  --openssldir=$opensslDir
make
make install

