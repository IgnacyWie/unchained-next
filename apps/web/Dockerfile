# Use Node 20-alpine for best size/performance
FROM node:20-alpine AS base

# ---------------------------------------------------------
# 1. PRUNE: Scope the workspace to just this app
# ---------------------------------------------------------
FROM base AS builder
# Disable Turbo telemetry
ENV TURBO_TELEMETRY_DISABLED=1

RUN apk add --no-cache libc6-compat
WORKDIR /app
RUN npm install turbo --global

COPY . .

# ✂️ PRUNE: Slices the monorepo to only what 'web' needs
RUN turbo prune --scope=web --docker

# ---------------------------------------------------------
# 2. INSTALL: The Speed Layer (Fetch + Cache Mounts)
# ---------------------------------------------------------
FROM base AS installer

# Disable Turbo telemetry
ENV TURBO_TELEMETRY_DISABLED=1

RUN apk add --no-cache libc6-compat
WORKDIR /app

# Install pnpm globally
RUN npm install -g pnpm
RUN corepack enable

# 📂 COPY METADATA FIRST
COPY --from=builder /app/out/json/ .
COPY --from=builder /app/out/pnpm-lock.yaml ./pnpm-lock.yaml

# 🚀 SPEED HACK 1: pnpm fetch + Cache Mount
RUN --mount=type=cache,id=pnpm,target=/pnpm/store \
  pnpm config set store-dir /pnpm/store && \
  pnpm fetch

# 🚀 SPEED HACK 2: Install from Offline Store
RUN --mount=type=cache,id=pnpm,target=/pnpm/store \
  pnpm install -r --offline --frozen-lockfile

# 📂 COPY SOURCE CODE
COPY --from=builder /app/out/full/ .

# 🛠️ PRISMA GENERATE
WORKDIR /app/packages/db
RUN pnpm exec prisma generate
WORKDIR /app

# 🏗️ BUILD
RUN pnpm turbo run build --filter=web...

# ---------------------------------------------------------
# 3. RUNNER: Production Image
# ---------------------------------------------------------
FROM base AS runner
WORKDIR /app

# Disable Next.js & Turbo telemetry at runtime
ENV NEXT_TELEMETRY_DISABLED=1
ENV TURBO_TELEMETRY_DISABLED=1
ENV DO_NOT_TRACK=1

ENV NODE_ENV=production
ENV PORT=3000
ENV HOSTNAME="0.0.0.0"

# 👇 CRITICAL FIX: Install OpenSSL for Prisma
# This fixes "Error loading shared library libssl.so.1.1"
RUN apk add --no-cache libc6-compat openssl

RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs

# Copy the Standalone build from the installer stage
COPY --from=installer --chown=nextjs:nextjs /app/apps/web/.next/standalone ./
COPY --from=installer --chown=nextjs:nextjs /app/apps/web/.next/static ./apps/web/.next/static
COPY --from=installer --chown=nextjs:nextjs /app/apps/web/public ./apps/web/public

USER nextjs

EXPOSE 3000

CMD ["node", "apps/web/server.js"]
