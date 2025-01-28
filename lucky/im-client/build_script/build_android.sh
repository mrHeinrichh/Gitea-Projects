#!/bin/sh
set -e

#echo "请输入打包类型："
#read buildType

#echo "请输入渠道："
#read channel

buildType=$1
channel=$2
#version=$3

## 修改配置文件
if [ $buildType == "profile" ]; then
  sed -i "" "s/.*ORG_CHANNEL.*/  \"ORG_CHANNEL\": $channel/g" ../profile.json
else
	echo "Invalid Target"
	exit 1
fi

# 获取版本号
fullVersion=$(echo | grep -i -e "version: " ../pubspec.yaml)
version=$(echo $fullVersion | cut -d " " -f 2 | cut -d "+" -f 1)
buildNo=$(echo $fullVersion | cut -d "+" -f 2 )
echo "Version $version+$buildNo+$buildType+$channel"

#if [ $# -lt 1 ]; then
#    echo "Usage: $0 版本号 设备类型 appId app路径"
#    exit 1
#fi
#
#version=$1
#deviceType=$2
#appId=$3
#src=$4
#
#shOutInfo=$(./android_make_appid.sh $src)
#if [ $? != "0" ]; then
#    echo 打包android时修改更换出错
#    exit $?
#fi
#new_appId=$(echo $shOutInfo | awk 'END {print $NF}')
#
#./android_make_key.sh $src
#if [ $? != "0" ]; then
#    echo 打包android时修改key出错
#    exit $?
#fi
#
#./change_conf.sh $version $deviceType $src
#if [ $? != "0" ]; then
#    echo 打包android时修改配置文件出错
#    exit $?
#fi
#
#_name=${src##*/}
#echo "项目 $_name"
#cd $src
#
##处理一下输出文件夹
root_path=$(pwd)
cd ..
main_path=$(pwd)
mkdir -p ~/Desktop/$buildType
cd ~/Desktop/$buildType
mkdir -p apk
cd apk
apk_path=$(pwd)
cd $root_path

#file_name="$apk_path/${appId}-${new_appId}-${version}_app.apk"
#echo $file_name
##删掉旧的编译文件
#rm -f build/app/outputs/flutter-apk/app-release.apk

#换conf.dart文件
cd ../lib
cp conf.dart.dst conf.dart

cd $root_path
##处理一下输出文件
file_name="$apk_path/$buildType-v$version+$buildNo.apk"
echo "BuildType: $buildType"
if [ $buildType == "profile" ]; then
	sed -i '' 's|^storeFile=.*|storeFile=/Users/mikko/JX/code/im-client-ph-jenkins/android/upload-keystore.jks|' ../android/key.properties
	flutter build apk --dart-define-from-file=profile.json --profile

	#拷贝到目标去
	echo "copying apk"
	cp -f $main_path/build/app/outputs/flutter-apk/app-profile.apk $file_name

	#推去AWS S3
	S3_BUCKET_NAME="jtalk/build-apk"
	/opt/homebrew/bin/aws s3 cp "$file_name" "s3://$S3_BUCKET_NAME/"

	#创QR
	OBJECT_URL="https://jtalk.s3.ap-southeast-1.amazonaws.com/build-apk/$buildType-v$version%2B$buildNo.apk"
	echo "$OBJECT_URL" > ~/Desktop/$buildType/apk/apk.txt

	# Output the object URL
	echo "File uploaded successfully!"
	echo "Object URL: $OBJECT_URL"

	# Generate QR code with the object URL
	QR_CODE_FILENAME="$apk_path/$buildType-v$version+$buildNo-qr.png"
	/opt/homebrew/bin/qrencode -o "$QR_CODE_FILENAME" "$OBJECT_URL"
	echo "QR code generated: $QR_CODE_FILENAME"

	exit 0
elif [ $buildType == "release" ]; then
	sed -i '' 's|^storeFile=.*|storeFile=/Users/mikko/JX/code/im-client-ph-jenkins/android/upload-keystore.jks|' ../android/key.properties
	flutter build apk --dart-define-from-file=release.json --release

	#拷贝到目标去
	echo "copying apk"
	cp -f $main_path/build/app/outputs/flutter-apk/app-release.apk $file_name

	#推去AWS S3
	S3_BUCKET_NAME="jtalk/build-apk"
	/opt/homebrew/bin/aws s3 cp "$file_name" "s3://$S3_BUCKET_NAME/"

	#创QR
	OBJECT_URL="https://jtalk.s3.ap-southeast-1.amazonaws.com/build-apk/$buildType-v$version%2B$buildNo.apk"
	echo "$OBJECT_URL" > ~/Desktop/$buildType/apk/apk.txt

	# Output the object URL
	echo "File uploaded successfully!"
	echo "Object URL: $OBJECT_URL"

	# Generate QR code with the object URL
	QR_CODE_FILENAME="$apk_path/$buildType-v$version+$buildNo-qr.png"
	/opt/homebrew/bin/qrencode -o "$QR_CODE_FILENAME" "$OBJECT_URL"
	echo "QR code generated: $QR_CODE_FILENAME"

	exit 0
else
	echo "Invalid buildTyped"
	exit 1
fi
