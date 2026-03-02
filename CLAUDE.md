# Moltbot Sandbox

Fork of [cloudflare/moltworker](https://github.com/cloudflare/moltworker). Runs [OpenClaw](https://github.com/openclaw/openclaw) personal AI assistant in a Cloudflare Sandbox container.

## Architecture

```
Browser -> Cloudflare Worker (Hono, src/index.ts)
              |
              |-- HTTP proxy -> Sandbox Container (OpenClaw Gateway, port 18789)
              |-- WebSocket proxy (with server-side token injection)
              |-- Admin UI (/_admin/) protected by CF Access
              |-- API routes (/api/*) protected by CF Access
```

## Authentication Layers

1. **Cloudflare Access** - Protects admin routes (/_admin/*, /api/*, /debug/*). JWT validated in `src/auth/`.
2. **Gateway Token** - `MOLTBOT_GATEWAY_TOKEN` secret. Worker injects it server-side into WebSocket requests for the container. Mapped to `OPENCLAW_GATEWAY_TOKEN` in `src/gateway/env.ts`.
3. **Device Pairing** - OpenClaw's internal device approval via /_admin/.

## Key Files

- `src/index.ts` - Main Worker entry point. WebSocket proxy with token injection and error message transformation.
- `start-openclaw.sh` - Container startup script. R2 restore, config patching, background sync, gateway launch.
- `src/gateway/env.ts` - Maps Worker env vars to container env vars (e.g., MOLTBOT_GATEWAY_TOKEN -> OPENCLAW_GATEWAY_TOKEN).
- `src/gateway/process.ts` - Gateway process lifecycle (find existing, start new, wait for port).
- `src/auth/` - CF Access JWT verification and middleware.
- `src/routes/` - HTTP route handlers (admin UI, API, debug, public health).
- `wrangler.jsonc` - Cloudflare Worker config (container settings, bindings).

## Upstream Sync

This repo is a fork of `cloudflare/moltworker`. To sync upstream fixes:
```bash
git remote add upstream https://github.com/cloudflare/moltworker.git
git fetch upstream
git merge upstream/main
```

## Development

```bash
npm install
npm run build          # Vite build
npm run typecheck      # TypeScript check
npm run lint           # oxlint
npm run test           # vitest
npx wrangler dev       # Local dev (HTTP works, WebSocket limited)
```

## Deployment

```bash
npx wrangler secret put MOLTBOT_GATEWAY_TOKEN    # Gateway token
npx wrangler secret put ANTHROPIC_API_KEY         # Or use AI Gateway
npm run deploy                                     # Build + deploy
```

After deploying, access at: `https://moltbot-sandbox.zhenjiazhou0127.workers.dev?token={YOUR_TOKEN}`

## CF AI Gateway Provider Configuration

`start-openclaw.sh` 中的 `configureAIGateway()` 函数为不同 provider 构建不同的 baseUrl 和 API 类型：

| Provider | baseUrl 后缀 | API 类型 | 认证 header |
|---|---|---|---|
| `workers-ai` | `/v1` | `openai-completions` | `Authorization: Bearer` |
| `anthropic` | (无) | `anthropic-messages` | `x-api-key` |
| `google-ai-studio` | `/v1beta` | `google-generative-ai` | `x-goog-api-key` |
| 其他 | (无) | `openai-completions` | `Authorization: Bearer` |

CF AI Gateway 会自动将 gateway API key 替换为真正的 provider API key。

## Common Issues

- **1008 Invalid token**: Ensure MOLTBOT_GATEWAY_TOKEN is set as a secret AND the Worker injects it into WebSocket requests (see src/index.ts).
- **Container cold start**: First request takes 1-2 minutes. Set `SANDBOX_SLEEP_AFTER=never` for always-on.
- **Stale container**: After changing secrets, delete old container in Cloudflare Dashboard -> Workers -> Containers.
- **R2 persistence**: Optional but recommended. Stores config, workspace, and skills across restarts.
- **Gemini 空回复 (empty responses)**:
  - 症状：WebSocket 连接成功但 assistant 回复为空。
  - 根因：CF AI Gateway 的 Google AI Studio provider 需要 `/v1beta` 路径前缀，且必须使用 `google-generative-ai` API 类型（Google 原生格式）。使用 `openai-completions`（OpenAI 兼容格式）会因 `thinking` 等不支持的参数返回 400。
  - 排查方法：检查 AI Gateway logs 中的请求路径和 status code。用 curl 测试 `{gw}/google-ai-studio/v1beta/models/{model}:generateContent`。
  - 修复位置：`start-openclaw.sh` 的 `configureAIGateway()` 函数。
