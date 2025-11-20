#!/bin/bash
set -e

# --- 0. Prerequisites ---
echo "🐳 Docker Registry & Project Setup"

# Check if gh CLI is installed
if ! command -v gh &>/dev/null; then
  echo "⚠️  GitHub CLI (gh) not found. Install it to automatically set GitHub secrets."
  echo "   Visit: https://cli.github.com/"
  echo ""
  read -p "Continue without GitHub secrets setup? (y/N): " CONTINUE
  if [[ ! "$CONTINUE" =~ ^[Yy]$ ]]; then
    exit 1
  fi
  GH_AVAILABLE=false
else
  GH_AVAILABLE=true
  # Check if authenticated
  if ! gh auth status &>/dev/null; then
    echo "⚠️  Not authenticated with GitHub CLI"
    echo "   Run: gh auth login"
    GH_AVAILABLE=false
  fi
fi

# Attempt to auto-detect Docker username
DETECTED_USER=$(docker info 2>/dev/null | sed -n 's/^\s*Username: //p')
if [ -n "$DETECTED_USER" ]; then
  read -p "Enter Docker Hub/Registry Username [${DETECTED_USER}]: " INPUT_USER
  DOCKER_USER=${INPUT_USER:-$DETECTED_USER}
else
  read -p "Enter your Docker Hub/Registry Username (leave blank for local only): " DOCKER_USER
fi

# Get Docker Hub token/password
if [ "$GH_AVAILABLE" = true ] && [ -n "$DOCKER_USER" ]; then
  echo ""
  echo "🔑 Docker Hub Authentication"
  echo "   For GitHub Actions, use a Personal Access Token instead of password"
  echo "   Create one at: https://hub.docker.com/settings/security"
  read -sp "Enter Docker Hub Password/Token: " DOCKER_PASSWORD
  echo ""
fi

# Get App Name
read -p "Enter your Application Name (default: unchained-web): " APP_NAME
APP_NAME=${APP_NAME:-unchained-web}

# Get Production Domain
read -p "Enter your Production Domain (default: https://unchained.wie.dev): " INPUT_DOMAIN
NEXT_APP_DOMAIN=${INPUT_DOMAIN:-"https://unchained.wie.dev"}

# Get AWS credentials (optional)
echo ""
echo "📧 AWS SES Configuration (Optional - press Enter to skip)"
read -p "AWS Region [us-east-1]: " AWS_REGION
AWS_REGION=${AWS_REGION:-us-east-1}
read -p "AWS SMTP User (leave blank to skip): " AWS_SMTP_USER
if [ -n "$AWS_SMTP_USER" ]; then
  read -sp "AWS SMTP Password: " AWS_SMTP_PASS
  echo ""
fi

# --- 1. Helper Functions ---
generate_hex() {
  openssl rand -hex 32 | tr -d '\n'
}

generate_password() {
  openssl rand -hex 16 | tr -d '\n'
}

process_template() {
  local template_file=$1
  local output_file=$2
  if [ ! -f "$template_file" ]; then
    echo "⚠️  Template not found: $template_file"
    return
  fi
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
    -e "s|{{DOCKER_IMAGE_NAME}}|${DOCKER_IMAGE_NAME_WITH_TAG}|g" \
    "$template_file" >"$output_file"
  echo "✅ Generated: $output_file"
}

set_github_secret() {
  local secret_name=$1
  local secret_value=$2

  if [ "$GH_AVAILABLE" = true ]; then
    echo "$secret_value" | gh secret set "$secret_name" 2>/dev/null
    if [ $? -eq 0 ]; then
      echo "  ✅ Set GitHub secret: $secret_name"
    else
      echo "  ⚠️  Failed to set: $secret_name"
    fi
  fi
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

if [ -n "$DOCKER_USER" ]; then
  DOCKER_IMAGE_NAME="${DOCKER_USER}/${APP_NAME}"
else
  DOCKER_IMAGE_NAME="${APP_NAME}"
fi
DOCKER_IMAGE_NAME_WITH_TAG="${DOCKER_IMAGE_NAME}:latest"
echo "ℹ️  Image Name set to: $DOCKER_IMAGE_NAME_WITH_TAG"

INGRESS_HOST=$(echo "$NEXT_APP_DOMAIN" | sed -E 's|https?://||')
echo "ℹ️  Domain set to: $INGRESS_HOST"

# --- 3. Generate Files ---
mkdir -p ops/helm/unchained-web
mkdir -p apps/web
mkdir -p packages/db

# Root .env
if [ -f "templates/env.root.tpl" ]; then
  process_template "templates/env.root.tpl" ".env"
else
  echo "DOCKER_IMAGE_NAME=\"${DOCKER_IMAGE_NAME_WITH_TAG}\"" >.env
  echo "✅ Generated: .env (Basic)"
fi

# Apps/Web .env
if [ -f "templates/env.web.tpl" ]; then
  process_template "templates/env.web.tpl" "apps/web/.env"
else
  echo "⏭️  Skipping apps/web/.env (Template not found)"
fi

# DB .env
echo "DATABASE_URL=\"${CONN_STRING_LOCAL}\"" >packages/db/.env
echo "✅ Generated: packages/db/.env"

# Helm values.yaml
process_template "templates/helm.values.tpl" "ops/helm/unchained-web/values.yaml"

# Also create example file (safe to commit)
if [ -f "ops/helm/unchained-web/values.yaml" ]; then
  cp "ops/helm/unchained-web/values.yaml" "ops/helm/unchained-web/values.yaml.example"
  # Replace secrets with placeholders
  sed -i.bak \
    -e 's/postgresPassword: "[^"]*"/postgresPassword: "CHANGE_ME_RANDOM_32_CHARS"/' \
    -e 's/nextAuthSecret: "[^"]*"/nextAuthSecret: "CHANGE_ME_RANDOM_64_CHARS"/' \
    "ops/helm/unchained-web/values.yaml.example"
  rm -f "ops/helm/unchained-web/values.yaml.example.bak"
  echo "✅ Generated: values.yaml.example (safe to commit)"
fi

echo "---------------------------------------------------"
echo "🚀 Setup Complete! Helm values.yaml is ready."
echo "---------------------------------------------------"

# --- 4. Set GitHub Secrets ---
if [ "$GH_AVAILABLE" = true ]; then
  echo ""
  echo "🔐 Setting GitHub Secrets..."

  # Check if we're in a git repository
  if ! git rev-parse --git-dir >/dev/null 2>&1; then
    echo "⚠️  Not in a git repository. Skipping GitHub secrets setup."
    GH_AVAILABLE=false
  else
    # Get current repository
    REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null)
    if [ -z "$REPO" ]; then
      echo "⚠️  Could not detect GitHub repository. Skipping secrets setup."
      GH_AVAILABLE=false
    else
      echo "📦 Repository: $REPO"
      echo ""

      # Docker credentials
      if [ -n "$DOCKER_USER" ] && [ -n "$DOCKER_PASSWORD" ]; then
        set_github_secret "DOCKER_USERNAME" "$DOCKER_USER"
        set_github_secret "DOCKER_PASSWORD" "$DOCKER_PASSWORD"
      fi

      # Database credentials
      set_github_secret "POSTGRES_USER" "$DB_USER"
      set_github_secret "POSTGRES_PASSWORD" "$DB_PASSWORD"
      set_github_secret "POSTGRES_DB" "$DB_NAME"

      # NextAuth
      set_github_secret "NEXTAUTH_SECRET" "$NEXTAUTH_SECRET"
      set_github_secret "NEXTAUTH_URL" "$NEXT_APP_DOMAIN"

      # Ingress
      set_github_secret "INGRESS_HOST" "$INGRESS_HOST"

      # AWS (if provided)
      if [ -n "$AWS_SMTP_USER" ]; then
        set_github_secret "AWS_REGION" "$AWS_REGION"
        set_github_secret "AWS_SMTP_USER" "$AWS_SMTP_USER"
        set_github_secret "AWS_SMTP_PASS" "$AWS_SMTP_PASS"
      fi

      # Kubernetes config
      echo ""
      echo "🔧 Kubernetes Configuration"
      if [ -f "$HOME/.kube/config" ]; then
        read -p "Set KUBE_CONFIG from ~/.kube/config? (y/N): " SET_KUBECONFIG
        if [[ "$SET_KUBECONFIG" =~ ^[Yy]$ ]]; then
          KUBE_CONFIG_B64=$(cat "$HOME/.kube/config" | base64 -w 0 2>/dev/null || cat "$HOME/.kube/config" | base64)
          set_github_secret "KUBE_CONFIG" "$KUBE_CONFIG_B64"
        fi
      else
        echo "  ⚠️  ~/.kube/config not found. You'll need to set KUBE_CONFIG manually."
      fi

      echo ""
      echo "✅ GitHub Secrets configured!"
      echo "   View at: https://github.com/$REPO/settings/secrets/actions"
    fi
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
echo "  🐳 Docker Image: $DOCKER_IMAGE_NAME_WITH_TAG"
echo "  🗄️  Database: $DB_NAME"
echo "  🌐 Domain: $INGRESS_HOST"
echo ""

if [ "$GH_AVAILABLE" = true ]; then
  echo "GitHub Secrets:"
  echo "  ✅ All secrets configured automatically"
  echo ""
  echo "Next Steps:"
  echo "  1. Review generated files"
  echo "  2. Push to GitHub to trigger deployment"
  echo "  3. Monitor: gh run watch"
else
  echo "⚠️  GitHub Secrets Not Configured"
  echo ""
  echo "To set secrets manually:"
  echo "  1. Install GitHub CLI: https://cli.github.com/"
  echo "  2. Run: gh auth login"
  echo "  3. Re-run this script"
  echo ""
  echo "Or set manually at:"
  echo "  GitHub → Settings → Secrets and variables → Actions"
  echo ""
  echo "Required Secrets:"
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
