#!/bin/bash

# --- 0. Prerequisites ---
echo "🐳 Docker Registry Setup"
read -p "Enter your Docker Hub/Registry Username (leave blank to skip K8s manifest generation): " DOCKER_USER

# --- 1. Helper Functions ---
generate_hex() {
  # We use hex for secrets to avoid special chars like '/' or '+'
  # breaking the 'sed' replacement commands.
  openssl rand -hex 32 | tr -d '\n'
}

generate_password() {
  openssl rand -hex 16 | tr -d '\n'
}

to_base64() {
  echo -n "$1" | base64
}

process_template() {
  local template_file=$1
  local output_file=$2

  if [ ! -f "$template_file" ]; then
    echo "⚠️  Template not found: $template_file"
    return
  fi

  # We use | as delimiter for sed to avoid conflicts with URL slashes
  sed \
    -e "s|{{DB_USER}}|${DB_USER}|g" \
    -e "s|{{DB_PASSWORD}}|${DB_PASSWORD}|g" \
    -e "s|{{DB_NAME}}|${DB_NAME}|g" \
    -e "s|{{DB_PORT_EXTERNAL}}|${DB_PORT_EXTERNAL}|g" \
    -e "s|{{NEXTAUTH_SECRET}}|${NEXTAUTH_SECRET}|g" \
    -e "s|{{NEXT_APP_URL}}|${NEXT_APP_URL}|g" \
    -e "s|{{EMAIL_HOST_DOCKER}}|${EMAIL_HOST_DOCKER}|g" \
    -e "s|{{EMAIL_HOST_LOCAL}}|${EMAIL_HOST_LOCAL}|g" \
    -e "s|{{EMAIL_FROM}}|${EMAIL_FROM}|g" \
    -e "s|{{CONN_STRING_LOCAL}}|${CONN_STRING_LOCAL}|g" \
    -e "s|{{DOCKER_IMAGE_NAME}}|${DOCKER_IMAGE_NAME}|g" \
    \
    -e "s|{{B64_DB_USER}}|${B64_DB_USER}|g" \
    -e "s|{{B64_DB_PASSWORD}}|${B64_DB_PASSWORD}|g" \
    -e "s|{{B64_DB_NAME}}|${B64_DB_NAME}|g" \
    -e "s|{{B64_CONN_STRING_K8S}}|${B64_CONN_STRING_K8S}|g" \
    -e "s|{{B64_NEXTAUTH_SECRET}}|${B64_NEXTAUTH_SECRET}|g" \
    -e "s|{{B64_NEXT_APP_DOMAIN}}|${B64_NEXT_APP_DOMAIN}|g" \
    -e "s|{{B64_AWS_REGION}}|${B64_AWS_REGION}|g" \
    -e "s|{{B64_AWS_USER}}|${B64_AWS_USER}|g" \
    -e "s|{{B64_AWS_PASS}}|${B64_AWS_PASS}|g" \
    "$template_file" >"$output_file"

  echo "✅ Generated: $output_file"
}

echo ""
echo "🔐 Generating configuration..."

# --- 2. Define Variables ---

# Basic Vars
DB_USER="postgres"
DB_NAME="myapp"
DB_PASSWORD=$(generate_password)
DB_PORT_EXTERNAL="5432"
NEXTAUTH_SECRET=$(generate_hex) # Hex to be sed-safe
EMAIL_FROM="Unchained App <no-reply@unchained.local>"

# URLs & Hosts
NEXT_APP_URL="http://localhost:3000"
NEXT_APP_DOMAIN="http://api.example.com" # K8s domain
EMAIL_HOST_LOCAL="localhost"
EMAIL_HOST_DOCKER="mailpit"

# Connection Strings
CONN_STRING_LOCAL="postgresql://${DB_USER}:${DB_PASSWORD}@localhost:${DB_PORT_EXTERNAL}/${DB_NAME}?schema=public"
CONN_STRING_K8S="postgresql://${DB_USER}:${DB_PASSWORD}@postgres-service:5432/${DB_NAME}?schema=public"

# Docker Image
if [ -n "$DOCKER_USER" ]; then
  DOCKER_IMAGE_NAME="${DOCKER_USER}/web-app:latest"
else
  DOCKER_IMAGE_NAME="PLACEHOLDER_IMAGE"
fi

# --- 3. Generate Base64 Versions (For Kubernetes) ---
B64_DB_USER=$(to_base64 "$DB_USER")
B64_DB_PASSWORD=$(to_base64 "$DB_PASSWORD")
B64_DB_NAME=$(to_base64 "$DB_NAME")
B64_CONN_STRING_K8S=$(to_base64 "$CONN_STRING_K8S")
B64_NEXTAUTH_SECRET=$(to_base64 "$NEXTAUTH_SECRET")
B64_NEXT_APP_DOMAIN=$(to_base64 "$NEXT_APP_DOMAIN")
# Placeholders
B64_AWS_REGION=$(to_base64 "us-east-1")
B64_AWS_USER=$(to_base64 "change-me")
B64_AWS_PASS=$(to_base64 "change-me")

# --- 4. Run Processors ---

# A. Root .env
process_template "templates/env.root.tpl" ".env"

# B. Apps/Web .env
if [ -d "apps/web" ]; then
  process_template "templates/env.web.tpl" "apps/web/.env"
fi

# C. Packages/DB .env
if [ -d "packages/db" ]; then
  # Re-using env.web.tpl structure or creating a simple one on fly?
  # Let's just write a simple one here as it's only 1 line usually.
  echo "DATABASE_URL=\"${CONN_STRING_LOCAL}\"" >packages/db/.env
  echo "✅ Generated: packages/db/.env"
fi

# D. Kubernetes
mkdir -p ops/k8s
process_template "templates/k8s.secrets.tpl" "ops/k8s/secrets.yaml"

if [ -n "$DOCKER_USER" ]; then
  process_template "templates/k8s.web.tpl" "ops/k8s/web.yaml"
else
  echo "⏭️  Skipping ops/k8s/web.yaml (No Docker User provided)"
fi

echo "---------------------------------------------------"
echo "🚀 Setup Complete!"
echo "---------------------------------------------------"
