# Use Node 20-alpine (LTS) for best stability with Prisma
FROM node:20-alpine AS base

# ---------------------------------------------------------
# 1. Prune: Scope the workspace to just this app
# ---------------------------------------------------------
FROM base AS builder
RUN apk add --no-cache libc6-compat
WORKDIR /app
RUN npm install turbo --global

# Copy the entire monorepo context
COPY . .

# Prune dependencies (Generates 'out' folder with only needed packages)
# Ensure the scope matches your package.json name (e.g. @repo/web or web)
RUN turbo prune --scope=web --docker

# ---------------------------------------------------------
# 2. Install & Build
# ---------------------------------------------------------
FROM base AS installer
RUN apk add --no-cache libc6-compat openssl
WORKDIR /app
RUN corepack enable

# Copy lockfile and package.json's from pruned output
COPY .gitignore .gitignore
COPY --from=builder /app/out/json/ .
COPY --from=builder /app/out/pnpm-lock.yaml ./pnpm-lock.yaml

# Install deps
RUN pnpm install

# Copy source code from pruned output
COPY --from=builder /app/out/full/ .

# Generate Prisma Client
# We do this explicitly to ensure the binary is compatible with Alpine
WORKDIR /app/packages/db
RUN pnpm exec prisma generate
WORKDIR /app

# Build the project
RUN pnpm turbo run build --filter=web...

# ---------------------------------------------------------
# 3. Production Runner
# ---------------------------------------------------------
FROM base AS runner
RUN apk add --no-cache libc6-compat openssl
WORKDIR /app

ENV NODE_ENV=production
ENV PORT=3000
ENV HOSTNAME="0.0.0.0"

RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs

# Copy public assets and standalone server
# Note: Standalone output typically preserves the 'apps/web' directory structure
COPY --from=installer --chown=nextjs:nextjs /app/apps/web/.next/standalone ./
COPY --from=installer --chown=nextjs:nextjs /app/apps/web/.next/static ./apps/web/.next/static
COPY --from=installer --chown=nextjs:nextjs /app/apps/web/public ./apps/web/public

USER nextjs

EXPOSE 3000

CMD ["node", "apps/web/server.js"]
