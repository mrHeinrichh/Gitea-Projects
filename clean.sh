#!/bin/bash

# 脚本目录
cd $(dirname $0)
platform=$1
fource=$2
valid_platforms=("ios" "android" "web" "windows" "macos" "linux")
default_platform="ios"

# 检查平台是否有效
if [ -z "$platform" ]; then
    platform=$default_platform
    echo "No platform specified. Defaulting to $default_platform."
else
    if [[ ! " ${valid_platforms[@]} " =~ " ${platform} " ]]; then
        echo "Invalid platform specified. Valid platforms are: ${valid_platforms[*]}"
        exit 1
    fi
fi

echo "Running script for platform: $platform"

root=$(pwd)
# 清理build目录
rm -rf build
# 清理插件
echo "########## 清理插件 无需点击vscode的Get packages "
echo ''
flutter clean

timestamp_file="$HOME/last_execution_timestamp.txt"
# 获取当前日期
current_date=$(date +"%Y-%m-%d")

# 检查记录文件是否不存在或者上次执行时间不是今天
if [ "$fource" == "1" ] || [ ! -f "$timestamp_file" ] || [ "$(cat "$timestamp_file")" != "$current_date" ]; then
    # 更新记录文件中的时间戳
    echo '############强制清理缓存'
    flutter pub cache clean -f
    echo "$current_date" >"$timestamp_file"
fi
echo ''
echo "########## 获取项目插件"
echo ''
rm -rf pubspec.lock && flutter pub get

echo ''
echo "########## 获取项目插件列子项目插件"
echo ''
for plugin in $(ls plugin); do
    echo $plugin/example
    _plugin=$root/plugin/$plugin/example
    if [ -d $_plugin ]; then
        echo "获取插件example=====> $_plugin"
        cd $_plugin
        rm -rf pubspec.lock && flutter pub get
    fi
    _plugin=$root/plugin/$plugin/test
    if [ -d $_plugin ]; then
        echo "获取插件test=====> $_plugin"
        cd $_plugin
        rm -rf pubspec.lock && flutter pub get
    fi
    _plugin=$root/plugin/$plugin
    if [ -d $_plugin ]; then
        echo "获取插件====> $_plugin"
        cd $_plugin
        rm -rf pubspec.lock && flutter pub get
    fi
done

# Platform-specific commands
case $platform in
ios | macos)
    echo ''
    echo "########## 清理$platform pod"
    echo ''
    cd $root/$platform
    rm -rf .symlinks
    rm -rf Pods
    rm -rf Podfile.lock
    pod repo update
    echo ''
    echo "########## $platform pod install"
    echo ''
    pod install
    echo ''
    echo "########## $platform build"
    echo ''
    # flutter build ios
    ;;

android)
    echo ''
    echo "########## 清理$platform"
    echo ''
    cd $root/$platform
    # Add any Android-specific cleaning commands here

    echo ''
    echo "########## $platform build"
    echo ''
    # flutter build apk
    ;;

web)
    echo ''
    echo "########## 清理$platform"
    echo ''
    cd $root/$platform
    # Add any Web-specific cleaning commands here

    echo ''
    echo "########## $platform build"
    echo ''
    # flutter build web
    ;;

windows | linux)
    echo ''
    echo "########## 清理$platform"
    echo ''
    cd $root/$platform
    # Add any Desktop-specific cleaning commands here

    echo ''
    echo "########## $platform build"
    echo ''
    # flutter build $platform
    ;;

*)
    echo "Unsupported platform: $platform"
    exit 1
    ;;
esac

read -p '执行完成，输入任意键退出...'
exit 0
