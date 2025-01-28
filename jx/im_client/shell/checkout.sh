#!/bin/bash
cd $(dirname $0)
home=`pwd`
source_branch=$1

if [ -z "$source_branch" ]; then
    read -p '请输入分支名...'
    exit 0
fi
# 定义要搜索的文件和URL前缀
file_path="pubspec.yaml"
url_prefix="https://2a5d16efb3659d15f497f5672357bf7a2780692d[^ ]*"
target_directory="$HOME/Desktop/plugins" # 目标目录

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

    # 切换到仓库目录
    cd "$target_directory/$repo_name"

    # 拉取最新代码并合并
    git checkout $source_branch
    git reset --hard
    git pull origin $source_branch

    # rm -rf "$target_directory/$repo_name/pubspec.lock"

    # cp -rf $home/analysis_options.yaml analysis_options.yaml
    # git add .
    # git commit -am "analysis_options.yaml"
    # git push origin $source_branch

    # 返回到原始目录
    cd -
done <urls.txt

# 清理
rm urls.txt

read -p '执行完成，输入任意键退出...'
exit 0
