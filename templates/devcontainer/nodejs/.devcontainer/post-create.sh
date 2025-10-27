#!/bin/bash
# Node.js Dev Container Post-Create Script
# Runs after container is created

set -e

echo "📦 Node.js Dev Container - Post-Create Setup"
echo ""

# Check Node.js version
echo "Node.js version: $(node --version)"
echo "npm version: $(npm --version)"
echo ""

# Check if package.json exists
if [ -f "package.json" ]; then
    echo "📦 Found package.json - installing dependencies..."

    # Detect which package manager to use
    if [ -f "pnpm-lock.yaml" ]; then
        echo "Using pnpm..."
        pnpm install
    elif [ -f "yarn.lock" ]; then
        echo "Using yarn..."
        yarn install
    elif [ -f "package-lock.json" ]; then
        echo "Using npm..."
        npm install
    else
        echo "Using npm (no lockfile found)..."
        npm install
    fi

    echo "✅ Dependencies installed"
else
    echo "ℹ️  No package.json found"
    echo "   Create one with: npm init -y"
fi

echo ""
echo "✅ Post-create setup complete!"
echo ""
echo "💡 Tips:"
echo "  - Install packages: npm install <package>"
echo "  - Run scripts: npm run <script>"
echo "  - Start dev server: npm run dev"
echo ""
