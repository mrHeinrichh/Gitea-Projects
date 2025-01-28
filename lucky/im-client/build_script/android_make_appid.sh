#!/bin/bash

set -e

if [ $# -lt 1 ]; then
    echo "Usage: $0 app路径"
    exit 1
fi

cd $1
cd android

a=$(grep 'applicationId "' app/build.gradle | tr -d '"')
appId=$(python -c "print('$a'.strip().split(' ')[1])")
echo "当前包名:$appId"

#brew install md5sha1sum
i1=$(head /dev/urandom | cksum | md5sum | cut -c 1-9)
i2=$(head /dev/urandom | cksum | md5sum | cut -c 1-9)
new_appId="com.j${i1}.y${i2}"
echo "随机包名:$new_appId"
sed_cmd="s/$appId/$new_appId/g"

for i in $(grep -rl "$appId" .); do
    if [[ $i == *executionHistory* ]]; then
        continue
    fi

    echo $i
    gsed -i "$sed_cmd" $i
done

echo $new_appId
exit 0
