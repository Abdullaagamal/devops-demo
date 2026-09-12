# ---------- Stage 1: dependencies ----------
FROM node:22-alpine AS deps
WORKDIR /app
# Copy manifests only so we keep the Docker layer cache when they don't change
COPY package.json package-lock.json ./
# npm ci installs byte-for-byte from the lockfile (reproducible builds)
RUN npm ci --omit=dev

# ---------- Stage 2: production runtime ----------
FROM node:22-alpine AS runner
WORKDIR /app

ENV NODE_ENV=production \
    PORT=3000 \
    HOST=0.0.0.0

# Run as a non-root user (least privilege)
RUN addgroup --system --gid 1001 nodejs \
    && adduser --system --uid 1001 nodeuser

COPY --from=deps --chown=nodeuser:nodejs /app/node_modules ./node_modules
COPY --chown=nodeuser:nodejs app.js package.json ./

USER nodeuser

EXPOSE 3000

# Owner of the container image itself (Docker side; K8s probes are the real guard)
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget -qO- http://127.0.0.1:3000/health || exit 1

CMD ["node", "app.js"]