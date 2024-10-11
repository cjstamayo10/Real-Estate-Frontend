# BASE
# See all versions at https://hub.docker.com/_/node/tags
FROM node:22-alpine AS base

# Check https://github.com/nodejs/docker-node/tree/b4117f9333da4138b03a546ec926ef50a31506c3#nodealpine to understand why libc6-compat might be needed.
# Fix missing shared library for alpine-based images (dynamic link failure)
RUN apk add --no-cache libc6-compat
RUN apk update
RUN ln -s lib lib64

# BUILDER
FROM base AS builder

# Set working directory
WORKDIR /app

# First install the dependencies (as they change less often)
COPY .gitignore .gitignore
RUN npm install -g

# Build the project
RUN npm run build --filter=web

# RUNNER
FROM base AS runner

# Set working directory
WORKDIR /app

# Don't run production as root
# Run as nextjs
RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs
USER nextjs

COPY --from=builder next.config.mjs .
COPY --from=builder package.json .

# Automatically leverage output traces to reduce image size
# https://nextjs.org/docs/advanced-features/output-file-tracing
COPY --from=builder --chown=nextjs:nodejs /app/apps/web/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/apps/web/.next/static ./apps/web/.next/static
COPY --from=builder --chown=nextjs:nodejs /app/apps/web/public ./apps/web/public

# Run the server
EXPOSE 3000/tcp
ENV PORT 3000
CMD node apps/web/server.js
