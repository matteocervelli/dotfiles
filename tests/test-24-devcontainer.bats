#!/usr/bin/env bats
# Tests for Dev Container System
# Test project-specific dev container templates and generator
#
# Usage:
#   bats tests/test-24-devcontainer.bats

# Test configuration
SCRIPT_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TEMPLATES_DIR="$PROJECT_ROOT/templates/devcontainer"
GENERATOR_SCRIPT="$PROJECT_ROOT/scripts/devcontainer/generate-devcontainer.sh"

# Helper function to strip JSONC comments for jq parsing
# devcontainer.json files use JSONC (JSON with Comments) which jq doesn't support
strip_jsonc_comments() {
    local file="$1"
    # Use Python to strip comments and trailing commas from JSONC
    # This handles single-line comments, multi-line comments, and trailing commas
    python3 << 'PYTHON_SCRIPT'
import re
import json

def strip_jsonc(text):
    # Remove single-line comments (//...) but not inside strings
    # Strategy: remove // comments only at line start or after whitespace
    lines = []
    for line in text.split('\n'):
        # Find // outside of strings (simple heuristic)
        comment_pos = -1
        in_string = False
        escape_next = False

        for i, char in enumerate(line):
            if escape_next:
                escape_next = False
                continue
            if char == '\\':
                escape_next = True
                continue
            if char == '"' and not escape_next:
                in_string = not in_string
            if not in_string and i < len(line) - 1 and line[i:i+2] == '//':
                comment_pos = i
                break

        if comment_pos >= 0:
            lines.append(line[:comment_pos].rstrip())
        else:
            lines.append(line)

    text = '\n'.join(lines)

    # Remove trailing commas before ] or }
    text = re.sub(r',(\s*[}\]])', r'\1', text)

    return text

with open("'"$file"'", 'r') as f:
    content = f.read()
    print(strip_jsonc(content))
PYTHON_SCRIPT
}

# Setup and teardown
setup() {
    # Create temporary test directory
    TEST_DIR="$(mktemp -d)"
    TEST_PROJECT="$TEST_DIR/test-project"
}

teardown() {
    # Cleanup temporary directory
    [ -n "$TEST_DIR" ] && rm -rf "$TEST_DIR"
}

# =============================================================================
# Templates Directory Tests
# =============================================================================

@test "devcontainer templates directory exists" {
    [ -d "$TEMPLATES_DIR" ]
}

@test "base template exists" {
    [ -d "$TEMPLATES_DIR/base" ]
    [ -d "$TEMPLATES_DIR/base/.devcontainer" ]
}

@test "python template exists" {
    [ -d "$TEMPLATES_DIR/python" ]
    [ -d "$TEMPLATES_DIR/python/.devcontainer" ]
}

@test "nodejs template exists" {
    [ -d "$TEMPLATES_DIR/nodejs" ]
    [ -d "$TEMPLATES_DIR/nodejs/.devcontainer" ]
}

# =============================================================================
# Base Template Tests
# =============================================================================

@test "base: devcontainer.json exists" {
    [ -f "$TEMPLATES_DIR/base/.devcontainer/devcontainer.json" ]
}

@test "base: devcontainer.json is valid JSON" {
    run bash -c "strip_jsonc_comments '$TEMPLATES_DIR/base/.devcontainer/devcontainer.json' | jq empty"
    [ "$status" -eq 0 ]
}

@test "base: devcontainer.json has required fields" {
    # Test name field
    run python3 -c "$(cat << 'PYCODE'
import json, re
def strip_jsonc(text):
    lines = []
    for line in text.split('\n'):
        comment_pos = -1
        in_string = False
        for i, char in enumerate(line):
            if char == '"': in_string = not in_string
            if not in_string and i < len(line) - 1 and line[i:i+2] == '//':
                comment_pos = i
                break
        lines.append(line[:comment_pos].rstrip() if comment_pos >= 0 else line)
    text = '\n'.join(lines)
    text = re.sub(r',(\s*[}\]])', r'\1', text)
    return text
with open('$TEMPLATES_DIR/base/.devcontainer/devcontainer.json') as f:
    data = json.loads(strip_jsonc(f.read()))
    print(data['name'])
PYCODE
)"
    [ "$status" -eq 0 ]
    [[ "$output" != "null" ]]

    # Test image field
    run python3 -c "$(cat << 'PYCODE'
import json, re
def strip_jsonc(text):
    lines = []
    for line in text.split('\n'):
        comment_pos = -1
        in_string = False
        for i, char in enumerate(line):
            if char == '"': in_string = not in_string
            if not in_string and i < len(line) - 1 and line[i:i+2] == '//':
                comment_pos = i
                break
        lines.append(line[:comment_pos].rstrip() if comment_pos >= 0 else line)
    text = '\n'.join(lines)
    text = re.sub(r',(\s*[}\]])', r'\1', text)
    return text
with open('$TEMPLATES_DIR/base/.devcontainer/devcontainer.json') as f:
    data = json.loads(strip_jsonc(f.read()))
    print(data['image'])
PYCODE
)"
    [ "$status" -eq 0 ]
    [[ "$output" == "dotfiles-ubuntu:dev" ]]
}

@test "base: Dockerfile exists" {
    [ -f "$TEMPLATES_DIR/base/.devcontainer/Dockerfile" ]
}

@test "base: docker-compose.yml exists" {
    [ -f "$TEMPLATES_DIR/base/.devcontainer/docker-compose.yml" ]
}

@test "base: README.md exists" {
    [ -f "$TEMPLATES_DIR/base/README.md" ]
}

# =============================================================================
# Python Template Tests
# =============================================================================

@test "python: devcontainer.json exists" {
    [ -f "$TEMPLATES_DIR/python/.devcontainer/devcontainer.json" ]
}

@test "python: devcontainer.json has Python extensions" {
    run bash -c "strip_jsonc_comments '$TEMPLATES_DIR/python/.devcontainer/devcontainer.json' | jq -r '.customizations.vscode.extensions[]'"
    [ "$status" -eq 0 ]
    [[ "$output" == *"ms-python.python"* ]]
}

@test "python: devcontainer.json forwards Python ports" {
    run bash -c "strip_jsonc_comments '$TEMPLATES_DIR/python/.devcontainer/devcontainer.json' | jq -r '.forwardPorts[]'"
    [ "$status" -eq 0 ]
    [[ "$output" == *"8000"* ]] || [[ "$output" == *"5000"* ]]
}

@test "python: Dockerfile exists and extends dotfiles" {
    [ -f "$TEMPLATES_DIR/python/.devcontainer/Dockerfile" ]
    run grep "FROM dotfiles-ubuntu:dev" "$TEMPLATES_DIR/python/.devcontainer/Dockerfile"
    [ "$status" -eq 0 ]
}

@test "python: post-create.sh exists and is executable" {
    [ -f "$TEMPLATES_DIR/python/.devcontainer/post-create.sh" ]
    [ -x "$TEMPLATES_DIR/python/.devcontainer/post-create.sh" ]
}

@test "python: post-create.sh has proper shebang" {
    run head -n 1 "$TEMPLATES_DIR/python/.devcontainer/post-create.sh"
    [ "$status" -eq 0 ]
    [[ "$output" == "#!/bin/bash" ]]
}

# =============================================================================
# Node.js Template Tests
# =============================================================================

@test "nodejs: devcontainer.json exists" {
    [ -f "$TEMPLATES_DIR/nodejs/.devcontainer/devcontainer.json" ]
}

@test "nodejs: devcontainer.json has Node.js extensions" {
    run bash -c "strip_jsonc_comments '$TEMPLATES_DIR/nodejs/.devcontainer/devcontainer.json' | jq -r '.customizations.vscode.extensions[]'"
    [ "$status" -eq 0 ]
    [[ "$output" == *"dbaeumer.vscode-eslint"* ]] || [[ "$output" == *"esbenp.prettier-vscode"* ]]
}

@test "nodejs: devcontainer.json forwards Node.js ports" {
    run bash -c "strip_jsonc_comments '$TEMPLATES_DIR/nodejs/.devcontainer/devcontainer.json' | jq -r '.forwardPorts[]'"
    [ "$status" -eq 0 ]
    [[ "$output" == *"3000"* ]] || [[ "$output" == *"8080"* ]]
}

@test "nodejs: Dockerfile exists" {
    [ -f "$TEMPLATES_DIR/nodejs/.devcontainer/Dockerfile" ]
}

@test "nodejs: post-create.sh exists and is executable" {
    [ -f "$TEMPLATES_DIR/nodejs/.devcontainer/post-create.sh" ]
    [ -x "$TEMPLATES_DIR/nodejs/.devcontainer/post-create.sh" ]
}

# =============================================================================
# Generator Script Tests
# =============================================================================

@test "generator script exists and is executable" {
    [ -f "$GENERATOR_SCRIPT" ]
    [ -x "$GENERATOR_SCRIPT" ]
}

@test "generator script has proper shebang" {
    run head -n 1 "$GENERATOR_SCRIPT"
    [ "$status" -eq 0 ]
    [[ "$output" == "#!/usr/bin/env bash" ]]
}

@test "generator script has help option" {
    run "$GENERATOR_SCRIPT" --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"Dev Container Generator"* ]]
}

@test "generator script lists available templates" {
    run "$GENERATOR_SCRIPT" --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"base"* ]]
    [[ "$output" == *"python"* ]]
    [[ "$output" == *"nodejs"* ]]
}

# =============================================================================
# Generator Functionality Tests
# =============================================================================

@test "generator: fails without template" {
    run "$GENERATOR_SCRIPT" --project "$TEST_PROJECT"
    [ "$status" -ne 0 ]
    [[ "$output" == *"Template is required"* ]]
}

@test "generator: fails without project" {
    run "$GENERATOR_SCRIPT" --template base
    [ "$status" -ne 0 ]
    [[ "$output" == *"Project path is required"* ]]
}

@test "generator: fails with invalid template" {
    run "$GENERATOR_SCRIPT" --template invalid --project "$TEST_PROJECT"
    [ "$status" -ne 0 ]
    [[ "$output" == *"Invalid template"* ]]
}

@test "generator: dry-run mode works" {
    run "$GENERATOR_SCRIPT" --template base --project "$TEST_PROJECT" --dry-run
    [ "$status" -eq 0 ]
    [[ "$output" == *"DRY RUN"* ]]
    # Should not create files
    [ ! -d "$TEST_PROJECT/.devcontainer" ]
}

@test "generator: creates base template successfully" {
    run "$GENERATOR_SCRIPT" --template base --project "$TEST_PROJECT"
    [ "$status" -eq 0 ]

    # Check files were created
    [ -d "$TEST_PROJECT/.devcontainer" ]
    [ -f "$TEST_PROJECT/.devcontainer/devcontainer.json" ]
    [ -f "$TEST_PROJECT/.devcontainer/Dockerfile" ]
    [ -f "$TEST_PROJECT/.devcontainer/docker-compose.yml" ]
}

@test "generator: creates python template successfully" {
    run "$GENERATOR_SCRIPT" --template python --project "$TEST_PROJECT"
    [ "$status" -eq 0 ]

    # Check Python-specific files
    [ -d "$TEST_PROJECT/.devcontainer" ]
    [ -f "$TEST_PROJECT/.devcontainer/devcontainer.json" ]
    [ -f "$TEST_PROJECT/.devcontainer/Dockerfile" ]
    [ -f "$TEST_PROJECT/.devcontainer/post-create.sh" ]
    [ -x "$TEST_PROJECT/.devcontainer/post-create.sh" ]
}

@test "generator: creates nodejs template successfully" {
    run "$GENERATOR_SCRIPT" --template nodejs --project "$TEST_PROJECT"
    [ "$status" -eq 0 ]

    # Check Node.js-specific files
    [ -d "$TEST_PROJECT/.devcontainer" ]
    [ -f "$TEST_PROJECT/.devcontainer/devcontainer.json" ]
    [ -f "$TEST_PROJECT/.devcontainer/Dockerfile" ]
    [ -f "$TEST_PROJECT/.devcontainer/post-create.sh" ]
}

@test "generator: fails if .devcontainer exists without force" {
    # Create .devcontainer directory
    mkdir -p "$TEST_PROJECT/.devcontainer"

    run "$GENERATOR_SCRIPT" --template base --project "$TEST_PROJECT"
    [ "$status" -ne 0 ]
    [[ "$output" == *"already exists"* ]]
}

@test "generator: force flag overwrites existing .devcontainer" {
    # Create existing .devcontainer
    mkdir -p "$TEST_PROJECT/.devcontainer"
    echo "old content" > "$TEST_PROJECT/.devcontainer/test.txt"

    run "$GENERATOR_SCRIPT" --template base --project "$TEST_PROJECT" --force
    [ "$status" -eq 0 ]

    # Old file should be gone
    [ ! -f "$TEST_PROJECT/.devcontainer/test.txt" ]

    # New files should exist
    [ -f "$TEST_PROJECT/.devcontainer/devcontainer.json" ]
}

# =============================================================================
# Generated Files Validation Tests
# =============================================================================

@test "generated: devcontainer.json is valid JSON" {
    "$GENERATOR_SCRIPT" --template base --project "$TEST_PROJECT" >/dev/null 2>&1

    run bash -c "strip_jsonc_comments '$TEST_PROJECT/.devcontainer/devcontainer.json' | jq empty"
    [ "$status" -eq 0 ]
}

@test "generated: devcontainer.json has Claude Code env vars" {
    "$GENERATOR_SCRIPT" --template python --project "$TEST_PROJECT" >/dev/null 2>&1

    run bash -c "strip_jsonc_comments '$TEST_PROJECT/.devcontainer/devcontainer.json' | jq -r '.remoteEnv.CLAUDE_CODE_CONTAINER'"
    [ "$status" -eq 0 ]
    [ "$output" == "true" ]

    run bash -c "strip_jsonc_comments '$TEST_PROJECT/.devcontainer/devcontainer.json' | jq -r '.remoteEnv.PROJECT_ROOT'"
    [ "$status" -eq 0 ]
    [ "$output" == "/workspace" ]
}

@test "generated: docker-compose.yml is valid YAML" {
    "$GENERATOR_SCRIPT" --template base --project "$TEST_PROJECT" >/dev/null 2>&1

    # Check if yq is available (YAML processor)
    if command -v yq >/dev/null 2>&1; then
        run yq eval '.version' "$TEST_PROJECT/.devcontainer/docker-compose.yml"
        [ "$status" -eq 0 ]
    else
        skip "yq not available for YAML validation"
    fi
}

@test "generated: Dockerfile has proper FROM statement" {
    "$GENERATOR_SCRIPT" --template python --project "$TEST_PROJECT" >/dev/null 2>&1

    run grep "^FROM" "$TEST_PROJECT/.devcontainer/Dockerfile"
    [ "$status" -eq 0 ]
    [[ "$output" == *"dotfiles-ubuntu:dev"* ]]
}

# =============================================================================
# Template Content Tests
# =============================================================================

@test "all templates: devcontainer.json specifies remoteUser" {
    for template in base python nodejs; do
        run bash -c "strip_jsonc_comments '$TEMPLATES_DIR/$template/.devcontainer/devcontainer.json' | jq -r '.remoteUser'"
        [ "$status" -eq 0 ]
        [ "$output" == "developer" ]
    done
}

@test "all templates: devcontainer.json specifies workspaceFolder" {
    for template in base python nodejs; do
        run bash -c "strip_jsonc_comments '$TEMPLATES_DIR/$template/.devcontainer/devcontainer.json' | jq -r '.workspaceFolder'"
        [ "$status" -eq 0 ]
        [ "$output" == "/workspace" ]
    done
}

@test "all templates: Dockerfile has LABEL maintainer" {
    for template in base python nodejs; do
        if [ -f "$TEMPLATES_DIR/$template/.devcontainer/Dockerfile" ]; then
            run grep "LABEL maintainer" "$TEMPLATES_DIR/$template/.devcontainer/Dockerfile"
            [ "$status" -eq 0 ]
        fi
    done
}

# =============================================================================
# Documentation Tests
# =============================================================================

@test "devcontainer guide exists" {
    [ -f "$PROJECT_ROOT/docs/docker/DEVCONTAINER-GUIDE.md" ]
}

@test "devcontainer guide is comprehensive" {
    run wc -l "$PROJECT_ROOT/docs/docker/DEVCONTAINER-GUIDE.md"
    [ "$status" -eq 0 ]
    # Should be substantial (> 500 lines)
    lines=$(echo "$output" | awk '{print $1}')
    [ "$lines" -gt 500 ]
}

@test "devcontainer guide mentions all templates" {
    for template in base python nodejs; do
        run grep -i "$template" "$PROJECT_ROOT/docs/docker/DEVCONTAINER-GUIDE.md"
        [ "$status" -eq 0 ]
    done
}

@test "devcontainer guide mentions Claude Code" {
    run grep -i "claude code" "$PROJECT_ROOT/docs/docker/DEVCONTAINER-GUIDE.md"
    [ "$status" -eq 0 ]
}

# =============================================================================
# Integration Tests
# =============================================================================

@test "integration: can generate and validate Python dev container" {
    # Generate
    "$GENERATOR_SCRIPT" --template python --project "$TEST_PROJECT" >/dev/null 2>&1

    # Validate structure
    [ -d "$TEST_PROJECT/.devcontainer" ]
    [ -f "$TEST_PROJECT/.devcontainer/devcontainer.json" ]
    [ -f "$TEST_PROJECT/.devcontainer/Dockerfile" ]
    [ -f "$TEST_PROJECT/.devcontainer/post-create.sh" ]

    # Validate JSON
    jq empty "$TEST_PROJECT/.devcontainer/devcontainer.json"

    # Validate Dockerfile
    grep "FROM dotfiles-ubuntu:dev" "$TEST_PROJECT/.devcontainer/Dockerfile" >/dev/null
}

@test "integration: can generate and validate Node.js dev container" {
    # Generate
    "$GENERATOR_SCRIPT" --template nodejs --project "$TEST_PROJECT" >/dev/null 2>&1

    # Validate structure
    [ -d "$TEST_PROJECT/.devcontainer" ]
    [ -f "$TEST_PROJECT/.devcontainer/devcontainer.json" ]

    # Validate ports are configured
    run bash -c "strip_jsonc_comments '$TEST_PROJECT/.devcontainer/devcontainer.json' | jq -r '.forwardPorts[]'"
    [ "$status" -eq 0 ]
}

# =============================================================================
# CLI Output Tests
# =============================================================================

@test "generator: shows next steps after successful generation" {
    run "$GENERATOR_SCRIPT" --template base --project "$TEST_PROJECT"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Next steps"* ]]
    [[ "$output" == *"code $TEST_PROJECT"* ]]
}

@test "generator: output includes template name" {
    run "$GENERATOR_SCRIPT" --template python --project "$TEST_PROJECT"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Template: python"* ]]
}

@test "generator: output includes project path" {
    run "$GENERATOR_SCRIPT" --template base --project "$TEST_PROJECT"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Project: $TEST_PROJECT"* ]]
}
