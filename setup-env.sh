#!/bin/bash

# --- 1. Helper Functions ---
generate_secret() {
  openssl rand -base64 32 | tr -d '\n'
}

generate_password() {
  openssl rand -hex 16 | tr -d '\n'
}

echo "🔐 Generating secrets for Docker Network setup..."

# --- 2. Generate Values ---
# Database
DB_USER="postgres"
DB_NAME="myapp"
DB_PASSWORD=$(generate_password)
DB_PORT_INTERNAL="5432"
DB_PORT_EXTERNAL="5432"

# NextAuth
NEXTAUTH_SECRET=$(generate_secret)
NEXT_APP_URL="http://localhost:3000"

# Email (Mailpit Defaults)
EMAIL_USER="none"
EMAIL_PASS="none"
EMAIL_FROM="noreply@unchained.local"
# For local development (Node running on host)
EMAIL_HOST_LOCAL="localhost"
EMAIL_PORT_LOCAL="1025"
# For Docker production (Container to Container)
EMAIL_HOST_DOCKER="mailpit"
EMAIL_PORT_DOCKER="1025"

# 1. LOCAL Connection String (For Prisma Migrate / Local Dev)
# Uses 'localhost' because your terminal is outside Docker
CONN_STRING_LOCAL="postgresql://${DB_USER}:${DB_PASSWORD}@localhost:${DB_PORT_EXTERNAL}/${DB_NAME}?schema=public"

# --- 3. Write Root .env ---
# Docker Compose reads this to spin up the containers
echo "📄 Writing root .env..."
cat <<EOF >.env
# --- Database Raw Vars (Used to build connection strings) ---
POSTGRES_USER=${DB_USER}
POSTGRES_PASSWORD=${DB_PASSWORD}
POSTGRES_DB=${DB_NAME}
POSTGRES_PORT=${DB_PORT_EXTERNAL}

# --- NextAuth ---
NEXTAUTH_SECRET=${NEXTAUTH_SECRET}
NEXT_PUBLIC_APP_URL=${NEXT_APP_URL}

# --- Email (Docker Internal) ---
# Used if you run the full stack inside Docker
EMAIL_SERVER_HOST=${EMAIL_HOST_DOCKER}
EMAIL_SERVER_PORT=${EMAIL_PORT_DOCKER}
EMAIL_SERVER_USER=${EMAIL_USER}
EMAIL_SERVER_PASSWORD=${EMAIL_PASS}
EMAIL_FROM=${EMAIL_FROM}
EOF

# --- 4. Write Apps/Web .env ---
# Used by 'npm run dev' locally
if [ -d "apps/web" ]; then
  echo "📄 Writing apps/web/.env..."
  cat <<EOF >apps/web/.env
# Local connection for development
DATABASE_URL="${CONN_STRING_LOCAL}"

# Auth
NEXTAUTH_URL=${NEXT_APP_URL}
NEXTAUTH_SECRET=${NEXTAUTH_SECRET}

# Email (Localhost)
# Connects to the forwarded port 1025 from Docker
EMAIL_SERVER_HOST=${EMAIL_HOST_LOCAL}
EMAIL_SERVER_PORT=${EMAIL_PORT_LOCAL}
EMAIL_SERVER_USER=${EMAIL_USER}
EMAIL_SERVER_PASSWORD=${EMAIL_PASS}
EMAIL_FROM=${EMAIL_FROM}
EOF
fi

# --- 5. Write Packages/DB .env ---
# Used by 'npx prisma migrate' locally
if [ -d "packages/db" ]; then
  echo "📄 Writing packages/db/.env..."
  cat <<EOF >packages/db/.env
DATABASE_URL="${CONN_STRING_LOCAL}"
EOF
fi

echo "---------------------------------------------------"
echo "✅ Done!"
echo "1. Database vars set."
echo "2. NextAuth Secret generated."
echo "3. Mailpit config added (localhost for App, 'mailpit' for Docker)."
echo "---------------------------------------------------"
