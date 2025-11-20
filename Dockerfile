# Use Node 20-alpine (LTS) for best stability with Prisma
FROM node:20-alpine AS base

# 1. Prune the workspace
FROM base AS builder
# Install libc6-compat needed for Turbo on Alpine
RUN apk add --no-cache libc6-compat
WORKDIR /app
RUN npm install turbo --global
COPY . .
RUN turbo prune --scope=web --docker

# 2. Install dependencies & Build
FROM base AS installer
# FIX 1: Install OpenSSL and libc6 (REQUIRED for Prisma on Alpine)
RUN apk add --no-cache libc6-compat openssl
WORKDIR /app

# Enable corepack for pnpm
RUN corepack enable

COPY .gitignore .gitignore
COPY --from=builder /app/out/json/ .
COPY --from=builder /app/out/pnpm-lock.yaml ./pnpm-lock.yaml

# Install dependencies
RUN pnpm install

# Copy source code
COPY --from=builder /app/out/full/ .

# FIX 2: Generate Prisma Client inside the db package context.
# We change directory to 'packages/db' so pnpm finds the local 'prisma' binary.
# We rely on the default schema location (./prisma/schema.prisma) inside that folder.
WORKDIR /app/packages/db
RUN pnpm exec prisma generate
WORKDIR /app

# Build the project
RUN pnpm turbo run build --filter=web...

# 3. Production Image
FROM base AS runner
# FIX 3: Install OpenSSL in production image too (Database connection needs it)
RUN apk add --no-cache libc6-compat openssl
WORKDIR /app

ENV NODE_ENV production

RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs
USER nextjs

COPY --from=installer /app/apps/web/next.config.ts .
COPY --from=installer /app/apps/web/package.json .

# Automatically leverage output traces to reduce image size
COPY --from=installer --chown=nextjs:nextjs /app/apps/web/.next/standalone ./
COPY --from=installer --chown=nextjs:nextjs /app/apps/web/.next/static ./apps/web/.next/static
COPY --from=installer --chown=nextjs:nextjs /app/apps/web/public ./apps/web/public

EXPOSE 3000

ENV PORT 3000
ENV HOSTNAME "0.0.0.0"

CMD ["node", "apps/web/server.js"]
