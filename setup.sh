#!/bin/bash
set -e

echo "🚀 OpenClaw on Cloudflare Workers - Setup Script"
echo "================================================"
echo ""

# Check dependencies
echo "📋 Checking dependencies..."
command -v npx >/dev/null 2>&1 || { echo "❌ npx not found. Please install Node.js"; exit 1; }
command -v openssl >/dev/null 2>&1 || { echo "❌ openssl not found"; exit 1; }
echo "✅ Dependencies OK"
echo ""

# Generate tokens
echo "🔑 Generating authentication tokens..."
GATEWAY_TOKEN=$(openssl rand -hex 32)
CDP_SECRET=$(openssl rand -base64 32)
echo "✅ Tokens generated"
echo ""

# Save tokens to file for reference
cat > .tokens.txt <<EOF
# SAVE THESE TOKENS - You'll need them to access your deployment
# DO NOT commit this file to git (it's in .gitignore)

MOLTBOT_GATEWAY_TOKEN=$GATEWAY_TOKEN
CDP_SECRET=$CDP_SECRET

# Access your Control UI at:
# https://your-worker.workers.dev/?token=$GATEWAY_TOKEN
EOF

echo "💾 Tokens saved to .tokens.txt (DO NOT commit this file)"
echo ""

# Configure AI Provider
echo "🤖 AI Provider Configuration"
echo "Choose your AI provider:"
echo "1) Anthropic (Claude) - Recommended"
echo "2) OpenAI (GPT)"
read -p "Enter choice (1 or 2): " ai_choice

if [ "$ai_choice" = "1" ]; then
    read -p "Enter your Anthropic API key: " ANTHROPIC_KEY
    echo "$ANTHROPIC_KEY" | npx wrangler secret put ANTHROPIC_API_KEY
    echo "✅ Anthropic API key configured"
elif [ "$ai_choice" = "2" ]; then
    read -p "Enter your OpenAI API key: " OPENAI_KEY
    echo "$OPENAI_KEY" | npx wrangler secret put OPENAI_API_KEY
    echo "✅ OpenAI API key configured"
else
    echo "❌ Invalid choice"
    exit 1
fi
echo ""

# Configure Gateway Token
echo "🔐 Configuring gateway token..."
echo "$GATEWAY_TOKEN" | npx wrangler secret put MOLTBOT_GATEWAY_TOKEN
echo "✅ Gateway token configured"
echo ""

# Configure CDP
echo "🌐 Configuring CDP (Browser Automation)..."
echo "$CDP_SECRET" | npx wrangler secret put CDP_SECRET

read -p "Enter your worker URL (e.g., https://moltbot-sandbox.your-account.workers.dev): " WORKER_URL
echo "$WORKER_URL" | npx wrangler secret put WORKER_URL
echo "✅ CDP configured"
echo ""

# Configure Cloudflare Access
echo "🔒 Cloudflare Access Configuration (for Admin UI)"
echo "See: https://developers.cloudflare.com/cloudflare-one/policies/access/"
read -p "Enter CF_ACCESS_TEAM_DOMAIN (e.g., myteam.cloudflareaccess.com): " CF_TEAM
read -p "Enter CF_ACCESS_AUD (Application Audience tag): " CF_AUD

echo "$CF_TEAM" | npx wrangler secret put CF_ACCESS_TEAM_DOMAIN
echo "$CF_AUD" | npx wrangler secret put CF_ACCESS_AUD
echo "✅ Cloudflare Access configured"
echo ""

# Optional: R2 Storage
read -p "Configure R2 storage for persistence? (y/n): " r2_choice
if [ "$r2_choice" = "y" ]; then
    read -p "Enter R2_ACCESS_KEY_ID: " R2_KEY
    read -p "Enter R2_SECRET_ACCESS_KEY: " R2_SECRET
    read -p "Enter CF_ACCOUNT_ID: " CF_ACCOUNT

    echo "$R2_KEY" | npx wrangler secret put R2_ACCESS_KEY_ID
    echo "$R2_SECRET" | npx wrangler secret put R2_SECRET_ACCESS_KEY
    echo "$CF_ACCOUNT" | npx wrangler secret put CF_ACCOUNT_ID
    echo "✅ R2 storage configured"
fi
echo ""

# Deploy
echo "🚀 Deploying to Cloudflare Workers..."
npm install
npm run deploy
echo ""

# Final instructions
echo "✅ Setup Complete!"
echo "=================="
echo ""
echo "📝 Your tokens are saved in .tokens.txt"
echo ""
echo "🌐 Access your Control UI:"
echo "   $WORKER_URL/?token=$GATEWAY_TOKEN"
echo ""
echo "📚 Next steps:"
echo "   1. Visit /_admin/ to manage device pairing"
echo "   2. See TROUBLESHOOTING.md for common issues"
echo "   3. See README.md for full documentation"
echo ""
