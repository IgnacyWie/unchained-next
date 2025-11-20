#!/bin/bash
set -e

# --- 0. Prerequisites ---
echo "🐳 Docker Registry & Project Setup"

# Check if gh CLI is installed
if ! command -v gh &>/dev/null; then
  echo "⚠️  GitHub CLI (gh) not found. Install it to automatically set GitHub secrets."
  read -p "Continue without GitHub secrets setup? (y/N): " CONTINUE
  if [[ ! "$CONTINUE" =~ ^[Yy]$ ]]; then exit 1; fi
  GH_AVAILABLE=false
else
  GH_AVAILABLE=true
  if ! gh auth status &>/dev/null; then
    echo "⚠️  Not authenticated with GitHub CLI. Run: gh auth login"
    GH_AVAILABLE=false
  fi
fi

# Detect Docker username
DETECTED_USER=$(docker info 2>/dev/null | sed -n 's/^\s*Username: //p')
if [ -n "$DETECTED_USER" ]; then
  read -p "Enter Docker Hub/Registry Username [${DETECTED_USER}]: " INPUT_USER
  DOCKER_USER=${INPUT_USER:-$DETECTED_USER}
else
  read -p "Enter your Docker Hub/Registry Username (leave blank for local only): " DOCKER_USER
fi

# Get Docker Hub token/password (optional)
DOCKER_PASSWORD=""
if [ -n "$DOCKER_USER" ]; then
  read -sp "Enter Docker Hub Password/Token (leave blank to skip): " DOCKER_PASSWORD
  echo ""
fi

# Get App Name
read -p "Enter your Application Name (default: unchained-web): " APP_NAME
APP_NAME=${APP_NAME:-unchained-web}

# Get Production Domain
read -p "Enter your Production Domain (default: https://unchained.wie.dev): " INPUT_DOMAIN
NEXT_APP_DOMAIN=${INPUT_DOMAIN:-"https://unchained.wie.dev"}

# Get AWS credentials (optional)
read -p "AWS Region [us-east-1]: " AWS_REGION
AWS_REGION=${AWS_REGION:-us-east-1}
read -p "AWS SMTP User (leave blank to skip): " AWS_SMTP_USER
if [ -n "$AWS_SMTP_USER" ]; then
  read -sp "AWS SMTP Password: " AWS_SMTP_PASS
  echo ""
fi

# --- 1. Helpers ---
generate_hex() { openssl rand -hex 32 | tr -d '\n'; }
generate_password() { openssl rand -hex 16 | tr -d '\n'; }

process_template() {
  local template_file=$1
  local output_file=$2
  [[ ! -f "$template_file" ]] && echo "⚠️ Template not found: $template_file" && return
  sed \
    -e "s|{{DB_USER}}|${DB_USER}|g" \
    -e "s|{{DB_PASSWORD}}|${DB_PASSWORD}|g" \
    -e "s|{{DB_NAME}}|${DB_NAME}|g" \
    -e "s|{{DB_PORT_EXTERNAL}}|${DB_PORT_EXTERNAL}|g" \
    -e "s|{{NEXTAUTH_SECRET}}|${NEXTAUTH_SECRET}|g" \
    -e "s|{{NEXT_APP_URL}}|${NEXT_APP_URL}|g" \
    -e "s|{{NEXT_APP_DOMAIN}}|${NEXT_APP_DOMAIN}|g" \
    -e "s|{{INGRESS_HOST}}|${INGRESS_HOST}|g" \
    -e "s|{{EMAIL_HOST_DOCKER}}|${EMAIL_HOST_DOCKER}|g" \
    -e "s|{{EMAIL_HOST_LOCAL}}|${EMAIL_HOST_LOCAL}|g" \
    -e "s|{{EMAIL_FROM}}|${EMAIL_FROM}|g" \
    -e "s|{{CONN_STRING_LOCAL}}|${CONN_STRING_LOCAL}|g" \
    -e "s|{{CONN_STRING_K8S}}|${CONN_STRING_K8S}|g" \
    -e "s|{{DOCKER_IMAGE_NAME}}|${DOCKER_IMAGE_NAME}|g" \
    "$template_file" >"$output_file"
  echo "✅ Generated: $output_file"
}

set_github_secret() {
  local secret_name=$1
  local secret_value=$2
  [[ "$GH_AVAILABLE" != true ]] && return
  [[ -z "$secret_value" ]] && return
  echo "$secret_value" | gh secret set "$secret_name" 2>/dev/null &&
    echo "✅ Set GitHub secret: $secret_name" ||
    echo "⚠️ Failed to set: $secret_name"
}

# --- 2. Define Variables ---
DB_USER="postgres"
DB_NAME="${APP_NAME//-/_}_db"
DB_PASSWORD=$(generate_password)
DB_PORT_EXTERNAL="5432"
NEXTAUTH_SECRET=$(generate_hex)
EMAIL_FROM="no-reply@unchained.local"
NEXT_APP_URL="http://localhost:3000"
EMAIL_HOST_LOCAL="localhost"
EMAIL_HOST_DOCKER="mailpit"
CONN_STRING_LOCAL="postgresql://${DB_USER}:${DB_PASSWORD}@localhost:${DB_PORT_EXTERNAL}/${DB_NAME}?schema=public"
CONN_STRING_K8S="postgresql://${DB_USER}:${DB_PASSWORD}@postgres-service:5432/${DB_NAME}?schema=public"

DOCKER_IMAGE_NAME=${DOCKER_USER:+$DOCKER_USER/}${APP_NAME}
echo "ℹ️ Image Name set to: $DOCKER_IMAGE_NAME"

INGRESS_HOST=$(echo "$NEXT_APP_DOMAIN" | sed -E 's|https?://||')
echo "ℹ️ Domain set to: $INGRESS_HOST"

# --- 3. Generate Files ---
mkdir -p ops/helm/unchained-web apps/web packages/db

[[ -f templates/env.root.tpl ]] && process_template templates/env.root.tpl .env ||
  echo "DOCKER_IMAGE_NAME=\"$DOCKER_IMAGE_NAME\"" >.env

[[ -f templates/env.web.tpl ]] && process_template templates/env.web.tpl apps/web/.env
echo "DATABASE_URL=\"$CONN_STRING_LOCAL\"" >packages/db/.env

process_template templates/helm.values.tpl ops/helm/unchained-web/values.yaml
cp ops/helm/unchained-web/values.yaml ops/helm/unchained-web/values.yaml.example
sed -i.bak \
  -e 's/postgresPassword: "[^"]*"/postgresPassword: "CHANGE_ME_RANDOM_32_CHARS"/' \
  -e 's/nextAuthSecret: "[^"]*"/nextAuthSecret: "CHANGE_ME_RANDOM_64_CHARS"/' \
  ops/helm/unchained-web/values.yaml.example
rm -f ops/helm/unchained-web/values.yaml.example.bak

# --- 4. Set GitHub Secrets ---
if [[ "$GH_AVAILABLE" == true ]]; then
  REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null)
  [[ -z "$REPO" ]] && echo "⚠️ Could not detect GitHub repo. Skipping secrets." && exit 0

  # Docker secrets only if password provided
  [[ -n "$DOCKER_USER" && -n "$DOCKER_PASSWORD" ]] && {
    set_github_secret DOCKER_USERNAME "$DOCKER_USER"
    set_github_secret DOCKER_PASSWORD "$DOCKER_PASSWORD"
  }

  # Always set Postgres, NextAuth, Kube, AWS
  set_github_secret POSTGRES_USER "$DB_USER"
  set_github_secret POSTGRES_PASSWORD "$DB_PASSWORD"
  set_github_secret POSTGRES_DB "$DB_NAME"
  set_github_secret NEXTAUTH_SECRET "$NEXTAUTH_SECRET"
  set_github_secret NEXTAUTH_URL "$NEXT_APP_DOMAIN"
  set_github_secret INGRESS_HOST "$INGRESS_HOST"

  if [[ -n "$AWS_SMTP_USER" ]]; then
    set_github_secret AWS_REGION "$AWS_REGION"
    set_github_secret AWS_SMTP_USER "$AWS_SMTP_USER"
    set_github_secret AWS_SMTP_PASS "$AWS_SMTP_PASS"
  fi

  if [[ -f "$HOME/.kube/config" ]]; then
    read -p "Set KUBE_CONFIG from ~/.kube/config? (y/N): " SET_KUBECONFIG
    [[ "$SET_KUBECONFIG" =~ ^[Yy]$ ]] && {
      KUBE_CONFIG_B64=$(base64 -w 0 <"$HOME/.kube/config")
      set_github_secret KUBE_CONFIG "$KUBE_CONFIG_B64"
    }
  fi
fi

# --- 5. Summary ---
echo ""
echo "=================================================="
echo "📋 Setup Summary"
echo "=================================================="
echo ""
echo "Generated Files:"
echo "  ✅ .env"
echo "  ✅ apps/web/.env"
echo "  ✅ packages/db/.env"
echo "  ✅ ops/helm/unchained-web/values.yaml"
echo "  ✅ ops/helm/unchained-web/values.yaml.example"
echo ""
echo "Configuration:"
echo "  🐳 Docker Image: $DOCKER_IMAGE_NAME"
echo "  🗄️  Database: $DB_NAME"
echo "  🌐 Domain: $INGRESS_HOST"
echo ""

if [[ "$GH_AVAILABLE" == true ]]; then
  echo "GitHub Secrets:"
  if [[ -n "$DOCKER_PASSWORD" ]]; then
    echo "  ✅ Docker credentials configured"
  else
    echo "  ⚠️  Docker credentials not configured (password/token not provided)"
  fi
  echo "  ✅ Postgres, NextAuth, Ingress configured"
  [[ -n "$AWS_SMTP_USER" ]] && echo "  ✅ AWS SES credentials configured"
  [[ -f "$HOME/.kube/config" ]] && echo "  ✅ KUBE_CONFIG configured (if approved)"

  echo ""
  echo "Next Steps:"
  echo "  1. Review generated files"
  echo "  2. Push to GitHub to trigger deployment"
  echo "  3. Monitor deployment: gh run watch"
else
  echo "⚠️  GitHub CLI not available or not authenticated"
  echo ""
  echo "To configure GitHub Secrets manually:"
  echo "  1. Install GitHub CLI: https://cli.github.com/"
  echo "  2. Run: gh auth login"
  echo "  3. Re-run this script or set secrets manually at:"
  echo "     GitHub → Settings → Secrets and variables → Actions"
  echo ""
  echo "Required Secrets (if not already set):"
  echo "  - DOCKER_USERNAME=$DOCKER_USER"
  echo "  - DOCKER_PASSWORD=<your-token>"
  echo "  - POSTGRES_USER=$DB_USER"
  echo "  - POSTGRES_PASSWORD=$DB_PASSWORD"
  echo "  - POSTGRES_DB=$DB_NAME"
  echo "  - NEXTAUTH_SECRET=$NEXTAUTH_SECRET"
  echo "  - NEXTAUTH_URL=$NEXT_APP_DOMAIN"
  echo "  - INGRESS_HOST=$INGRESS_HOST"
  echo "  - KUBE_CONFIG=<base64-encoded-kubeconfig>"
fi

echo ""
echo "=================================================="
echo "🎉 Setup Complete!"
echo "=================================================="
