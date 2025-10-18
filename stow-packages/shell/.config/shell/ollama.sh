#!/usr/bin/env bash
# =============================================================================
# Ollama Model Aliases
# Managed by dotfiles: ~/dev/projects/dotfiles
# =============================================================================

# =============================================================================
# Embeddings
# =============================================================================

alias ollama-embeddings="OLLAMA_HOST=localhost:11435 ollama run nomic-embed-text-v2-moe.Q8_0:latest"

# =============================================================================
# Tools
# =============================================================================

alias ollama-tools="OLLAMA_HOST=localhost:11436 ollama run Llama-3-Groq-8B-Tool-Use-Q4_K_M:latest"

# =============================================================================
# Small Models (8B)
# =============================================================================

alias ollama-small="OLLAMA_HOST=localhost:11437 ollama run Qwen3-8B-Q4_K_S:latest"
alias ollama-small-mistral="OLLAMA_HOST=localhost:11437 ollama run Mistral-7B-Instruct-v0.3.Q4_K_S:latest"
alias ollama-small-qwen="OLLAMA_HOST=localhost:11437 ollama run Qwen3-8B-Q4_K_S:latest"
alias ollama-small-deepseek="OLLAMA_HOST=localhost:11437 ollama run DeepSeek-R1-Distill-Qwen-7B-Q4_K_M:latest"
alias ollama-small-llama="OLLAMA_HOST=localhost:11437 ollama run llama3.1:8b"
alias ollama-small-gemma="OLLAMA_HOST=localhost:11437 ollama run gemma-3-4b-it.Q4_K_S:latest"

# =============================================================================
# Medium Models (14-24B)
# =============================================================================

alias ollama-medium="OLLAMA_HOST=localhost:11438 ollama run Qwen_Qwen3-14B-Q4_K_L:latest"
alias ollama-medium-qwen="OLLAMA_HOST=localhost:11438 ollama run Qwen_Qwen3-14B-Q4_K_L:latest"
alias ollama-mistral="OLLAMA_HOST=localhost:11438 ollama run Mistral-Small-3.2-24B-Instruct-2506-Q4_K_S:latest"

# =============================================================================
# Large Models (27-32B)
# =============================================================================

alias ollama-large="OLLAMA_HOST=localhost:11439 ollama run Qwen_Qwen3-30B-A3B-Q6_K_L:latest"
alias ollama-large-qwen="OLLAMA_HOST=localhost:11439 ollama run Qwen_Qwen3-30B-A3B-Q6_K_L:latest"
alias ollama-large-deepseek="OLLAMA_HOST=localhost:11439 ollama run DeepSeek-R1-Distill-Qwen-32B-Q4_K_S:latest"
alias ollama-large-gemma="OLLAMA_HOST=localhost:11439 ollama run gemma-3-27B-it-QAT-Q4_0:latest"

# =============================================================================
# XLarge Models (70B)
# =============================================================================

alias ollama-xlarge="OLLAMA_HOST=localhost:11440 ollama run Llama-3.3-70B-Instruct-Q4_K_M:latest"

# =============================================================================
# Code Models
# =============================================================================

alias ollama-code="OLLAMA_HOST=localhost:11441 ollama run Devstral-Small-2505-Q4_K_M:latest"

# =============================================================================
# End of Ollama aliases
# =============================================================================
