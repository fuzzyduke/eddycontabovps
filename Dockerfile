FROM node:22-bookworm AS builder

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    bash \
    && rm -rf /var/lib/apt/lists/*

# Install Bun (required for build scripts)
RUN curl -fsSL https://bun.sh/install | bash
ENV PATH="/root/.bun/bin:${PATH}"

RUN corepack enable

WORKDIR /gateway-source

# Clone the official OpenClaw repository
RUN git clone https://github.com/openclaw/openclaw.git .

# Install dependencies and build
# We use --frozen-lockfile to ensure stability
RUN pnpm install --frozen-lockfile
RUN pnpm build
RUN pnpm ui:build

# Runner stage
FROM node:22-bookworm

RUN corepack enable
WORKDIR /app

# Copy built artifacts from builder
COPY --from=builder /gateway-source /app

# Set environment
ENV NODE_ENV=production
ENV OPENCLAW_PORT=18789

# Create workspace dir for persistence
RUN mkdir -p /home/node/.openclaw/workspace && chown -R node:node /home/node/.openclaw

# App setup
RUN chown -R node:node /app
USER node

# Expose the gateway port
EXPOSE 18789

# Start the gateway
# --allow-unconfigured is useful for initial setup
# --bind lan allows it to be reachable via the network proxy
CMD ["node", "openclaw.mjs", "gateway", "--allow-unconfigured", "--bind", "lan"]
