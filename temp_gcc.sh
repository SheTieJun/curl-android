#!/usr/bin/env bash

# ====================================================================
# Sets the cross compile environment for Android
# Based upon OpenSSL's setenv-android.sh (by TH, JW, and SM).
#
# Crypto++ Library is copyrighted as a compilation and (as of version 5.6.2)
# licensed under the Boost Software License 1.0, while the individual files
# in the compilation are all public domain.
#
# See http://www.cryptopp.com/wiki/Android_(Command_Line) for more details
# ====================================================================

real_path() {
	echo "$PWD"
}


unset IS_CROSS_COMPILE

unset IS_IOS
unset IS_ANDROID
unset IS_ARM_EMBEDDED

unset AOSP_FLAGS
unset AOSP_SYSROOT
unset AOSP_STL_INC
unset AOSP_STL_LIB
unset AOSP_BITS_INC

export API=21 


REL_SCRIPT_PATH="$(dirname $0)"
SCRIPTPATH=$(real_path $REL_SCRIPT_PATH)
CURLPATH="$SCRIPTPATH/curl"
SSLPATH="$SCRIPTPATH/openssl"

echo "CURLPATH=$CURLPATH"
echo "SSLPATH=$SSLPATH"

if [ -f /proc/cpuinfo ]; then
	JOBS=$(grep flags /proc/cpuinfo |wc -l)
elif [ ! -z $(which sysctl) ]; then
	JOBS=$(sysctl -n hw.ncpu)
else
	JOBS=8
fi


# Set AOSP_TOOLCHAIN_SUFFIX to your preference of tools and STL library.
#   Note: 4.9 is required for the latest architectures, like ARM64/AARCH64.
# AOSP_TOOLCHAIN_SUFFIX=4.8
# AOSP_TOOLCHAIN_SUFFIX=4.9
if [ -z "$AOSP_TOOLCHAIN_SUFFIX" ]; then
    AOSP_TOOLCHAIN_SUFFIX=4.9
fi

# Set AOSP_API to the API you want to use. 'armeabi' and 'armeabi-v7a' need
#   API 3 (or above), 'mips' and 'x86' need API 9 (or above), etc.
# AOSP_API="android-3"     # Android 1.5 and above
# AOSP_API="android-4"     # Android 1.6 and above
# AOSP_API="android-5"     # Android 2.0 and above
# AOSP_API="android-8"     # Android 2.2 and above
# AOSP_API="android-9"     # Android 2.3 and above
# AOSP_API="android-14"    # Android 4.0 and above
# AOSP_API="android-18"    # Android 4.3 and above
# AOSP_API="android-19"    # Android 4.4 and above
# AOSP_API="android-21"    # Android 5.0 and above
# AOSP_API="android-23"    # Android 6.0 and above
if [ -z "$AOSP_API" ]; then
    AOSP_API="android-21"
fi

#####################################################################

# ANDROID_NDK_ROOT should always be set by the user (even when not running this script)
#   http://groups.google.com/group/android-ndk/browse_thread/thread/a998e139aca71d77.
# If the user did not specify the NDK location, try and pick it up. We expect something
#   like ANDROID_NDK_ROOT=/opt/android-ndk-r10e or ANDROID_NDK_ROOT=/usr/local/android-ndk-r10e.

if [ -z "$ANDROID_NDK_ROOT" ]; then
	echo "Please set your ANDROID_NDK_ROOT environment variable first"
	exit 1
fi

# Error checking
if [ ! -d "$ANDROID_NDK_ROOT/toolchains" ]; then
    echo "ERROR: ANDROID_NDK_ROOT is not a valid path. Please set it."
    [ "$0" = "$BASH_SOURCE" ] && exit 1 || return 1
fi

#####################################################################

if [ "$#" -lt 1 ]; then
    THE_ARCH=armv7
else
    THE_ARCH=$(tr [A-Z] [a-z] <<< "$1")
fi

# https://developer.android.com/ndk/guides/abis.html
case "$THE_ARCH" in
  arm|armv5|armv6|armv7|armeabi)
    TOOLCHAIN_BASE="arm-linux-androideabi"
    TOOLNAME_BASE="arm-linux-androideabi"
    AOSP_ABI="armeabi"
    AOSP_ARCH="arch-arm"
    AOSP_FLAGS="-march=armv5te -mtune=xscale -mthumb -msoft-float -funwind-tables -fexceptions -frtti"
    ;;
  armv7a|armeabi-v7a)
    TOOLCHAIN_BASE="arm-linux-androideabi"
    TOOLNAME_BASE="arm-linux-androideabi"
    AOSP_ABI="armeabi-v7a"
    AOSP_ARCH="arch-arm"
    AOSP_FLAGS="-march=armv7-a -mthumb -mfpu=vfpv3-d16 -mfloat-abi=softfp -Wl,--fix-cortex-a8 -funwind-tables -fexceptions -frtti"
    ;;
  hard|armv7a-hard|armeabi-v7a-hard)
    TOOLCHAIN_BASE="arm-linux-androideabi"
    TOOLNAME_BASE="arm-linux-androideabi"
    AOSP_ABI="armeabi-v7a"
    AOSP_ARCH="arch-arm"
    AOSP_FLAGS="-mhard-float -D_NDK_MATH_NO_SOFTFP=1 -march=armv7-a -mfpu=vfpv3-d16 -mfloat-abi=softfp -Wl,--fix-cortex-a8 -funwind-tables -fexceptions -frtti -Wl,--no-warn-mismatch -Wl,-lm_hard"
    ;;
  neon|armv7a-neon)
    TOOLCHAIN_BASE="arm-linux-androideabi"
    TOOLNAME_BASE="arm-linux-androideabi"
    AOSP_ABI="armeabi-v7a"
    AOSP_ARCH="arch-arm"
    AOSP_FLAGS="-march=armv7-a -mfpu=vfpv3-d16 -mfloat-abi=softfp -Wl,--fix-cortex-a8 -funwind-tables -fexceptions -frtti"
    ;;
  armv8|armv8a|aarch64|arm64|arm64-v8a)
    TOOLCHAIN_BASE="aarch64-linux-android"
    TOOLNAME_BASE="aarch64-linux-android"
    AOSP_ABI="arm64-v8a"
    AOSP_ARCH="arch-arm64"
    AOSP_FLAGS="-funwind-tables -fexceptions -frtti"
    ;;
  mips|mipsel)
    TOOLCHAIN_BASE="mipsel-linux-android"
    TOOLNAME_BASE="mipsel-linux-android"
    AOSP_ABI="mips"
    AOSP_ARCH="arch-mips"
    AOSP_FLAGS="-funwind-tables -fexceptions -frtti"
    ;;
  mips64|mipsel64|mips64el)
    TOOLCHAIN_BASE="mips64el-linux-android"
    TOOLNAME_BASE="mips64el-linux-android"
    AOSP_ABI="mips64"
    AOSP_ARCH="arch-mips64"
    AOSP_FLAGS="-funwind-tables -fexceptions -frtti"
    ;;
  x86)
    TOOLCHAIN_BASE="x86"
    TOOLNAME_BASE="i686-linux-android"
    AOSP_ABI="x86"
    AOSP_ARCH="arch-x86"
    AOSP_FLAGS="-march=i686 -mtune=intel -mssse3 -mfpmath=sse -funwind-tables -fexceptions -frtti"
    ;;
  x86_64|x64)
    TOOLCHAIN_BASE="x86_64"
    TOOLNAME_BASE="x86_64-linux-android"
    AOSP_ABI="x86_64"
    AOSP_ARCH="arch-x86_64"
    AOSP_FLAGS="-march=x86-64 -msse4.2 -mpopcnt -mtune=intel -funwind-tables -fexceptions -frtti"
    ;;
  *)
    echo "ERROR: Unknown architecture $1"
    [ "$0" = "$BASH_SOURCE" ] && exit 1 || return 1
    ;;
esac


# Based on ANDROID_NDK_ROOT, try and pick up the path for the tools. We expect something
# like /opt/android-ndk-r10e/toolchains/arm-linux-androideabi-4.7/prebuilt/linux-x86_64/bin
# Once we locate the tools, we add it to the PATH.
AOSP_TOOLCHAIN_PATH=""
for host in "linux-x86_64" "darwin-x86_64" "linux-x86" "darwin-x86" "windows" "windows-x86_64"
do
    if [ -d "$ANDROID_NDK_ROOT/toolchains/$TOOLCHAIN_BASE-$AOSP_TOOLCHAIN_SUFFIX/prebuilt/$host/bin" ]; then
        AOSP_TOOLCHAIN_PATH="$ANDROID_NDK_ROOT/toolchains/$TOOLCHAIN_BASE-$AOSP_TOOLCHAIN_SUFFIX/prebuilt/$host/bin"
        break
    fi
done


#####################################################################

# Error checking
if [ ! -d "$ANDROID_NDK_ROOT/platforms/$AOSP_API" ]; then
    echo "ERROR: AOSP_API is not valid. Does the NDK support the API? Please edit this script."
    [ "$0" = "$BASH_SOURCE" ] && exit 1 || return 1
elif [ ! -d "$ANDROID_NDK_ROOT/platforms/$AOSP_API/$AOSP_ARCH" ]; then
    echo "ERROR: AOSP_ARCH is not valid. Does the NDK support the architecture? Please edit this script."
    [ "$0" = "$BASH_SOURCE" ] && exit 1 || return 1
fi

# Android SYSROOT. It will be used on the command line with --sysroot
#   http://android.googlesource.com/platform/ndk/+/ics-mr0/docs/STANDALONE-TOOLCHAIN.html
# ndk\platforms\android-21\arch-arm64
export AOSP_SYSROOT="$ANDROID_NDK_ROOT/platforms/$AOSP_API/$AOSP_ARCH"

# TODO: export for the previous GNUmakefile-cross. These can go away eventually.
export ANDROID_SYSROOT=$AOSP_SYSROOT



#####################################################################

# # Android STL. We support GNU, LLVM and STLport out of the box.

# if [ "$#" -lt 2 ]; then
#     THE_STL=stlport-shared
# else
#     THE_STL=$(tr [A-Z] [a-z] <<< "$2")
# fi

# case "$THE_STL" in
#   stlport-static)
#     AOSP_STL_INC="$ANDROID_NDK_ROOT/sources/cxx-stl/stlport/stlport/"
#     AOSP_STL_LIB="$ANDROID_NDK_ROOT/sources/cxx-stl/stlport/libs/$AOSP_ABI/libstlport_static.a"
#     ;;
#   stlport|stlport-shared)
#     AOSP_STL_INC="$ANDROID_NDK_ROOT/sources/cxx-stl/stlport/stlport/"
#     AOSP_STL_LIB="$ANDROID_NDK_ROOT/sources/cxx-stl/stlport/libs/$AOSP_ABI/libstlport_shared.so"
#     ;;
#   gabi++-static|gnu-static)
#     AOSP_STL_INC="$ANDROID_NDK_ROOT/sources/cxx-stl/gnu-libstdc++/$AOSP_TOOLCHAIN_SUFFIX/include"
#     AOSP_BITS_INC="$ANDROID_NDK_ROOT/sources/cxx-stl/gnu-libstdc++/$AOSP_TOOLCHAIN_SUFFIX/libs/$AOSP_ABI/include"
#     AOSP_STL_LIB="$ANDROID_NDK_ROOT/sources/cxx-stl/gnu-libstdc++/$AOSP_TOOLCHAIN_SUFFIX/libs/$AOSP_ABI/libgnustl_static.a"
#     ;;
#   gnu|gabi++|gnu-shared|gabi++-shared)
#     AOSP_STL_INC="$ANDROID_NDK_ROOT/sources/cxx-stl/gnu-libstdc++/$AOSP_TOOLCHAIN_SUFFIX/include"
#     AOSP_BITS_INC="$ANDROID_NDK_ROOT/sources/cxx-stl/gnu-libstdc++/$AOSP_TOOLCHAIN_SUFFIX/libs/$AOSP_ABI/include"
#     AOSP_STL_LIB="$ANDROID_NDK_ROOT/sources/cxx-stl/gnu-libstdc++/$AOSP_TOOLCHAIN_SUFFIX/libs/$AOSP_ABI/libgnustl_shared.so"
#     ;;
#   llvm-static)
#     AOSP_STL_INC="$ANDROID_NDK_ROOT/sources/cxx-stl/llvm-libc++/libcxx/include"
#     AOSP_STL_LIB="$ANDROID_NDK_ROOT/sources/cxx-stl/llvm-libc++/libs/$AOSP_ABI/libc++_static.a"
#     ;;
#   llvm|llvm-shared)
#     AOSP_STL_INC="$ANDROID_NDK_ROOT/sources/cxx-stl/llvm-libc++/libcxx/include"
#     AOSP_STL_LIB="$ANDROID_NDK_ROOT/sources/cxx-stl/llvm-libc++/libs/$AOSP_ABI/libc++_shared.so"
#     ;;
#   *)
#     echo "ERROR: Unknown STL library $2"
#     [ "$0" = "$BASH_SOURCE" ] && exit 1 || return 1
# esac


#####################################################################


export CPP="$AOSP_TOOLCHAIN_PATH/$TOOLNAME_BASE-cpp --sysroot=$AOSP_SYSROOT"
export CC="$AOSP_TOOLCHAIN_PATH/$TOOLNAME_BASE-gcc --sysroot=$AOSP_SYSROOT"
export CXX="$AOSP_TOOLCHAIN_PATH/$TOOLNAME_BASE-g++ --sysroot=$AOSP_SYSROOT"
export CFLAGS="-pie -fPIE $AOSP_FLAGS"
# export LDFLAGS="-pie -fPIE"
#####################################################################

export opensslDir=$(pwd)/android-lib-openssl/$AOSP_ABI

if [ ! -d $opensslDir  ];then
 mkdir -p $opensslDir
fi

export openssl_lib=$opensslDir/lib

if [ ! -d $openssl_lib  ];then
 mkdir -p $openssl_lib
fi


echo "openssl输出目录 =$opensslDir "

VERBOSE=1
if [ ! -z "$VERBOSE" ] && [ "$VERBOSE" != "0" ]; then
  echo "job:"$JOBS
  echo "API:"$API
  echo "ANDROID_NDK_ROOT: $ANDROID_NDK_ROOT"
  echo "AOSP_TOOLCHAIN_PATH: $AOSP_TOOLCHAIN_PATH"
  echo "AOSP_ABI: $AOSP_ABI"  
  echo "AOSP_API: $AOSP_API"
  echo "CC: $CC"
  echo "AOSP_SYSROOT: $AOSP_SYSROOT"
  echo "AOSP_FLAGS: $AOSP_FLAGS"
  # echo "AOSP_STL_INC: $AOSP_STL_INC"
  # echo "AOSP_STL_LIB: $AOSP_STL_LIB"

fi

echo "start build openssl"

cd  $SSLPATH

pwd

PATH=$ANDROID_NDK_ROOT/toolchains/arm-linux-androideabi-4.8/prebuilt/linux-x86_64/bin:$PATH

## 最终成MakeFile
./Configure $openssl_target --libdir=$openssl_lib no-asm shared no-cast no-idea no-camellia no-comp -D__ANDROID_API__=$API --prefix=$opensslDir  --openssldir=$opensslDir


EXITCODE=$?
if [ $EXITCODE -ne 0 ]; then
	echo "Error building the libssl and libcrypto"
	cd $PWD
	exit $EXITCODE
fi

make clean

make -j$JOBS

make install


#####################################################################

echo "start build curl"

cd ..

export outCurlib=$(pwd)/android-lib-curl/$AOSP_ABI

if [ ! -d $outCurlib  ];then
  mkdir -p $outCurlib
fi

echo "Curlib输出目录 =$outCurlib "
pwd

cd  $CURLPATH
# # ./Configure android no-asm no-shared no-cast no-idea no-camellia no-whirpool
if [ ! -x "configure" ]; then
	echo "Curl needs external tools to be compiled"
	echo "Make sure you have autoconf, automake and libtool installed"

	./buildconf

	EXITCODE=$?
	if [ $EXITCODE -ne 0 ]; then
		echo "Error running the buildconf program"
		cd $PWD
		exit $EXITCODE
	fi
fi


./configure \
    --prefix=$outCurlib \
    --enable-static \
    --enable-shared \
    --host=$TOOLNAME_BASE\
    --with-ssl=$opensslDir \
    --without-zlib

make clean

make -j$JOBS

make install

EXITCODE=$?
if [ $EXITCODE -ne 0 ]; then
	echo "Error building the curl"
	cd $PWD
	exit $EXITCODE
fi

[ "$0" = "$BASH_SOURCE" ] && exit 0 || return 0cd .