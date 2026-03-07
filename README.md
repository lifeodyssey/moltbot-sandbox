# OpenClaw on Cloudflare Workers - Personal Deployment Guide

> **Personal Fork:** This is my deployment configuration and troubleshooting experience based on [cloudflare/moltworker](https://github.com/cloudflare/moltworker). For detailed upstream documentation, see the [original README](https://github.com/cloudflare/moltworker).

Deploy [OpenClaw](https://github.com/openclaw/openclaw) personal AI assistant on Cloudflare Workers with one command.

## Quick Start

**One-command deployment:**

```bash
# 1. Copy and configure your API keys
cp .env.example .env
# Edit .env with your API keys

# 2. Run setup script
./setup.sh
```

That's it! The script will:
- ✅ Generate secure tokens
- ✅ Configure your AI provider
- ✅ Set up browser automation (CDP)
- ✅ Configure admin UI access
- ✅ Deploy to Cloudflare

Access your deployment at: `https://your-worker.workers.dev/?token=YOUR_TOKEN`

---

## Prerequisites

### 1. Cloudflare Workers Paid Plan ($5/month)

**Required** for Cloudflare Sandbox containers and Browser Rendering.

**Enable here:** https://dash.cloudflare.com/?to=/:account/workers/plans

### 2. Cloudflare API Token

**For wrangler CLI deployment.** Create a token with these permissions:

1. Go to https://dash.cloudflare.com/profile/api-tokens
2. Click "Create Token" → "Create Custom Token"
3. **Required permissions:**
   - Account → Account Settings → Read
   - Account → Workers Scripts → Edit
   - Account → Workers KV Storage → Edit
   - Account → Workers Routes → Edit
   - Account → Workers R2 Storage → Edit

4. **Optional permissions** (based on features you use):
   - Account → Access: Apps and Policies → Read (if using Cloudflare Access for admin UI)
   - Account → AI Gateway → Edit (if using AI Gateway)
   - Zone → Zone → Read (if using custom domain)

5. Set Account Resources to your account
6. Copy the token and add to `.env`:
   ```
   CLOUDFLARE_API_TOKEN=your-token-here
   ```

**Why these permissions:**
- **Workers Scripts** - Deploy worker, containers, and browser rendering
- **Workers KV Storage** - Required for Durable Objects (Sandbox class)
- **Workers Routes** - Configure routing
- **R2 Storage** - Persistent data storage (strongly recommended)

### 3. AI Provider API Key

Choose **one** provider and get an API key:

| Provider | API Key Location | Notes |
|----------|------------------|-------|
| **Anthropic (Claude)** | https://console.anthropic.com/ | Recommended, best quality |
| **OpenAI (GPT)** | https://platform.openai.com/api-keys | Requires billing setup |
| **Moonshot (Kimi)** | https://platform.moonshot.cn/ | Kimi Code API |
| **Google (Gemini)** | https://aistudio.google.com/app/apikey | Free tier available |

Add to `.env`:
```bash
# Choose one:
ANTHROPIC_API_KEY=sk-ant-...
# OPENAI_API_KEY=sk-...
# MOONSHOT_API_KEY=sk-...
# GOOGLE_API_KEY=AIza...
```

---

## What Gets Deployed

After running `./setup.sh`, you'll have:

- **OpenClaw container** running on Cloudflare Workers
- **Browser automation** (CDP) for web interactions
- **Secure access** via generated tokens
- **Your chosen AI provider** configured

## Troubleshooting

Having issues? Check [TROUBLESHOOTING.md](./TROUBLESHOOTING.md) for:

- Common deployment errors
- AI provider configuration issues
- CDP authentication problems
- Model selection and limitations

## Advanced Configuration

For advanced features like R2 storage, custom models, or Cloudflare Access, see:

- [Original upstream README](https://github.com/cloudflare/moltworker) - Full documentation
- [TROUBLESHOOTING.md](./TROUBLESHOOTING.md) - Detailed configuration guide

## Project Structure

```
├── setup.sh              # One-command deployment script
├── .env.example          # API key template
├── .tokens.txt           # Generated tokens (DO NOT commit)
├── TROUBLESHOOTING.md    # Detailed troubleshooting guide
└── src/
    ├── gateway/          # Worker entry point
    └── routes/           # API routes (CDP, admin)
```

## License

Same as upstream [cloudflare/moltworker](https://github.com/cloudflare/moltworker).
