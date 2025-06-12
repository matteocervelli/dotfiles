# ==============================================================================
# Multi-stage Dockerfile Template
# ==============================================================================
# This Dockerfile provides a production-ready template with multi-stage builds
# Customize the base images and build steps based on your technology stack
# ==============================================================================

# ==============================================================================
# Build Stage
# ==============================================================================
FROM node:18-alpine AS build

# Set working directory
WORKDIR /app

# Install dependencies first (for better caching)
COPY package*.json ./
RUN npm ci --only=production && npm cache clean --force

# Copy source code
COPY . .

# Build the application
RUN npm run build

# ==============================================================================
# Production Stage
# ==============================================================================
FROM node:18-alpine AS production

# Create app user for security
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nextjs -u 1001

# Set working directory
WORKDIR /app

# Copy built application from build stage
COPY --from=build --chown=nextjs:nodejs /app/dist ./dist
COPY --from=build --chown=nextjs:nodejs /app/node_modules ./node_modules
COPY --from=build --chown=nextjs:nodejs /app/package*.json ./

# Create necessary directories with proper permissions
RUN mkdir -p /app/logs && chown -R nextjs:nodejs /app

# Switch to non-root user
USER nextjs

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:3000/health || exit 1

# Start the application
CMD ["npm", "start"]

# ==============================================================================
# Alternative: Python Application
# ==============================================================================
# Uncomment and modify this section for Python applications

# FROM python:3.11-slim AS python-build
# 
# WORKDIR /app
# 
# # Install system dependencies
# RUN apt-get update && apt-get install -y \
#     build-essential \
#     curl \
#     && rm -rf /var/lib/apt/lists/*
# 
# # Install Python dependencies
# COPY requirements.txt .
# RUN pip install --no-cache-dir -r requirements.txt
# 
# # Copy source code
# COPY . .
# 
# FROM python:3.11-slim AS python-production
# 
# # Create app user
# RUN useradd --create-home --shell /bin/bash app
# 
# WORKDIR /app
# 
# # Copy dependencies and code from build stage
# COPY --from=python-build /usr/local/lib/python3.11/site-packages /usr/local/lib/python3.11/site-packages
# COPY --from=python-build /usr/local/bin /usr/local/bin
# COPY --from=python-build --chown=app:app /app .
# 
# USER app
# 
# EXPOSE 8000
# 
# HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
#     CMD curl -f http://localhost:8000/health || exit 1
# 
# CMD ["python", "-m", "uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]

# ==============================================================================
# Build Arguments and Environment Variables
# ==============================================================================
# These can be customized during build time

ARG NODE_ENV=production
ARG BUILD_DATE
ARG VERSION
ARG COMMIT_SHA

# Set environment variables
ENV NODE_ENV=${NODE_ENV}
ENV PORT=3000

# Labels for metadata
LABEL maintainer="your-email@example.com"
LABEL version="${VERSION}"
LABEL description="Your application description"
LABEL build-date="${BUILD_DATE}"
LABEL commit="${COMMIT_SHA}"