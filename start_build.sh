#!/usr/bin/env bash

# export ANDROID_NDK_ROOT="/mnt/c/other/ndk/android-ndk-r20"
# r20 没有gcc
# for arch in armeabi armeabi-v7a armeabi-v7a-hard arm64-v8a mips mips64 x86 x86_64
#for arch in armeabi-v7a
# clang 只支持 armeabi-v7a arm64-v8a x86 x86_64
for arch in  armeabi-v7a arm64-v8a x86 x86_64
do
     chmod +x temp_gcc.sh
    ./temp_gcc.sh $arch 
done

 

# CPPFLAGS="-I$(pwd)/openssl/include" LDFLAGS="-L$(pwd)/openssl/lib" \

#通过chmod +x build_all.sh和chmod +x build_curl.sh命令赋予脚本执行权限。
#https://blog.csdn.net/byhook/article/details/52187711
#https://blog.csdn.net/zhuyunier/article/details/79442417

#有两个参数
# armeabi-v7a
# armeabi-v7a-hard
# arm64-v8a
# mips
# mips64
# x86
# armeabi
# x86_64
#  
# 第二个参数
# 
# stlport (shared)
# stlport-static
# stlport-shared
# gnu (shared)
# gnu-static
# gnu-shared
 
