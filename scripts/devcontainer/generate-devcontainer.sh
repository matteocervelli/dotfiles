#!/usr/bin/env bash
# Dev Container Generator Script
# Creates project-specific dev containers from templates
#
# Usage:
#   ./scripts/devcontainer/generate-devcontainer.sh --template python --project ~/my-project
#   ./scripts/devcontainer/generate-devcontainer.sh -t nodejs -p ~/web-app --force
#
# Templates:
#   base         - Base container (ZSH + Git + Docker CLI)
#   python       - Python development (Python 3, pip, poetry, pytest)
#   nodejs       - Node.js development (Node.js, npm, pnpm, yarn)
#   fullstack    - Full-stack (Python + Node.js + PostgreSQL + Redis)
#   data-science - Data science (Python + Jupyter + pandas + NumPy)

set -eo pipefail

# Script directory and root detection
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source utilities
# shellcheck source=../utils/logger.sh
source "$PROJECT_ROOT/scripts/utils/logger.sh"

# Configuration
TEMPLATE=""
PROJECT_PATH=""
FORCE=0
DRY_RUN=0
VERBOSE=0

TEMPLATES_DIR="$PROJECT_ROOT/templates/devcontainer"
AVAILABLE_TEMPLATES=("base" "python" "nodejs" "fullstack" "data-science")

# =============================================================================
# Helper Functions
# =============================================================================

show_help() {
    cat << EOF
Dev Container Generator

Generate project-specific dev containers from templates for isolated development
with Claude Code and VS Code.

USAGE:
    $0 [OPTIONS]

OPTIONS:
    -t, --template TYPE     Dev container template (base, python, nodejs, fullstack, data-science)
    -p, --project PATH      Target project directory
    -f, --force             Overwrite existing .devcontainer directory
    -n, --dry-run           Preview what would be created
    -v, --verbose           Show detailed output
    -h, --help              Show this help message

TEMPLATES:
    base                    Base container (ZSH + Git + Docker CLI)
    python                  Python development (Python 3, pip, poetry, pytest)
    nodejs                  Node.js development (Node.js, npm, pnpm, yarn)
    fullstack               Full-stack (Python + Node.js + PostgreSQL + Redis)
    data-science            Data science (Python + Jupyter + pandas + NumPy)

EXAMPLES:
    # Create Python dev container
    $0 --template python --project ~/my-python-app

    # Create Node.js dev container with force
    $0 -t nodejs -p ~/my-web-app --force

    # Preview what would be created
    $0 --template base --project ~/my-project --dry-run

WORKFLOW:
    1. Generate dev container: $0 -t python -p ~/my-app
    2. Open in VS Code: code ~/my-app
    3. Reopen in Container: Cmd+Shift+P → "Dev Containers: Reopen in Container"
    4. Start coding with Claude Code in isolated environment

REQUIREMENTS:
    - Docker or Podman installed
    - VS Code with Dev Containers extension (optional)
    - Dotfiles Docker images built (make docker-build-all)

EOF
}

# Parse command-line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -t|--template)
                TEMPLATE="$2"
                shift 2
                ;;
            -p|--project)
                PROJECT_PATH="$2"
                shift 2
                ;;
            -f|--force)
                FORCE=1
                shift
                ;;
            -n|--dry-run)
                DRY_RUN=1
                shift
                ;;
            -v|--verbose)
                VERBOSE=1
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

# Validate arguments
validate_args() {
    # Check template
    if [[ -z "$TEMPLATE" ]]; then
        log_error "Template is required. Use -t or --template"
        echo ""
        echo "Available templates: ${AVAILABLE_TEMPLATES[*]}"
        exit 1
    fi

    # Validate template exists
    local found=0
    for t in "${AVAILABLE_TEMPLATES[@]}"; do
        if [[ "$t" == "$TEMPLATE" ]]; then
            found=1
            break
        fi
    done

    if [[ $found -eq 0 ]]; then
        log_error "Invalid template: $TEMPLATE"
        echo ""
        echo "Available templates: ${AVAILABLE_TEMPLATES[*]}"
        exit 1
    fi

    # Check template directory exists
    if [[ ! -d "$TEMPLATES_DIR/$TEMPLATE" ]]; then
        log_error "Template directory not found: $TEMPLATES_DIR/$TEMPLATE"
        exit 1
    fi

    # Check project path
    if [[ -z "$PROJECT_PATH" ]]; then
        log_error "Project path is required. Use -p or --project"
        exit 1
    fi

    # Expand ~ to home directory
    PROJECT_PATH="${PROJECT_PATH/#\~/$HOME}"

    # Create project directory if it doesn't exist
    if [[ ! -d "$PROJECT_PATH" ]]; then
        if [[ $DRY_RUN -eq 0 ]]; then
            log_info "Creating project directory: $PROJECT_PATH"
            mkdir -p "$PROJECT_PATH"
        else
            log_info "[DRY RUN] Would create: $PROJECT_PATH"
        fi
    fi

    # Check if .devcontainer already exists
    if [[ -d "$PROJECT_PATH/.devcontainer" ]] && [[ $FORCE -eq 0 ]]; then
        log_error ".devcontainer directory already exists: $PROJECT_PATH/.devcontainer"
        log_info "Use --force to overwrite"
        exit 1
    fi
}

# Copy template to project
copy_template() {
    log_step "Generating dev container for project..."
    echo ""

    log_info "Template: $TEMPLATE"
    log_info "Project: $PROJECT_PATH"
    echo ""

    if [[ $DRY_RUN -eq 1 ]]; then
        log_warning "DRY RUN MODE - No files will be created"
        echo ""
    fi

    # Remove existing .devcontainer if force is enabled
    if [[ -d "$PROJECT_PATH/.devcontainer" ]] && [[ $FORCE -eq 1 ]]; then
        if [[ $DRY_RUN -eq 0 ]]; then
            log_info "Removing existing .devcontainer directory..."
            rm -rf "$PROJECT_PATH/.devcontainer"
        else
            log_info "[DRY RUN] Would remove: $PROJECT_PATH/.devcontainer"
        fi
    fi

    # Copy template
    if [[ $DRY_RUN -eq 0 ]]; then
        log_info "Copying template files..."
        cp -r "$TEMPLATES_DIR/$TEMPLATE/.devcontainer" "$PROJECT_PATH/"

        # Copy README if exists
        if [[ -f "$TEMPLATES_DIR/$TEMPLATE/README.md" ]]; then
            cp "$TEMPLATES_DIR/$TEMPLATE/README.md" "$PROJECT_PATH/.devcontainer/"
        fi

        log_success "Template files copied"
    else
        log_info "[DRY RUN] Would copy files from: $TEMPLATES_DIR/$TEMPLATE/.devcontainer"
        log_info "[DRY RUN] Would copy to: $PROJECT_PATH/.devcontainer"
    fi

    # Set proper permissions
    if [[ $DRY_RUN -eq 0 ]]; then
        if [[ -f "$PROJECT_PATH/.devcontainer/post-create.sh" ]]; then
            chmod +x "$PROJECT_PATH/.devcontainer/post-create.sh"
            [[ $VERBOSE -eq 1 ]] && log_info "Made post-create.sh executable"
        fi
    fi
}

# Show created files
show_created_files() {
    log_step "Created files:"
    echo ""

    if [[ $DRY_RUN -eq 0 ]]; then
        tree -L 2 "$PROJECT_PATH/.devcontainer" 2>/dev/null || \
        find "$PROJECT_PATH/.devcontainer" -type f -exec echo "  {}" \;
    else
        log_info "[DRY RUN] Would create the following structure:"
        tree -L 2 "$TEMPLATES_DIR/$TEMPLATE/.devcontainer" 2>/dev/null || \
        find "$TEMPLATES_DIR/$TEMPLATE/.devcontainer" -type f -exec echo "  {}" \;
    fi

    echo ""
}

# Show next steps
show_next_steps() {
    log_success "Dev container generated successfully!"
    echo ""
    log_info "Next steps:"
    echo ""
    echo "  1. Review configuration:"
    echo "     cat $PROJECT_PATH/.devcontainer/devcontainer.json"
    echo ""
    echo "  2. Open project in VS Code:"
    echo "     code $PROJECT_PATH"
    echo ""
    echo "  3. Reopen in container:"
    echo "     Cmd/Ctrl + Shift + P → 'Dev Containers: Reopen in Container'"
    echo ""
    echo "  4. Or use Docker Compose directly:"
    echo "     cd $PROJECT_PATH"
    echo "     docker-compose -f .devcontainer/docker-compose.yml up -d"
    echo "     docker-compose -f .devcontainer/docker-compose.yml exec devcontainer zsh"
    echo ""
    echo "  5. Claude Code integration:"
    echo "     - Environment variables set: CLAUDE_CODE_CONTAINER=true"
    echo "     - Workspace mounted at: /workspace"
    echo "     - Safe for 'dangerously skip mode' operations"
    echo ""
    log_info "Documentation: $PROJECT_PATH/.devcontainer/README.md"
}

# =============================================================================
# Main Execution
# =============================================================================

main() {
    # Parse arguments
    parse_args "$@"

    # Validate arguments
    validate_args

    # Copy template
    copy_template

    # Show created files
    [[ $VERBOSE -eq 1 ]] && show_created_files

    # Show next steps (only if not dry run)
    if [[ $DRY_RUN -eq 0 ]]; then
        show_next_steps
    else
        echo ""
        log_info "Dry run complete. Use without --dry-run to create files."
    fi
}

# Run main function
main "$@"
