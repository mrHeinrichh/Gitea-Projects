#!/bin/sh
set -e

#echo "请输入目标名称："
#read targetName
targetName=$1

cd ../ios

fullVersion=$(echo | grep -i -e "version: " ../pubspec.yaml)
version=$(echo $fullVersion | cut -d " " -f 2 | cut -d "+" -f 1)
buildNo=$(echo $fullVersion | cut -d "+" -f 2 )
echo "Version $version+$buildNo"

##处理一下输出文件夹
root_path=$(pwd)
cd ..
main_path=$(pwd)
cd ~/Desktop/$targetName
mkdir -p ipa
cd ipa
ipa_path=$(pwd)
cd $root_path
mkdir -p $main_path/build/ios/archive

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
  	bundleID='com.luckyd.im'
elif [ $targetName == "HeyTalk" ]; then
	bundleID='com.jxsg.hey'
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
if [ $targetName == "Runner1" ]; then
	flutter build ipa --dart-define-from-file=profile.json --release --export-options-plist $main_path/build/ios/archive/ExportOptions.plist
elif [ $targetName == "HeyTalk" ]; then
	flutter build ipa --flavor $targetName --dart-define-from-file=release.json --release --export-options-plist $main_path/build/ios/archive/ExportOptions.plist
elif [ $targetName == "UUTalk" ]; then
	flutter build ipa --flavor UUTalk --dart-define-from-file=uutalk.json --release
elif [ $targetName == "Runner" ]; then
	flutter build ipa --flavor Runner --dart-define-from-file=profile.json --release
else
	echo "Invalid Target"
	exit 1
fi

echo "Copy IPA"
cp -f $main_path/build/ios/ipa/jxim_client.ipa $file_name

xcrun altool --upload-app --type ios -f $file_name --username admin@jiangxia.com.sg --password fmxn-qtzt-nmxl-xowd

rm -rf $build_folder
exit 0













#if [ $# -lt 5 ]; then
#	echo "Usage: $0 版本号 打包类型(2-6) app简写 app中文名 app路径"
#	exit 1
#fi
#
#version=$1
#let deviceType=$2
#deviceType="$deviceType"
#appId=$3
#appName=$4
#
##./change_conf.sh $version $deviceType $5
##if [ $? != "0" ]; then
##	echo 打包ios时修改配置文件出错
##	exit $?
##fi
#cd $5
#
#src=$5
#_name=${src##*/}
#echo "项目 $_name"
#
##识别编译类型
#buildType='ios'
#if [ $deviceType == "3" ] || [ $deviceType == "13" ]; then
#	buildType='tf'
#elif [ $deviceType == "4" ] || [ $deviceType == "14" ]; then
#	buildType='qy'
#elif [ $deviceType == "5" ] || [ $deviceType == "15" ]; then
#	buildType='gq'
#elif [ $deviceType == "6" ] || [ $deviceType == "16" ]; then
#	buildType='appstore'
#else
#	echo deviceType $deviceType err
#	exit 1
#fi
#
##先编译到临时文件夹,完事以后,拷贝到目标目录
#build_folder=~/Documents/AppBuild/tmp/$_name/$appId/$version/$buildType
#echo "编译地址 $build_folder"
#rm -rf $build_folder
#mkdir -p $build_folder
#
#cd ios
#
##获取开发者账号的id
#teamID=$(grep 'DEVELOPMENT_TEAM = .*;' Runner.xcodeproj/project.pbxproj | awk '!visited[$3]++' | awk '{print $3}' | sed 's/.$//g')
#echo "teamID $teamID"
##xcode上的项目名
#workspace_name=$(find . -name *.xcworkspace | awk -F "[/.]" '{print $(NF-1)}')
#scheme_name=${workspace_name}
#file_name=${build_folder}/${scheme_name}$(date +%Y%m%d%H%M)
#
#echo "开始构建"
#xcodebuild archive -workspace ${workspace_name}.xcworkspace -scheme ${scheme_name} -configuration Release -archivePath ${file_name}.xcarchive
#
#if ! [ -d "${file_name}.xcarchive" ]; then
#	echo "编译出错,xcarchive文件不存在"
#	exit 1
#fi
#
#echo "构建ExportOptions.plist"
#if [ $deviceType == "3" ] || [ $deviceType == "6" ]; then
#	echo "导出类型 app-store"
#	echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?>
#<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd\">
#<plist version=\"1.0\">
#<dict>
#	<key>destination</key>
#	<string>export</string>
#	<key>method</key>
#	<string>app-store</string>
#	<key>signingStyle</key>
#	<string>automatic</string>
#	<key>stripSwiftSymbols</key>
#	<true/>
#	<key>teamID</key>
#	<string>$teamID</string>
#	<key>uploadBitcode</key>
#	<false/>
#	<key>uploadSymbols</key>
#	<true/>
#	<key>provisioningProfiles</key>
#	<dict>
#    <key>com.luckyd.im</key>
#    <string>jxim</string>
#    <key>com.luckyd.im.ImagePublish</key>
#    <string>jximImagePublish</string>
#    <key>com.luckyd.im.NotificationService</key>
#    <string>jximNotificationService</string>
#  </dict>
#</dict>
#</plist>" >$build_folder/ExportOptions.plist
#else
#	echo "导出类型 ad-hoc"
#	echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?>
#<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">
#<plist version=\"1.0\">
#<dict>
#	<key>compileBitcode</key>
#	<true/>
#	<key>destination</key>
#	<string>export</string>
#	<key>method</key>
#	<string>app-store</string>
#	<key>signingStyle</key>
#	<string>automatic</string>
#	<key>stripSwiftSymbols</key>
#	<true/>
#	<key>teamID</key>
#	<string>$teamID</string>
#	<key>thinning</key>
#	<string>&lt;none&gt;</string>
#</dict>
#</plist>" >$build_folder/ExportOptions.plist
#fi
#
#echo "导出ipa"
#xcodebuild -exportArchive -archivePath ${file_name}.xcarchive -exportOptionsPlist $build_folder/exportOptions.plist -exportPath $build_folder -allowProvisioningUpdates
#
#cp -f $build_folder/$appName.ipa ~/Documents/AppBuild/$_name/${appId}_${version}_${buildType}.ipa
#
#xcrun altool --upload-app --type ios -f ~/Documents/AppBuild/$_name/${appId}_${version}_${buildType}.ipa --username admin@jiangxia.com.sg --password fmxn-qtzt-nmxl-xowd
#
#rm -rf $build_folder
#exit 0
