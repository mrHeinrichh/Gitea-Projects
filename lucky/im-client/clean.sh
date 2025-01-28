#!/bin/bash

# 脚本目录
cd $(dirname $0)
root=`pwd`
# 清理build目录
rm -rf build
# 清理插件
echo "########## 清理插件 无需点击vscode的Get packages "
echo ''
# rm -rf plugin
# git checkout plugin
flutter clean
flutter pub cache clean -f

echo ''
echo "########## 获取项目插件"
echo ''
rm -rf pubspec.lock && flutter pub upgrade

echo ''
echo "########## 获取项目插件列子项目插件"
echo ''
for plugin in `ls plugin`;  
do  
    echo $plugin/example
    _plugin=$root/plugin/$plugin/example
    if [ -d $_plugin ]; then
        echo "获取插件example=====> $plugin"
        cd $root
        rm -rf $_plugin/pubspec.lock
        cd $root/plugin/$plugin
        flutter pub upgrade
    fi
    _plugin=$root/plugin/$plugin/test
    if [ -d $_plugin ]; then
        echo "获取插件test=====> $plugin"
        cd $root
        rm -rf $_plugin/pubspec.lock
        cd $root/plugin/$plugin
        flutter pub upgrade
    fi
    _plugin=$root/plugin/$plugin
    if [ -d $_plugin ]; then
        echo "获取插件====> $plugin"
        cd $root
        rm -rf $_plugin/pubspec.lock
        cd $root/plugin/$plugin
        flutter pub upgrade
    fi
done

# 清理pod
echo ''
echo "########## 清理ios pod"
echo ''
cd $root/ios 
rm -rf Pods
rm Podfile.lock

echo ''
echo "########## ios pod install"
echo ''
pod install

# flutter build apk
# flutter build ios

# sh merge-im-ph.sh

read -p '执行完成，输入任意键退出...'
exit 0