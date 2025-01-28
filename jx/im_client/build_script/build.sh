#!/bin/sh
set -e

if [ "$2" != "1" ] && [ "$3" != "1" ] && [ "$4" != "1" ] && [ "$5" != "1" ]; then
    echo "没有要打的包"
    exit 1
fi

version=$(cat version)

echo "当前打包的版本号为: \033[32m $version \033[0m"
sleep 2
# while [ "$pkgAsk" != 'y' ]; do
#     read -p "请确认是否打包? [y/n]: " pkgAsk
#     # echo $pkgAsk
#     case $pkgAsk in
#     [yY][eE][sS] | [yY])
#         pkgAsk='y'
#         ;;
#     [nN][oO] | [nN])
#         exit 1
#         ;;
#     *)
#         echo "请输入有效的命令!"
#         ;;
#     esac
# done

root=$(pwd)
cd ..
app_path=$(pwd)
cd $root

shOutInfo=$(sh change_app_info.sh $app_path $1)
#echo change_app_info return $?
if [ $? != "0" ]; then
    exit $?
fi
# echo $shOutInfo
# echo ---------------
typeHead=$(echo $shOutInfo | awk 'END {print $NF}')
icon=$(echo $shOutInfo | awk 'END {print $(NF-1)}')
appCnName=$(echo $shOutInfo | awk 'END {print $(NF-2)}')

cd $app_path

#清理一下
flutter clean && flutter pub get
cd $root
echo $icon $appCnName $typeHead $app_path
#安卓
if [ "$2" == "1" ]; then
    echo 打包安卓
    sh build_android.sh $version ${typeHead}1 $icon${typeHead} $app_path
    if [ $? != "0" ]; then
        echo 安卓打包出错
        exit $?
    fi
fi

if [ "$3" == "1" ] || [ "$4" == "1" ] || [ "$5" == "1" ]; then
    cd $app_path
    cd ios && pod install && cd ..
    cd $root
    echo 打包个签
    if [ "$3" == "1" ]; then
        sh build_ios.sh $version ${typeHead}5 $icon${typeHead} $appCnName $app_path
        if [ $? != "0" ]; then
            echo 个签打包出错
            exit $?
        fi
    fi

    echo 打包企业签
    if [ "$4" == "1" ]; then
        sh build_ios.sh $version ${typeHead}4 $icon${typeHead} $appCnName $app_path
        if [ $? != "0" ]; then
            echo 个签打包出错
            exit $?
        fi
    fi

    echo 打包tf
    if [ "$5" == "1" ]; then
        sh build_ios.sh $version ${typeHead}3 $icon${typeHead} $appCnName $app_path
        if [ $? != "0" ]; then
            echo tf打包出错
            exit $?
        fi
    fi
fi
exit 0
