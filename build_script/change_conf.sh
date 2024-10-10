#!/bin/sh
set -e

if [ $# -lt 3 ]; then
    echo "Usage: $0 版本号 打包类型(1-6) app路径"
    exit 1
fi

cd $3
Ver=$1
Type=$2

echo 替换版本号 $1
rowNum=$(grep -n APP_VERSION ./lib/conf.dart | awk -F ':' '{ print $1;}')
#mac与众不同的格式
if [ -f "build_script/linux_sed" ]; then
    sed -i "${rowNum}s/.*/  static const String APP_VERSION = '${Ver}';/g" ./lib/conf.dart
else
    sed -i '' "${rowNum}s/.*/  static const String APP_VERSION = '${Ver}';/g" ./lib/conf.dart
fi
echo 替换打包类型 $2
rowNum=$(grep -n 'static const int DEVICE_TYPE' ./lib/conf.dart | awk -F ':' '{ print $1;}')
echo 替换打包类型行号 $rowNum
#mac与众不同的格式
if [ -f "build_script/linux_sed" ]; then
    sed -i "${rowNum}s/.*/  static const int DEVICE_TYPE = ${Type};/g" ./lib/conf.dart
else
    sed -i '' "${rowNum}s/.*/  static const int DEVICE_TYPE = ${Type};/g" ./lib/conf.dart
fi
echo 替换完毕
exit 0
