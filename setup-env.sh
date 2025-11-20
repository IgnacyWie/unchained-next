#!/bin/bash

# --- 0. Prerequisites ---
echo "🐳 Docker Registry & Project Setup"

# Attempt to auto-detect Docker username
DETECTED_USER=$(docker info 2>/dev/null | sed -n 's/^\s*Username: //p')

if [ -n "$DETECTED_USER" ]; then
  read -p "Enter Docker Hub/Registry Username [${DETECTED_USER}]: " INPUT_USER
  DOCKER_USER=${INPUT_USER:-$DETECTED_USER}
else
  read -p "Enter your Docker Hub/Registry Username (leave blank for local only): " DOCKER_USER
fi

# Get App Name
read -p "Enter your Application Name (default: unchained-web): " APP_NAME
APP_NAME=${APP_NAME:-unchained-web}

# Get Production Domain
read -p "Enter your Production Domain (default: https://unchained.wie.dev): " INPUT_DOMAIN
NEXT_APP_DOMAIN=${INPUT_DOMAIN:-"https://unchained.wie.dev"}

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

echo "---------------------------------------------------"
echo "🚀 Setup Complete! Helm values.yaml is ready."
echo "---------------------------------------------------"
