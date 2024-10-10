#!/bin/sh
set -e

echo "请输入目标名称："
read targetName

cd ../macos

fullVersion=$(echo | grep -i -e "version: " ../pubspec.yaml)
version=$(echo $fullVersion | cut -d " " -f 2 | cut -d "+" -f 1)
buildNo=$(echo $fullVersion | cut -d "+" -f 2 )
echo "Version $version+$buildNo"

##处理一下输出文件夹
root_path=$(pwd)
cd ..
main_path=$(pwd)
cd ~/Desktop
mkdir -p macosapp
cd macosapp
app_path=$(pwd)
cd $root_path

##处理一下输出文件
file_name="$app_path/app-release-v$version.app"
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
elif [ $targetName == "HeyTalk" ]; then
	bundleID='com.jxsg.hey'
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
</plist>" >$main_path/build/macos/archive/ExportOptions.plist

#编译
echo "Target: $targetName"
if [ $targetName == "Runner" ]; then
	flutter build macos --dart-define-from-file=profile.json --release --export-options-plist $main_path/build/macos/archive/ExportOptions.plist
elif [ $targetName == "HeyTalk" ]; then
	flutter build macos --flavor $targetName --dart-define-from-file=release.json --release --export-options-plist $main_path/build/ios/archive/ExportOptions.plist
else
	echo "Invalid Target"
	exit 1
fi

xcodebuild -scheme $targetName archive -archivePath $main_path/build/macos/archive/macosapp.xcarchive
flutter build macos --dart-define-from-file=profile.json --release --export-options-plist $main_path/build/ios/archive/ExportOptions.plist



xcodebuild -exportArchive -exportFormat app \
  -archivePath $main_path/build/macos/archive/macosapp.xcarchive \
  -exportPath $file_name

echo "Copy app"
cp -f $main_path/build/macos/app/jxim_client.app $file_name

xcrun altool --upload-app --type macos -f $file_name --username admin@jiangxia.com.sg --password fmxn-qtzt-nmxl-xowd

rm -rf $build_folder
exit 0