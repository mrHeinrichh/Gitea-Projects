#!/bin/sh
set -e

echo "请输入目标名称："
read targetName

echo "请输入渠道："
read channel

echo "是否Testfight版本："
read isTestflight

## 修改配置文件
if [ $targetName == "Runner" ]; then
  sed -i "" "s/.*IS_TESTFLIGHT.*/  \"IS_TESTFLIGHT\": $isTestflight,/g" ../profile.json
  sed -i "" "s/.*ORG_CHANNEL.*/  \"ORG_CHANNEL\": $channel/g" ../profile.json
else
	echo "Invalid Target"
	exit 1
fi

cd ../ios

##获取App的名字
appName=$(echo | grep -o '"APP_NAME": "[^"]*' ../profile.json | grep -o '[^"]*$')

fullVersion=$(echo | grep -i -e "version: " ../pubspec.yaml)
version=$(echo $fullVersion | cut -d " " -f 2 | cut -d "+" -f 1)
buildNo=$(echo $fullVersion | cut -d "+" -f 2 )
echo "$appName Version $channel+$isTestflight+$version+$buildNo"

##处理一下输出文件夹
root_path=$(pwd)
cd ..
main_path=$(pwd)
cd ~/Desktop
mkdir -p ipa
cd ipa
ipa_path=$(pwd)
cd $root_path

##处理一下输出文件
file_name="$ipa_path/app-release-v$version.ipa"
echo "root_path $root_path"
echo "main_path $main_path"
echo "file_name $file_name"

#获取开发者账号的id
teamID=$(grep 'DEVELOPMENT_TEAM = .*;' Runner.xcodeproj/project.pbxproj | awk '!visited[$3]++' | awk '{print $3}' | sed 's/.$//g')
echo "teamID $teamID"

#获取项目的Bundle Id
bundleID=`xcodebuild -showBuildSettings | grep PRODUCT_BUNDLE_IDENTIFIER | awk -F ' = ' '{print $2}'`

if [ $targetName == "Runner" ]; then
  bundleID='com.jiangxia.im'
elif [ $targetName == "UUTalk" ]; then
	bundleID='com.uutalk.im'
else
  echo "Invalid Target"
  exit 1
fi
echo "BundleID $bundleID"

#创建Plist
echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd\">
<plist version=\"1.0\">
<dict>
	<key>destination</key>
	<string>export</string>
	<key>method</key>
	<string>app-store</string>
	<key>signingStyle</key>
	<string>automatic</string>
	<key>stripSwiftSymbols</key>
	<true/>
	<key>teamID</key>
	<string>$teamID</string>
	<key>uploadBitcode</key>
	<false/>
	<key>uploadSymbols</key>
	<true/>
	<key>provisioningProfiles</key>
	<dict>
    <key>$bundleID</key>
    <string>$targetName</string>
    <key>$bundleID.NotificationService</key>
    <string>${targetName}NotificationService</string>
    <key>$bundleID.ImagePublish</key>
    <string>${targetName}ImagePublish</string>
  </dict>
</dict>
</plist>" >$main_path/build/ios/archive/ExportOptions.plist

#编译
echo "Target: $targetName"
if [ $targetName == "Runner" ]; then
	flutter build ipa --dart-define-from-file=profile.json --release --export-options-plist $main_path/build/ios/archive/ExportOptions.plist
else
	echo "Invalid Target"
	exit 1
fi

echo "Copy IPA"
cp -f $main_path/build/ios/ipa/$appName.ipa $file_name

if $isTestflight; then
  xcrun altool --upload-app --type ios -f $file_name --username admin@jiangxia.com.sg --password fmxn-qtzt-nmxl-xowd
fi

rm -rf $build_folder
exit 0