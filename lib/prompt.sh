#!/bin/bash
# prompt.sh — reusable interactive-input helpers.
# Source this file; do not execute directly.
#
# Requires: colors.sh sourced first (for CYAN/NC).

# prompt_with_default LABEL DEFAULT_VALUE
# Prints LABEL with DEFAULT_VALUE shown, reads input, echoes the chosen value
# (default applied if the user just presses Enter).
#
# Usage:
#   domain=$(prompt_with_default "Domain" "freellmapi.evx.imageanalysisgroup.top")
prompt_with_default() {
  local label="$1"
  local default_value="$2"
  local input

  read -r -p "$(echo -e "${CYAN}${label}${NC} [default: ${default_value}]: ")" input
  echo "${input:-$default_value}"
}

# confirm PROMPT_TEXT
# Returns 0 (true) on yes, 1 (false) on no. Defaults to "no" on empty input.
#
# Usage:
#   if confirm "Proceed with renewal?"; then ...; fi
confirm() {
  local prompt_text="$1"
  local input

  read -r -p "$(echo -e "${CYAN}${prompt_text}${NC} [y/N]: ")" input
  [[ "$input" =~ ^[Yy]$ ]]
}

# prompt_menu TITLE OPTION_1 OPTION_2 ...
# Prints a numbered menu, reads a numeric choice, echoes the chosen index (1-based).
# Re-prompts on invalid input. Caller maps the returned index to an action.
#
# Usage:
#   choice=$(prompt_menu "Select an option" "Setup A" "Setup B" "Exit")
prompt_menu() {
  local title="$1"
  shift
  local options=("$@")
  local count=${#options[@]}
  local choice

  echo -e "\n${BOLD}${title}${NC}" >&2
  for i in "${!options[@]}"; do
    echo "  $((i + 1)). ${options[$i]}" >&2
  done

  while true; do
    read -r -p "$(echo -e "${CYAN}Enter your choice [1-${count}]${NC}: ")" choice
    if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= count )); then
      echo "$choice"
      return 0
    fi
    echo -e "${YELLOW}Invalid choice. Please enter a number between 1 and ${count}.${NC}" >&2
  done
}
