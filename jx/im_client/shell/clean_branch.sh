#!/bin/bash

# 获取所有本地分支
branches=$(git branch | sed 's/^[* ] //')

# 获取远程分支列表
remote_branches=$(git ls-remote --heads origin | awk '{print $2}' | sed 's#refs/heads/##')

# 遍历本地分支
for branch in $branches; do
    # 跳过主分支（如 master 或 main）
    if [[ "$branch" == "im-ph" || "$branch" == "im-release" ]]; then
        continue
    fi

    # 检查本地分支是否存在于远程分支列表中
    if ! echo "$remote_branches" | grep -q "^$branch\$"; then
        # 如果远程中不存在，则删除本地分支
        echo "Deleting local branch: $branch"
        git branch -D "$branch"
    fi
done

echo "清理完成！"
