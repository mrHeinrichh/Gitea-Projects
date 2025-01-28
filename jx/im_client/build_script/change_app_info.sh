#!/bin/sh
set -e

if [ $# -lt 1 ]; then
    echo "Usage: $0 app路径"
    exit 1
fi
cd $1

channelId=''
skin=''
icon=''
appCnName=''
appId=''
openinstallId=''
while [ "$channelId" == '' ]; do
    if [ "$2" == '' ]; then
        read -p "请确认打包渠道? [1,2]: " channelId
    else
        let channelId=$2
    fi
    # echo $pkgAsk
    case $channelId in
    1)
        channelId='channel_1'
        skin='my_skin_1'
        icon='my_icon_1'
        appCnName='测试包'
        appId='com.release.app'
        openinstallId='abcd123'
        typeHead='0'
        ;;
    2)
        channelId='channel_2'
        skin='my_skin_2'
        icon='my_icon_2'
        appCnName='测试包'
        appId='com.release.app2'
        openinstallId=''
        typeHead='0'
        ;;
    *)
        if [ "$2" == '' ]; then
            echo "请输入有效的渠道!"
            channelId=''
        else
            echo "请输入有效的渠道!"
            exit 1
        fi
        ;;
    esac
done

echo "start pkg, $channelId"

echo 拷贝conf.dart
cp -f lib/conf.dart.${channelId}.dist lib/conf.dart
echo 修改ios的appid
if [ -f "build_script/linux_sed" ]; then
    sed -ri "s/(\s*PRODUCT_BUNDLE_IDENTIFIER = )[^\"]*/\1$appId;/" ios/Runner.xcodeproj/project.pbxproj
else
    sed -ri '' "s/(\s*PRODUCT_BUNDLE_IDENTIFIER = )[^\"]*/\1$appId;/" ios/Runner.xcodeproj/project.pbxproj
fi

echo 修改ios的中文名
rowNum=$(grep -n \<key\>CFBundleDisplayName\<\/key\> ios/Runner/info.plist | awk -F ':' '{ print $1;}')
let rowNum+=1
if [ -f "build_script/linux_sed" ]; then
    sed -i "${rowNum}s/.*/	<string>$appCnName<\/string>/g" ios/Runner/info.plist
else
    sed -i '' "${rowNum}s/.*/	<string>$appCnName<\/string>/g" ios/Runner/info.plist
fi
rowNum=$(grep -n \<key\>CFBundleName\<\/key\> ios/Runner/info.plist | awk -F ':' '{ print $1;}')
let rowNum+=1
if [ -f "build_script/linux_sed" ]; then
    sed -i "${rowNum}s/.*/	<string>$appCnName<\/string>/g" ios/Runner/info.plist
else
    sed -i '' "${rowNum}s/.*/	<string>$appCnName<\/string>/g" ios/Runner/info.plist
fi

echo 修改android的中文名
if [ -f "build_script/linux_sed" ]; then
    sed -ri "s/(\s*android:label=\")[^$]*/\1$appCnName\"/" android/app/src/main/AndroidManifest.xml
else
    sed -ri '' "s/(\s*android:label=\")[^$]*/\1$appCnName\"/" android/app/src/main/AndroidManifest.xml
fi

echo 修改openinstall的id
#安卓
if [ -f "build_script/linux_sed" ]; then
    sed -ri "s/(\s*OPENINSTALL_APPKEY)[^$]*/\1      : \"$openinstallId\",/" android/app/build.gradle
else
    sed -ri '' "s/(\s*OPENINSTALL_APPKEY)[^$]*/\1      : \"$openinstallId\",/" android/app/build.gradle
fi
if [ -f "build_script/linux_sed" ]; then
    sed -ri "s/(\s*<data android:scheme=\")[^$]*/\1$openinstallId\" \/>/" android/app/src/main/AndroidManifest.xml
else
    sed -ri '' "s/(\s*<data android:scheme=\")[^$]*/\1$openinstallId\" \/>/" android/app/src/main/AndroidManifest.xml
fi
rowNum=$(grep -n android:name=\"com.openinstall.APP_KEY\" ./android/app/src/main/AndroidManifest.xml | awk -F ':' '{ print $1;}')
let rowNum+=1
if [ -f "build_script/linux_sed" ]; then
    sed -i "${rowNum}s/.*/      android:value=\"$openinstallId\"/g" ./android/app/src/main/AndroidManifest.xml
else
    sed -i '' "${rowNum}s/.*/      android:value=\"$openinstallId\"/g" ./android/app/src/main/AndroidManifest.xml
fi
#苹果
rowNum=$(grep -n \.openinstall\.io ios/Runner/RunnerDebug.entitlements | awk -F ':' '{ print $1;}')
if [ -f "build_script/linux_sed" ]; then
    sed -i "${rowNum}s/.*/		<string>applinks:$openinstallId.openinstall.io<\/string>/g" ios/Runner/RunnerDebug.entitlements
else
    sed -i '' "${rowNum}s/.*/		<string>applinks:$openinstallId.openinstall.io<\/string>/g" ios/Runner/RunnerDebug.entitlements
fi
rowNum=$(grep -n \.openinstall\.io ios/Runner/RunnerDebug.entitlements | awk -F ':' '{ print $1;}')
if [ -f "build_script/linux_sed" ]; then
    sed -i "${rowNum}s/.*/		<string>applinks:$openinstallId.openinstall.io<\/string>/g" ios/Runner/RunnerProfile.entitlements
else
    sed -i '' "${rowNum}s/.*/		<string>applinks:$openinstallId.openinstall.io<\/string>/g" ios/Runner/RunnerProfile.entitlements
fi
rowNum=$(grep -n \.openinstall\.io ios/Runner/RunnerDebug.entitlements | awk -F ':' '{ print $1;}')
if [ -f "build_script/linux_sed" ]; then
    sed -i "${rowNum}s/.*/		<string>applinks:$openinstallId.openinstall.io<\/string>/g" ios/Runner/RunnerRelease.entitlements
else
    sed -i '' "${rowNum}s/.*/		<string>applinks:$openinstallId.openinstall.io<\/string>/g" ios/Runner/RunnerRelease.entitlements
fi
rowNum=$(grep -n \<string\>openinstall\<\/string\> ios/Runner/info.plist | awk -F ':' '{ print $1;}')
let rowNum+=3
if [ -f "build_script/linux_sed" ]; then
    sed -i "${rowNum}s/.*/				<string>$openinstallId<\/string>/g" ios/Runner/info.plist
else
    sed -i '' "${rowNum}s/.*/				<string>$openinstallId<\/string>/g" ios/Runner/info.plist
fi
rowNum=$(grep -n \<key\>com.openinstall.APP_KEY\<\/key\> ios/Runner/info.plist | awk -F ':' '{ print $1;}')
let rowNum+=1
if [ -f "build_script/linux_sed" ]; then
    sed -i "${rowNum}s/.*/	<string>$openinstallId<\/string>/g" ios/Runner/info.plist
else
    sed -i '' "${rowNum}s/.*/	<string>$openinstallId<\/string>/g" ios/Runner/info.plist
fi

#皮肤
sh skin/$skin/import.sh
#图标
sh icon/$icon/import.sh

echo $appCnName $icon $typeHead

exit 0
