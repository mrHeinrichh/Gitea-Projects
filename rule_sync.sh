#!/bin/bash
cd $(dirname $0)
root=$(pwd)
# 定义要搜索的文件和URL前缀
file_path="pubspec.yaml"
url_prefix="https://2a5d16efb3659d15f497f5672357bf7a2780692d[^ ]*"
target_directory="$HOME/Desktop/plugins" # 目标目录
target_branch="im-release"               # 目标合并分支
source_branch="im-ph"                    # 目标合并分支

mkdir -p $target_directory
# 从文件中提取所有匹配的URL
grep -o "${url_prefix}[^ ]*" "$file_path" | sort -u >urls.txt

# 读取URLs并处理
while IFS= read -r url; do

    # 从URL中解析出仓库名称
    repo_name=$(echo "$url" | awk -F'/' '{print $NF}')

    # 检查目标目录下是否存在仓库
    if [ ! -d "$target_directory/$repo_name" ]; then
        # 克隆仓库
        git clone "https://gitea.cyberbot.work/jx-im-plugin/${repo_name}" "$target_directory/$repo_name"
        echo "Repository cloned: $repo_name"
    else
        echo "Repository already exists: $repo_name"
    fi

    # 切换到仓库目录re
    cd "$target_directory/$repo_name"

    # git reset --hard
    # git checkout $source_branch
    # git pull

    # cp -rf ${root}/analysis_options.yaml analysis_options.yaml
    # rm -rf pubspec.lock && flutter pub get

    # rm -rf pubspec.lock && flutter pub get

    # git commit -m "ss" analysis_options.yaml
    # git push

    # 返回到原始目录
    cd -
done <urls.txt

# 清理
rm urls.txt

read -p '执行完成，输入任意键退出...'
exit 0
