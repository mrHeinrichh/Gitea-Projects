#!/bin/bash

set -e

if [ $# -lt 1 ]; then
    echo "Usage: $0 app路径"
    exit 1
fi

cd $1

cd android

###随机值
r=$RANDOM
keypass="android$r"
filename="gf_$r.keystore"
keyalias="key$r"

#这个工具不一定在这个目录，具体问题具体分析。
kt="/System/Volumes/Data/Applications/Android Studio.app/Contents/jre/jdk/Contents/Home/bin/keytool"

"$kt" -genkeypair -alias $keyalias -keypass $keypass -keystore $filename -storepass $keypass -dname "CN=Android $r,O=Android,C=US" -validity 9999 -deststoretype pkcs12

rm -f app/keystore/gf_*
mv $filename app/keystore

#storeFile
n_storeFile=$(grep -n storeFile ./app/build.gradle | cut -f1 -d:)
sed_cmd_1="${n_storeFile}c  storeFile file('keystore/$filename')"
# echo "替换 storeFile: $sed_cmd_1"

#storePassword
n_storePassword=$(grep -n storePassword ./app/build.gradle | cut -f1 -d:)
sed_cmd_2="${n_storePassword}c storePassword '$keypass'"
# echo "替换 storePassword: $sed_cmd_2"

#keyAlias
n_keyAlias=$(grep -n keyAlias ./app/build.gradle | cut -f1 -d:)
sed_cmd_3="${n_keyAlias}c keyAlias '$keyalias'"
# echo "替换 keyAlias: $sed_cmd_3"

#keyPassword
n_keyPassword=$(grep -n keyPassword ./app/build.gradle | cut -f1 -d:)
sed_cmd_4="${n_keyPassword}c keyPassword '$keypass'"
# echo "替换 keyPassword: $sed_cmd_4"

cat ./app/build.gradle | gsed "$sed_cmd_1" | gsed "$sed_cmd_2" | gsed "$sed_cmd_3" | gsed "$sed_cmd_4" >1
mv 1 app/build.gradle
echo "替换完成"

exit 0
