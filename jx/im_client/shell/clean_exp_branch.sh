#!/bin/bash

# 先获取远程更新并删除已删除的远程分支
git fetch --prune

# 获取当前日期和 3 个月前的时间戳
current_date=$(date +%s)
threemonths_ago=$((current_date - 7776000)) # 3 个月前的时间戳，7776000 秒

# 定义需要排除的分支列表
exclude_branches=("im-release-backup") # 替换为实际分支名称

# 获取所有远程分支的最后提交日期
remote_branches=$(git for-each-ref --format='%(refname:short) %(committerdate:raw)' refs/remotes/origin | grep -v 'origin/main\|origin/master')

# 遍历所有远程分支
while IFS= read -r line; do
    branch=$(echo "$line" | awk '{split($1, a, "origin/"); print a[2]}')

    # 检查是否在排除列表中
    if [[ "${exclude_branches[@]}" =~ "$branch" ]]; then
        echo "跳过排除的分支: $branch"
        continue
    fi

    # if [[ "$branch" == im-ph-vincent-fix* ]]; then
    #     echo "将要删除的远程分支: $branch"
    #     git push origin --delete $branch
    # fi

    committer_date=$(echo "$line" | awk '{print $2}')

    # 检查提交日期是否超过 3 个月
    if [ "$committer_date" -lt "$threemonths_ago" ]; then
        echo "将要删除的远程分支: $branch"
        git push origin --delete $branch
    fi
done <<<"$remote_branches"

echo "清理完成！"
