FROM docker.io/nikolaik/python-nodejs:python3.11-nodejs24

# 基础依赖
# build-essential + python3 + pkg-config 为 node-pty 等原生模块提供 node-gyp 工具链
RUN apt-get update && apt-get install -y --no-install-recommends \
    ripgrep ffmpeg git nginx lsof build-essential psmisc curl \
    python3 pkg-config \
    && rm -rf /var/lib/apt/lists/*

# 安装 uv（hermes-agent 官方推荐的安装方式）
RUN curl -LsSf https://astral.sh/uv/install.sh | sh
ENV PATH=/root/.local/bin:$PATH

# 安装 hermes-agent（通过 uv tool，使用仓库自带的 exact-pinned 依赖 + uv.lock）
RUN uv tool install --python 3.11 "hermes-agent @ git+https://github.com/NousResearch/hermes-agent.git"

# 安装 hermes-web-ui（最新稳定版，要求 node>=23）
# 注意：基础镜像已通过 corepack 自带 pnpm，重复安装会触发 EEXIST，故不再安装 pnpm
# 运行时由 hermes-web-ui 自带的守护进程管理，无需 PM2
# node-pty 为原生模块，prebuild 缺失时回退 node-gyp，依赖上面安装的 build-essential/python3
RUN npm install -g hermes-web-ui@0.6.17

# 配置文件
COPY entrypoint.sh /entrypoint.sh
COPY nginx.conf /etc/nginx/nginx.conf
COPY apps.conf /etc/nginx/conf.d/apps.conf
COPY ecosystem.config.js /app/ecosystem.config.js

RUN chmod +x /entrypoint.sh
ENV PATH=/usr/lib/node_modules/.bin:/root/.local/bin:$PATH

WORKDIR /app
COPY . /app/

EXPOSE 7860

ENTRYPOINT ["/entrypoint.sh"]
