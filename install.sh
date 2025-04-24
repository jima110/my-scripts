#!/bin/bash

# 更新软件包并安装 Docker 和 curl
apt update -y
apt install -y docker.io curl

# 启动 Docker 并设置为开机自启动
systemctl start docker
systemctl enable docker

# 生成设备 ID 和设备名称
DEVICE_ID=$(cat /dev/urandom | LC_ALL=C tr -dc 'A-F0-9' | dd bs=1 count=64 2>/dev/null)
DEVICE_NAME="EC2-$(hostname)-$(date +%Y%m%d%H%M%S)"

# 替换为你自己的 Proxyrack API Key
API_KEY="AHGSFHP4ORI27ZS3BFZGU1MIFMBAXEGPMAZLAVRN"

# 拉取并运行 Proxyrack 容器
docker pull proxyrack/pop
docker run -d --name proxyrack --restart always -e UUID="$DEVICE_ID" proxyrack/pop

# 打印设备信息
echo "等待 Proxyrack 容器启动并被平台识别..."
echo "设备 ID: $DEVICE_ID"
echo "设备名称: $DEVICE_NAME"

# 最多等待 10 分钟，每 30 秒检查一次是否能注册成功
MAX_ATTEMPTS=20
ATTEMPT=1
SUCCESS=0

while [ $ATTEMPT -le $MAX_ATTEMPTS ]; do
    echo "第 $ATTEMPT 次尝试注册设备..."

    RESPONSE=$(curl -s -X POST https://peer.proxyrack.com/api/device/add \
      -H "Api-Key: $API_KEY" \
      -H "Content-Type: application/json" \
      -H "Accept: application/json" \
      -d "{\"device_id\":\"$DEVICE_ID\",\"device_name\":\"$DEVICE_NAME\"}")

    if echo "$RESPONSE" | grep -q '"status":"ok"'; then
        echo "✅ 设备成功注册！"
        SUCCESS=1
        break
    else
        echo "⚠️ 设备尚未就绪，等待 30 秒后重试..."
        sleep 30
    fi
    ((ATTEMPT++))
done

if [ $SUCCESS -eq 0 ]; then
    echo "❌ 在规定时间内未能自动添加设备，请稍后手动重试注册。"
    echo "最后返回结果: $RESPONSE"
fi