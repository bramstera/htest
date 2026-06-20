---
title: Hermes
emoji: 🤖
colorFrom: green
colorTo: blue
sdk: docker
app_port: 7860
pinned: false
---

# Hermes

基于 [hermes-agent](https://github.com/NousResearch/hermes-agent) 与 [hermes-web-ui](https://www.npmjs.com/package/hermes-web-ui) 的 Docker 部署，面向 Hugging Face Spaces。

## 版本

| 组件 | 版本 |
|------|------|
| `hermes-web-ui` | `0.6.17`（最新稳定版，要求 Node ≥ 23） |
| `hermes-agent` | 通过 `uv` 从官方仓库 `main` 安装（exact-pinned 依赖 + `uv.lock`） |
| 基础镜像 | `nikolaik/python-nodejs:python3.11-nodejs24` |

## 环境变量

| 变量 | 必填 | 说明 |
|------|------|------|
| `AUTH_TOKEN` | ✅ | Web-UI 访问认证 Token（同时用于 HuggingFace / Nous Portal） |
| `HERMES_MODEL_PROVIDER` | ❌ | 模型提供商：`openai`（默认）、`anthropic`、`openrouter`、`nous` |
| `HERMES_API_KEY` | ❌ | API Key（OpenAI/Anthropic 等） |
| `HERMES_MODEL` | ❌ | 模型名，默认 `gpt-4o` |
| `PORTAL_TOKEN` | ❌ | Nous Portal Token（当 provider 为 `nous` 时使用） |

## 模型配置示例

### OpenAI
```yaml
HERMES_MODEL_PROVIDER: openai
HERMES_API_KEY: sk-xxx
HERMES_MODEL: gpt-4o
```

### Nous Portal（推荐，免费额度）
```yaml
HERMES_MODEL_PROVIDER: nous
AUTH_TOKEN: your_portal_token
```

### Anthropic
```yaml
HERMES_MODEL_PROVIDER: anthropic
HERMES_API_KEY: sk-ant-xxx
HERMES_MODEL: claude-3-5-sonnet-20241022
```

## 架构

```
Port 5700 (外部) ← nginx ← Port 7860 (hermes-web-ui)
```

- **5700**: nginx 反向代理入口
- **7860**: Hermes Web-UI 服务端口
- 进程由 `pm2-runtime` 以前台方式托管，作为容器主进程（信号转发 + 日志聚合）

> 说明：本镜像以 **Web-UI 为唯一交互入口**。消息网关（Telegram/Discord 等）需要交互式 `hermes gateway setup`，不适合无状态容器，故未启用。如需网关，请在具备持久化配置的环境中单独运行 `hermes gateway setup && hermes gateway start`。
