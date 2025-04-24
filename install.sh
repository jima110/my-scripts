#!/bin/bash

# 更新软件包并安装 Docker
apt update -y
apt install -y docker.io curl

# 启动 Docker 并设置为开机自启动
systemctl start docker
systemctl enable docker

# 生成设备 ID（64位十六进制随机字符串）
DEVICE_ID=$(cat /dev/urandom | LC_ALL=C tr -dc 'A-F0-9' | dd bs=1 count=64 2>/dev/null)
DEVICE_NAME="EC2-$(hostname)-$(date +%Y%m%d%H%M%S)"

# 你的 Proxyrack API Key（请替换为你自己的 API 密钥）
API_KEY="AHGSFHP4ORI27ZS3BFZGU1MIFMBAXEGPMAZLAVRN"

# 拉取并运行 Proxyrack 容器
docker pull proxyrack/pop
docker run -d --name proxyrack --restart always -e UUID="$DEVICE_ID" proxyrack/pop

# 等待容器启动完成
sleep 10

# 通过 Proxyrack API 自动注册设备
curl -X POST https://peer.proxyrack.com/api/device/add \
  -H "Api-Key: $API_KEY" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d "{\"device_id\":\"$DEVICE_ID\",\"device_name\":\"$DEVICE_NAME\"}"

# 打印设备 ID 和设备名称（供检查）
echo "Device ID: $DEVICE_ID"
echo "Device Name: $DEVICE_NAME"