#!/bin/bash

# 定义颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # 没有颜色

# 获取当前分支名
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

# 提示用户输入目标分支名
echo "${GREEN}请输入要切换的目标分支名 (默认分支：$CURRENT_BRANCH):${NC} "
read BRANCH

# 如果用户没有输入，使用当前分支
if [ -z "$BRANCH" ]; then
  BRANCH=$CURRENT_BRANCH
  echo "未输入目标分支名，使用当前分支 '$BRANCH'"
fi

git reset --hard
git fetch --prune
flutter pub get

# 检查目标分支是否存在于远程
REMOTE_BRANCH_EXISTS=$(git ls-remote --heads origin "$BRANCH")
if [ -z "$REMOTE_BRANCH_EXISTS" ]; then
  echo "${RED}远程分支 '$BRANCH' 不存在，请检查分支名称。${NC}"
  exit 1
fi

# 步骤 2：切换到基础分支 im-ph
BASE_BRANCH="im-ph"

if [[ "$BRANCH" == "$BASE_BRANCH" && "$CURRENT_BRANCH" == "$BASE_BRANCH" ]]; then
  # 如果当前分支已经是 im-ph，直接拉取更新并执行 Flutter 脚本
  echo "当前已在分支 '$BASE_BRANCH'，正在拉取最新代码..."
  git pull origin "$BASE_BRANCH"

  if [ $? -ne 0 ]; then
    echo "${RED}拉取代码失败，请手动检查。${NC}"
    exit 1
  fi

else

  # 如果当前分支不是 im-ph，切换到基础分支
  echo "正在切换到基础分支 '$BASE_BRANCH'..."
  git reset --hard
  git checkout "$BASE_BRANCH"

  if [ $? -ne 0 ]; then
    echo "${RED}切换到基础分支失败，请手动检查。${NC}"
    exit 1
  fi

  if [ "$BRANCH" != "$BASE_BRANCH" ]; then

    # 检查本地是否存在该分支
    if git show-ref --verify --quiet refs/heads/"$BRANCH"; then
      # 本地分支存在，先删除本地分支
      echo "本地存在分支 '$BRANCH'，正在删除本地分支..."
      git branch -D "$BRANCH"

      if [ $? -ne 0 ]; then
        echo "${RED}删除本地分支失败，请检查问题。${NC}"
        exit 1
      fi
    fi

    # 从远程拉取并切换到目标分支
    echo "正在从远程拉取并切换到分支 '$BRANCH'..."
    git checkout -b "$BRANCH" origin/"$BRANCH"

    if [ $? -ne 0 ]; then
      echo "${RED}切换分支失败，请检查问题。${NC}"
      exit 1
    fi
  fi

  git pull

  if [ $? -ne 0 ]; then
    echo "${RED}分支拉取失败，请检查问题。${NC}"
    exit 1
  fi
fi

# 询问用户是否清理未提交的更改和未跟踪文件
echo "${GREEN}是否需要清理并重新拉取新的插件？(y/N):${NC} "
read CLEAN_CHOICE

# 获取可用设备列表
echo "正在获取可用设备列表..."
DEVICE_LIST=$(flutter devices | grep "•" | grep -v "Error")

# 解析设备列表并显示选项
AVAILABLE_DEVICES=()
DEVICE_IDS=()

# 使用正则表达式来精确提取设备ID
while IFS= read -r line; do
  # 提取设备ID，设备ID通常位于设备描述后的位置，以空格和 "•" 分隔
  DEVICE_ID=$(echo "$line" | awk -F ' • ' '{print $2}' | awk '{print $1}')
  # 确保设备ID不为空并添加到列表中
  if [ -n "$DEVICE_ID" ]; then
    AVAILABLE_DEVICES+=("$line")
    DEVICE_IDS+=("$DEVICE_ID")
  fi
done <<<"$DEVICE_LIST"

if [ ${#AVAILABLE_DEVICES[@]} -eq 0 ]; then
  echo "${RED}没有找到可用设备，请连接设备后重试。${NC}"
  exit 1
fi

echo "可用设备："
for i in "${!AVAILABLE_DEVICES[@]}"; do
  echo "${GREEN}$((i + 1))) ${AVAILABLE_DEVICES[$i]}${NC}"
done

# 提示用户选择设备
echo "请选择要运行的设备编号 (例如 1):"
read DEVICE_NUMBER

# 如果用户没有输入，默认选择第一个设备
if [ -z "$DEVICE_NUMBER" ]; then
  DEVICE_NUMBER=1
  echo "未输入设备编号，默认选择第一个设备: ${AVAILABLE_DEVICES[0]}"
fi

# 验证用户输入的设备编号
if [[ ! "$DEVICE_NUMBER" =~ ^[1-9][0-9]*$ ]] || [ "$DEVICE_NUMBER" -gt "${#AVAILABLE_DEVICES[@]}" ]; then
  echo "${RED}无效的设备编号，请重试。${NC}"
  exit 1
fi

# 获取选中的设备ID
SELECTED_DEVICE="${DEVICE_IDS[$((DEVICE_NUMBER - 1))]}"

echo "您选择的设备ID为: $SELECTED_DEVICE"

# 检查用户选择是否为 'y' 或 'Y'
if [[ "$CLEAN_CHOICE" == "y" || "$CLEAN_CHOICE" == "Y" ]]; then
  # 清理代码
  echo "正在清理未提交的更改和未跟踪的文件..."
  ./clean.sh ios 1 1
  if [ -f "./xcode16.sh" ]; then
    # Commands to run if the file exists
    ./xcode16.sh
  fi
  

  # 检查清理是否成功
  if [ $? -ne 0 ]; then
    echo "${RED}清理当前分支失败，请手动检查。${NC}"
    exit 1
  fi
else
  echo "未选择清理，保留未提交的更改和未跟踪的文件。"
fi

xcode_version=$(xcodebuild -version | grep "Xcode" | awk '{print $2}')

# Extract major and minor version numbers (e.g., "16.1" -> major=16, minor=1)
major_version=$(echo $xcode_version | cut -d '.' -f 1)
minor_version=$(echo $xcode_version | cut -d '.' -f 2)


# Compare the major version with 16, if major is 16 or higher, we're good
if [ "$major_version" -gt 16 ] || { [ "$major_version" -eq 16 ] && [ "$minor_version" -ge 0 ]; }; then
  echo "xcode 16处理"
  search_term="sentry_flutter"
  replacement_term="sentry_flutter: 8.9.0"
  # Check if the term exists in the pubspec.yaml file
  if grep -q "$search_term" "./pubspec.yaml"; then
    echo "'$search_term' found in pubspec.yaml. Replacing it with '$replacement_term'."
            
    # Perform the replacement from the search_term to the end of the line
    sed -i "" "s/\($search_term.*\)/$replacement_term/" "./pubspec.yaml"
    echo "Replacement complete."
  fi
  
  sentry_search_term="pod 'Sentry', '~> 8.32.0'"
  sentry_replacement_term="pod 'Sentry', '~> 8.36.0'"
  # Check if the term exists in the pubspec.yaml file
  if grep -q "$sentry_search_term" "./ios/Podfile"; then
    echo "'$sentry_search_term' found in iOS Podfile. Replacing it with '$sentry_replacement_term'."
            
    # Perform the replacement from the search_term to the end of the line
    sed -i "" "s/\($sentry_search_term.*\)/$sentry_replacement_term/" "./ios/Podfile"
    echo "Replacement complete."
  fi
  
  if grep -q "$sentry_search_term" "./macos/Podfile"; then
    echo "'$sentry_search_term' found in MacOS Podfile. Replacing it with '$sentry_replacement_term'."
            
    # Perform the replacement from the search_term to the end of the line
    sed -i "" "s/\($sentry_search_term.*\)/$sentry_replacement_term/" "./macos/Podfile"
    echo "Replacement complete."
  fi
  
  ssl_search_term="#Xcode16BoringSSL"
  ssl_term_1="if target.name == 'BoringSSL-GRPC'"
  ssl_term_2="  target.source_build_phase.files.each do |file|"
  ssl_term_3="    if file.settings \&\& file.settings['COMPILER_FLAGS']"
  ssl_term_4="      flags = file.settings['COMPILER_FLAGS'].split"
  ssl_term_5="      flags.reject! { |flag| flag == '-GCC_WARN_INHIBIT_ALL_WARNINGS' }"
  ssl_term_6="      file.settings['COMPILER_FLAGS'] = flags.join(' ')"
  ssl_term_7="    end"
  ssl_term_8="  end"
  ssl_term_9="end"
  
  # Run grep -q to check if search term exists in the file
  grep -q "$ssl_search_term" "./ios/Podfile"

  # Capture the exit status (0 if found, 1 if not found)
  ssl_result=$?
  
  if [ $ssl_result -eq 0 ]; then
    # Extract all characters before the search term, which will be the spaces
    spaces_before=$(grep -m 1 "$ssl_search_term" "./ios/Podfile" | sed -n "s/^\([[:space:]]*\).*/\1/p")
    
    ssl_term="$ssl_term_1\n$spaces_before$ssl_term_2\n$spaces_before$ssl_term_3\n$spaces_before$ssl_term_4\n$spaces_before$ssl_term_5\n$spaces_before$ssl_term_6\n$spaces_before$ssl_term_7\n$spaces_before$ssl_term_8\n$spaces_before$ssl_term_9"
    echo "'$ssl_search_term' found in ios Podfile. $spaces_before Replacing it with '$ssl_term'."
            
    # Perform the replacement from the search_term to the end of the line
    sed -i "" "s/\($ssl_search_term.*\)/$ssl_term/" "./ios/Podfile"
    echo "Replacement complete."
  fi
  
  # Run grep -q to check if search term exists in the file
  grep -q "$ssl_search_term" "./macos/Podfile"

  # Capture the exit status (0 if found, 1 if not found)
  mac_ssl_result=$?
  
  if [ $mac_ssl_result -eq 0 ]; then
    # Extract all characters before the search term, which will be the spaces
        spaces_before=$(grep -m 1 "$ssl_search_term" "./macos/Podfile" | sed -n "s/^\([[:space:]]*\).*/\1/p")
    
    ssl_term="$ssl_term_1\n$spaces_before$ssl_term_2\n$spaces_before$ssl_term_3\n$spaces_before$ssl_term_4\n$spaces_before$ssl_term_5\n$spaces_before$ssl_term_6\n$spaces_before$ssl_term_7\n$spaces_before$ssl_term_8\n$spaces_before$ssl_term_9"
    echo "'$ssl_search_term' found in macos Podfile. Replacing it with '$ssl_term'."
            
    # Perform the replacement from the search_term to the end of the line
    sed -i "" "s/\($ssl_search_term.*\)/$ssl_term/" "./macos/Podfile"
    echo "Replacement complete."
  fi
fi

# 执行 Flutter 脚本
echo "正在执行 Flutter 脚本..."
flutter run -d "$SELECTED_DEVICE" --dart-define-from-file=release.json --release
exit 0
