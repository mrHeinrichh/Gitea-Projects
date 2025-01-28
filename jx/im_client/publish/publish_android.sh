#!/bin/bash

# 脚本目录
cd $(dirname $0)
cd ../
root=`pwd`

# build目录
cd ../
parent=`pwd`
build=$parent/build/android
if [ ! -d $build ]; then
    echo "没有找到build目录，请确认！！！！！"
    exit 1
fi

# 配置文件
info_json=$build/info.json
if [ ! -f $info_json ]; then
    echo "没有找到conf.json，请确认！！！！！"
    exit 2
fi
# 配置文件
launch_json=$build/launch.json
if [ ! -f $launch_json ]; then
    echo "没有找到launch.json，请确认！！！！！"
    exit 3
fi

# 版本号
version=`sed -n 18p $root/pubspec.yaml`
version=${version#*:}
version=${version// /}
echo "======编译版本号======"
echo $version

# 更新说明
info="修复了一些已知问题。"
echo "======默认更新说明======"
echo $info
echo ''

# 强制更新
read -p "是否设置最新版本号为当前版本强制更新（y/n）:" var_min

# 更新说明
read -p "请输入更新说明（可选）:" var_info
if [[ -n $var_info ]]; then
    info=$var_info
fi

# 自动提交git
read -p "是否自动执行git提交更新（y/n）:" var_git
if [[ $var_git =~ "y" ]]; then
    # git提交
    cd $build
    git pull
fi

# 构建apk
cd $root
rm -rf build
flutter build apk --release

# 拷贝apk
cp -rf $root/build/app/outputs/flutter-apk/app-release.apk $build/jxim.apk

# 修改的配置
echo "======版本号======"
echo $version
# 版本号
if [[ `uname  -a` =~ "Darwin" ]];then
	# mac
    sed -i '' 's/'"\"version"'\":.*/'"\"version"'\":'\"$version\",'/g' $info_json
else
    sed -i 's/'"\"version"'\":.*/'"\"version"'\":'\"$version\",'/g' $info_json
fi

echo "======最小版本号======"
echo $version
if [[ $var_min =~ "y" ]]; then
    if [[ `uname  -a` =~ "Darwin" ]];then
        # mac
        sed -i '' 's/'"\"minversion"'\":.*/'"\"minversion"'\":'\"$version\",'/g' $info_json
    else
        sed -i 's/'"\"minversion"'\":.*/'"\"minversion"'\":'\"$version\",'/g' $info_json
    fi
fi

echo "======更新说明======"
echo $info
# 更新说明
if [[ `uname  -a` =~ "Darwin" ]];then
	# mac
    sed -i '' 's/'"\"changelog"'\":.*/'"\"changelog"'\":'\"$info\",'/g' $info_json
else
    sed -i 's/'"\"changelog"'\":.*/'"\"changelog"'\":'\"$info\",'/g' $info_json
fi

# apk md5
md5=`md5 $build/jxim.apk | awk '{ print $4 }'`
echo "apk md5:$md5"
if [[ `uname  -a` =~ "Darwin" ]];then
	# mac
    sed -i '' 's/'"\"md5"'\":.*/'"\"md5"'\":'\"$md5\",'/g' $info_json
else
    sed -i 's/'"\"md5"'\":.*/'"\"md5"'\":'\"$md5\",'/g' $info_json
fi
# 大小
size=`ls -l $build/jxim.apk | awk '{print $5}'`
echo apk size $size
if [[ `uname  -a` =~ "Darwin" ]];then
	# mac
    sed -i '' 's/'"\"size"'\":.*/'"\"size"'\":'$size',/g' $info_json
else
    sed -i 's/'"\"size"'\":.*/'"\"size"'\":'$size',/g' $info_json
fi

# launch md5
md5=`md5 $info_json | awk '{ print $4 }'`
echo "launch md5:$md5"
if [[ `uname  -a` =~ "Darwin" ]];then
	# mac
    sed -i '' 's/'"\"md5"'\":.*/'"\"md5"'\":'\"$md5\"'/g' $launch_json
else
    sed -i 's/'"\"md5"'\":.*/'"\"md5"'\":'\"$md5\"'/g' $launch_json
fi

if [[ $var_git =~ "y" ]]; then
    # git提交
    cd $build
    if [ ! -f $build/.git/index.lock ]; then
        rm -rf $build/.git/index.lock 
    fi
    status=`git status`
    if [[ $status =~ '无文件要提交，干净的工作区' ]] || [[$status =~ 'working directory clean' ]]
    then
        echo "此次发布没有任何变化不需要git相关操作，请确认！！！"
    else
        git commit -am '安卓发布：'$version
        git pull
        git push
    fi
fi

cd $build
sh $build/rsync_back.sh 

read -p '执行完成，输入任意键退出...'

exit 0