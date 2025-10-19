#!/usr/bin/env bash
# =============================================================================
# Shell Aliases - Cross-platform
# Managed by dotfiles: ~/dev/projects/dotfiles
# =============================================================================

# =============================================================================
# Configuration & Source
# =============================================================================

# zsh
alias zshsource='source ~/.zshrc'
alias zshconfig='$EDITOR ~/.zshrc'
alias zshprofile='$EDITOR ~/.zprofile'
alias zshexports='$EDITOR ~/.config/shell/exports.sh'
alias zshfunctions='$EDITOR ~/.config/shell/functions.sh'

alias zshmacos='$EDITOR ~/.config/shell/.macos.sh'

alias zshaliases='$EDITOR ~/.config/shell/aliases.sh'
alias zshollama='$EDITOR ~/.config/shell/.ollama.sh'
alias zshhugo='$EDITOR ~/.config/shell/.hugo.sh'
alias zshpostgres='$EDITOR ~/.config/shell/.postgres.sh'


# bash
alias bashsource='source ~/.bashrc'
alias bashconfig='$EDITOR ~/.bashrc'

# =============================================================================
# Navigation
# =============================================================================

alias _home='cd ~'
alias _dev='cd ~/dev'
alias _projects='cd ~/dev/projects'
alias _dockers='cd ~/dev/compose'
alias _services='cd ~/dev/services'
alias _mcps='cd ~/dev/services/mcps'
alias _obsidian='cd ~/Brain4Change'
alias _media='cd ~/media'
alias _cdn='cd ~/media/cdn'
alias _docs='cd ~/dev/projects/DOC-AlStartUp'
alias _mccom='cd ~/dev/projects/WEB-mccom'
alias _adlimen='cd ~/dev/projects/WEB-adlimen'
alias _levero='cd ~/dev/projects/APP-levero'
alias _nutry='cd ~/dev/projects/APP-nutry'
alias _config='cd ~/.config'
alias _postgres='cd ~/.config/postgresql'
alias _postgresql='cd ~/.config/postgresql'
alias _secrets='cd ~/.secrets'

# =============================================================================
# Applications
# =============================================================================

alias claude="~/.claude/local/claude"
alias claudeconfig="code '$HOME/Library/Application Support/Claude/claude_desktop_config.json'"

# Python
alias python=python3
alias pip=pip3

# =============================================================================
# Scripts
# =============================================================================

alias newshort=~/dev/scripts/add-new-short-link.sh
alias cdnsync=~/dev/scripts/rclone-cdn-sync.sh
alias initproject=~/dev/scripts/launch-project.sh
alias ollama-sync=~/dev/scripts/add-llm-to-ollama.sh

# =============================================================================
# Automation
# =============================================================================

# GitHub labels automation
alias glabel='gh label delete --yes duplicate && gh label delete --yes "good first issue" && gh label delete --yes "help wanted" && gh label delete --yes invalid && gh label delete --yes question && gh label delete --yes wontfix && gh label clone matteocervelli/adlimen-website'

# Password generation
alias passgen="pwgen -cny \.\,\-\@\#\'\(\)\{\}\$\>\<\?\*\[\]\|\;\& 16 1"
alias passgen-8="pwgen -cny --remove-chars=\.\,\-\@\#\'\(\)\{\}\$\>\<\?\*\[\]\|\;\& 8 1"
alias passgen-12="pwgen -cny --remove-chars=\.\,\-\@\#\'\(\)\{\}\$\>\<\?\*\[\]\|\;\& 12 1"
alias passgen-16="pwgen -cny --remove-chars=\.\,\-\@\#\'\(\)\{\}\$\>\<\?\*\[\]\|\;\& 16 1"
alias passgen-20="pwgen -cny --remove-chars=\.\,\-\@\#\'\(\)\{\}\$\>\<\?\*\[\]\|\;\& 20 1"
alias passgen-24="pwgen -cny --remove-chars=\.\,\-\@\#\'\(\)\{\}\$\>\<\?\*\[\]\|\;\& 24 1"
alias passgen-28="pwgen -cny --remove-chars=\.\,\-\@\#\'\(\)\{\}\$\>\<\?\*\[\]\|\;\& 28 1"
alias passgen-32="pwgen -cny --remove-chars=\.\,\-\@\#\'\(\)\{\}\$\>\<\?\*\[\]\|\;\& 32 1"

# =============================================================================
# Network
# =============================================================================

# Note: Tailscale SSH aliases removed - now managed in SSH config
# Use: ssh macbook, ssh studio (configured in ~/.ssh/config.d/20-tailscale.conf)

# =============================================================================
# End of aliases
# =============================================================================
