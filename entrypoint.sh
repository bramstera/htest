#!/bin/bash
set -e

echo "===== Hermes 启动 at $(date) ====="

# 确保 PATH 包含 npm 全局 bin 和 uv 安装的工具
export PATH="/usr/lib/node_modules/.bin:/root/.local/bin:$PATH"

# 创建配置目录
mkdir -p ~/.hermes

# 写入 .env 配置（如果提供了环境变量）
if [ -n "$HERMES_MODEL_PROVIDER" ] || [ -n "$HERMES_API_KEY" ] || [ -n "$HERMES_MODEL" ]; then
    cat > ~/.hermes/.env << ENVEOF
HERMES_MODEL_PROVIDER=${HERMES_MODEL_PROVIDER:-openai}
HERMES_API_KEY=${HERMES_API_KEY:-}
HERMES_MODEL=${HERMES_MODEL:-gpt-4o}
AUTH_TOKEN=${AUTH_TOKEN:-}
PORTAL_TOKEN=${PORTAL_TOKEN:-}
ENVEOF
    echo "[配置] 已写入 ~/.hermes/.env"
else
    echo "[配置] 未提供模型配置，使用默认或已有配置"
fi

echo "===== 启动 nginx ====="
nginx -c /etc/nginx/nginx.conf
echo "nginx 已启动"

echo "===== 启动 hermes-web-ui ====="
# hermes-web-ui 自带守护进程管理（PID 文件 + stop/restart/status），
# 不能再叠加 PM2，否则前台 CLI fork 后退出 → PM2 反复重启 → "already running" 崩溃循环。
# 直接用 CLI 启动后台 server，再 tail 日志保活容器主进程。
hermes-web-ui start --port 7860

# 等待 server.log 出现后跟随它，保持容器存活并转发日志
LOG=/root/.hermes-web-ui/server.log
for i in $(seq 1 30); do [ -f "$LOG" ] && break; sleep 0.5; done
exec tail -f "$LOG"
