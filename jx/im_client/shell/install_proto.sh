#!/bin/bash

# Step 1: 安装 protoc Dart 插件
echo "Installing protoc Dart plugin..."
dart pub global activate protoc_plugin

# Step 2: 添加插件路径到 PATH 环境变量
echo "Adding protoc plugin to PATH..."
if [[ ":$PATH:" != *":$HOME/.pub-cache/bin:"* ]]; then
    export PATH="$PATH:$HOME/.pub-cache/bin"
    echo 'export PATH="$PATH:$HOME/.pub-cache/bin"' >>~/.bashrc
    echo "PATH updated successfully."
else
    echo "PATH already contains protoc plugin path."
fi

# Step 3: 生成 Dart 代码
# echo "Generating Dart code from .proto file..."
# protoc --dart_out=. push_client_message.proto

echo "Dart code generation completed!"

# Step 4: 需要更新下 update_block_bean.dart
