#!/bin/bash
# Python Dev Container Post-Create Script
# Runs after container is created

set -e

echo "🐍 Python Dev Container - Post-Create Setup"
echo ""

# Check if requirements.txt exists
if [ -f "requirements.txt" ]; then
    echo "📦 Found requirements.txt - creating virtual environment..."
    python3 -m venv .venv
    source .venv/bin/activate
    pip install --upgrade pip
    pip install -r requirements.txt
    echo "✅ Requirements installed"
elif [ -f "pyproject.toml" ]; then
    echo "📦 Found pyproject.toml..."
    if grep -q "tool.poetry" pyproject.toml; then
        echo "🎵 Poetry project detected - installing dependencies..."
        poetry install
        echo "✅ Poetry dependencies installed"
    elif grep -q "build-system" pyproject.toml; then
        echo "🔨 Standard pyproject.toml detected - installing with pip..."
        python3 -m venv .venv
        source .venv/bin/activate
        pip install --upgrade pip
        pip install -e .
        echo "✅ Package installed in development mode"
    fi
elif [ -f "Pipfile" ]; then
    echo "🐍 Pipenv project detected - installing dependencies..."
    pipenv install --dev
    echo "✅ Pipenv dependencies installed"
else
    echo "ℹ️  No dependency file found (requirements.txt, pyproject.toml, Pipfile)"
    echo "   Creating basic virtual environment..."
    python3 -m venv .venv
    source .venv/bin/activate
    pip install --upgrade pip
fi

echo ""
echo "✅ Post-create setup complete!"
echo ""
echo "💡 Tips:"
echo "  - Activate venv: source .venv/bin/activate"
echo "  - Install packages: pip install <package>"
echo "  - Run tests: pytest"
echo ""
