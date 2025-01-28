#!/bin/bash

# 脚本目录
cd $(dirname $0)
root=$(pwd)
echo ''
echo "########## 获取项目插件列子项目插件"
echo ''
for plugin in $(ls plugin); do
    echo $plugin/example
    _plugin=$root/plugin/$plugin/example
    if [ -d $_plugin ]; then
        echo "获取插件example=====> $_plugin"
        cd $_plugin
        cp -rf $root/plugins.yaml $_plugin/analysis_options.yaml
    fi
    _plugin=$root/plugin/$plugin/test
    if [ -d $_plugin ]; then
        echo "获取插件test=====> $_plugin"
        cd $_plugin
        cp -rf $root/plugins.yaml $_plugin/analysis_options.yaml
    fi
    _plugin=$root/plugin/$plugin
    if [ -d $_plugin ]; then
        echo "获取插件====> $_plugin"
        cd $_plugin
        cp -rf $root/plugins.yaml $_plugin/analysis_options.yaml
    fi
done

read -p '执行完成，输入任意键退出...'
exit 0
