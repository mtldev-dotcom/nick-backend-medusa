# ---- base ----
FROM node:20-slim AS base
ENV NODE_ENV=production
WORKDIR /app
RUN corepack enable

# ---- deps ----
FROM base AS deps
# Copy only files required to install dependencies (faster caching)
COPY package.json yarn.lock ./
COPY .yarnrc.yml ./
COPY .yarn/ ./.yarn/
# Yarn Berry uses --immutable; Yarn v1 will ignore it and use --frozen-lockfile
RUN yarn install --immutable || yarn install --frozen-lockfile

# ---- build ----
FROM deps AS build
COPY . .
# Build server (+ Admin UI) per Medusa docs
RUN yarn build

# ---- runtime ----
FROM node:20-slim AS runner
ENV NODE_ENV=production
WORKDIR /app
RUN corepack enable &&         apt-get update && apt-get install -y --no-install-recommends dumb-init curl &&         rm -rf /var/lib/apt/lists/*

# Bring built app (dist + node_modules) into runtime image
COPY --from=build /app /app

# Minimal entrypoint to run migrations before starting the server
COPY docker/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 9000
# Healthcheck only valid for server mode (MEDUSA_WORKER_MODE=server)
HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3       CMD curl -fsS http://localhost:9000/health || exit 1

ENTRYPOINT ["/usr/bin/dumb-init","--"]
CMD ["/entrypoint.sh"]
