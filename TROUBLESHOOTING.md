# Troubleshooting Deployment Guide

This guide covers common issues encountered when deploying OpenClaw on Cloudflare Workers and their solutions.

## Common Error: `{"code":2009,"message":"Unauthorized"}`

**Root Cause:** AI model configuration issue, NOT CDP authentication.

**Solution:** Remove Cloudflare AI Gateway configuration and use native provider directly.

### Why This Happens

When using Cloudflare AI Gateway configuration (`CLOUDFLARE_AI_GATEWAY_API_KEY`, `CF_AI_GATEWAY_ACCOUNT_ID`, `CF_AI_GATEWAY_GATEWAY_ID`), the model authentication may fail with error code 2009.

### Fix

1. **Remove AI Gateway secrets** (if configured):
```bash
# These are NOT recommended for this project
# CLOUDFLARE_AI_GATEWAY_API_KEY
# CF_AI_GATEWAY_ACCOUNT_ID
# CF_AI_GATEWAY_GATEWAY_ID
```

2. **Use native provider instead**:
```bash
# Direct Anthropic (recommended)
npx wrangler secret put ANTHROPIC_API_KEY

# Or direct OpenAI
npx wrangler secret put OPENAI_API_KEY
```

3. **Redeploy**:
```bash
npm run deploy
```

---

## Required Secrets Configuration

### 1. Authentication Tokens (Manual Generation Required)

All authentication tokens must be manually generated:

```bash
# Gateway Token (required for Control UI access)
export MOLTBOT_GATEWAY_TOKEN=$(openssl rand -hex 32)
echo "Save this token: $MOLTBOT_GATEWAY_TOKEN"
echo "$MOLTBOT_GATEWAY_TOKEN" | npx wrangler secret put MOLTBOT_GATEWAY_TOKEN

# CDP Secret (required for browser automation)
echo "$(openssl rand -base64 32)" | npx wrangler secret put CDP_SECRET

# Worker URL (required for CDP)
npx wrangler secret put WORKER_URL
# Enter: https://your-worker-name.your-account.workers.dev
```

**Important:** Save your `MOLTBOT_GATEWAY_TOKEN` - you'll need it to access the Control UI.

### 2. Cloudflare Access Configuration

Required for admin UI at `/_admin/`:

```bash
# Your Cloudflare Access team domain
npx wrangler secret put CF_ACCESS_TEAM_DOMAIN
# Enter: myteam.cloudflareaccess.com

# Application Audience (AUD) tag
npx wrangler secret put CF_ACCESS_AUD
# Enter: your-aud-tag-from-access-application
```

**How to configure Cloudflare Access:**

1. Enable Access on your worker: [Workers & Pages Dashboard](https://dash.cloudflare.com/?to=/:account/workers-and-pages) → Select your worker → Settings → Domains & Routes → Enable Cloudflare Access
2. Configure access policies: [Zero Trust Dashboard](https://one.dash.cloudflare.com/) → Access → Applications
3. Find your team domain: Zero Trust Dashboard → Settings → Custom Pages (subdomain before `.cloudflareaccess.com`)
4. Copy AUD tag from your Access application settings

**Reference:** [Cloudflare Access Documentation](https://developers.cloudflare.com/cloudflare-one/policies/access/)

---

## Model Configuration Issues

### Problem: Changing Default Model Doesn't Work

**Symptom:** Modifying `wrangler.jsonc` or other configuration files to change the default model has no effect.

**Root Cause:** OpenClaw agent uses its own configuration that overrides worker-level settings.

**Solution:** You must modify the agent's raw JSON configuration, not just the worker configuration files.

**Where to modify:**
- Agent configuration is stored inside the container
- Cannot be changed via `wrangler.jsonc` alone
- Must update the agent's internal configuration after deployment

**Workaround for now:**
1. Use environment variables to control model selection where possible
2. Access the container and modify agent config directly (advanced)
3. Or stick with the default model and configure via provider API key

### Recommended Model Configuration

**Best practice:** Use native provider with their default models:

```bash
# Anthropic (Claude)
npx wrangler secret put ANTHROPIC_API_KEY
# Uses Claude Sonnet by default

# OpenAI (GPT)
npx wrangler secret put OPENAI_API_KEY
# Uses GPT-4 by default
```

**Avoid:** Trying to override models via `CF_AI_GATEWAY_MODEL` or similar - this often causes authentication issues.

---

## Complete Deployment Checklist

Follow this order to avoid common issues:

### Step 1: Generate Tokens
```bash
# Generate gateway token
export MOLTBOT_GATEWAY_TOKEN=$(openssl rand -hex 32)
echo "SAVE THIS: $MOLTBOT_GATEWAY_TOKEN"

# Generate CDP secret
export CDP_SECRET=$(openssl rand -base64 32)
echo "CDP Secret: $CDP_SECRET"
```

### Step 2: Configure Secrets
```bash
# Required: AI Provider (choose one)
npx wrangler secret put ANTHROPIC_API_KEY
# OR
npx wrangler secret put OPENAI_API_KEY

# Required: Gateway token
echo "$MOLTBOT_GATEWAY_TOKEN" | npx wrangler secret put MOLTBOT_GATEWAY_TOKEN

# Required: CDP configuration
echo "$CDP_SECRET" | npx wrangler secret put CDP_SECRET
npx wrangler secret put WORKER_URL
# Enter: https://your-worker.workers.dev

# Required: Cloudflare Access
npx wrangler secret put CF_ACCESS_TEAM_DOMAIN
npx wrangler secret put CF_ACCESS_AUD
```

### Step 3: Deploy
```bash
npm run deploy
```

### Step 4: Verify
```bash
# Check deployment
npx wrangler deployments list

# Test Control UI
# Visit: https://your-worker.workers.dev/?token=YOUR_GATEWAY_TOKEN
```

---

## Other Common Issues

### Container Fails to Start

**Symptoms:**
- First request takes forever
- Gateway process not responding

**Solutions:**
1. Check secrets are configured: `npx wrangler secret list`
2. Check logs: `npx wrangler tail`
3. Verify Workers Paid plan is active
4. Try redeploying: `npm run deploy`

### Admin UI Shows "Unauthorized"

**Cause:** Cloudflare Access not configured or JWT invalid

**Solutions:**
1. Verify `CF_ACCESS_TEAM_DOMAIN` and `CF_ACCESS_AUD` are set
2. Check Access application is configured in Zero Trust Dashboard
3. Try logging out and back in to Cloudflare Access
4. For local dev: Set `DEV_MODE=true` in `.dev.vars`

### Device Pairing Not Working

**Cause:** Missing gateway token or Access configuration

**Solutions:**
1. Ensure you're using the correct gateway token in URL: `?token=YOUR_TOKEN`
2. Access admin UI at `/_admin/` to approve pending devices
3. Check that Cloudflare Access is properly configured
4. For testing: Set `DEV_MODE=true` in `.dev.vars` to bypass pairing

### R2 Storage Not Persisting

**Cause:** R2 credentials not configured

**Solutions:**
1. Create R2 API token with Read & Write permissions
2. Configure all three secrets:
   ```bash
   npx wrangler secret put R2_ACCESS_KEY_ID
   npx wrangler secret put R2_SECRET_ACCESS_KEY
   npx wrangler secret put CF_ACCOUNT_ID
   ```
3. Redeploy: `npm run deploy`

---

## Getting Help

If you're still experiencing issues:

1. Check logs: `npx wrangler tail`
2. Review [README.md](./README.md) for detailed setup instructions
3. Verify all secrets: `npx wrangler secret list`
4. Check [OpenClaw documentation](https://docs.openclaw.ai/)
5. Report issues: [GitHub Issues](https://github.com/cloudflare/moltworker/issues)

