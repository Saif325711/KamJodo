# Production Dockerfile for KamJodo Node.js Backend
FROM node:20-alpine AS base

WORKDIR /usr/src/app

# Copy package manifests first for optimal Docker layer caching
COPY package.json package-lock.json ./

# Install production dependencies only
RUN npm ci --only=production

# Copy application source code
COPY src ./src
COPY server.js ./
COPY data ./data

# Expose backend port
EXPOSE 5000

# Set production environment
ENV NODE_ENV=production
ENV PORT=5000

# Start server listening on 0.0.0.0
CMD ["node", "server.js"]
