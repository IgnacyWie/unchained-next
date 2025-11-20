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
DB_USER="postgres"
DB_NAME="myapp"
DB_PASSWORD=$(generate_password)
# The internal port inside the docker network
DB_PORT_INTERNAL="5432"
# The external port mapped to your host (can be changed if 5432 is taken)
DB_PORT_EXTERNAL="5432"

NEXTAUTH_SECRET=$(generate_secret)
NEXT_APP_URL="http://localhost:3000"

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
EOF

# --- 4. Write Apps/Web .env ---
# Used by 'npm run dev' locally
if [ -d "apps/web" ]; then
  echo "📄 Writing apps/web/.env..."
  cat <<EOF >apps/web/.env
# Local connection for development
DATABASE_URL="${CONN_STRING_LOCAL}"

NEXTAUTH_URL=${NEXT_APP_URL}
NEXTAUTH_SECRET=${NEXTAUTH_SECRET}
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
echo "1. The .env files are set to 'localhost' so you can run migrations locally."
echo "2. The docker-compose.yml is configured to override this with 'postgres' internally."
echo "---------------------------------------------------"
