#!/bin/bash

# 定义要搜索的文件和URL前缀
file_path="pubspec.yaml"
url_prefix="https://2a5d16efb3659d15f497f5672357bf7a2780692d[^ ]*"
target_directory="$HOME/Desktop/plugins" # 目标目录
target_branch="im-release"               # 目标合并分支
source_branch="im-ph"                    # 目标合并分支

current_branch=$(git rev-parse --abbrev-ref HEAD)
if [ "$current_branch" != "$target_branch" ]; then
    echo "Current branch is not '$target_branch', exit."
    exit 1
fi

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

    git checkout $target_branch
    git reset --hard
    git pull origin $target_branch

    git merge $source_branch -Xignore-space-change

    if [ $? -eq 0 ]; then
        echo "【${target_directory/$repo_name/}】 Merge was successful."
    else
        echo "Merge encountered problems."
        # 检查是否因为冲突而失败
        if git status | grep -q 'conflict'; then
            echo "【${target_directory/$repo_name/}】 Merge failed due to conflicts."
            echo "Please resolve conflicts and then commit the result."
        fi
        exit 1
    fi

    # 返回到原始目录
    cd -
done <urls.txt

# 清理
rm urls.txt
