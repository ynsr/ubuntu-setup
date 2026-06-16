#!/bin/bash
# setup.sh — nginx-setup entry point.
#
# Presents a menu of available setup modules and dispatches to the chosen
# one. Add new modules by dropping a script into modules/ and adding one
# line to the MENU_OPTIONS / dispatch table below — no other changes needed.
#
# Usage:
#   sudo ./setup.sh                 # interactive menu
#   sudo ./setup.sh --force-renew   # forces SSL renewal in the chosen module
#                                   # (currently used by the FreeLLMAPI module)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR
export SCRIPT_DIR

LOG_FILE="/var/log/nginx-setup.log"
export LOG_FILE

# shellcheck source=lib/colors.sh
source "${SCRIPT_DIR}/lib/colors.sh"
# shellcheck source=lib/logging.sh
source "${SCRIPT_DIR}/lib/logging.sh"
# shellcheck source=lib/prompt.sh
source "${SCRIPT_DIR}/lib/prompt.sh"
# shellcheck source=lib/nginx_common.sh
source "${SCRIPT_DIR}/lib/nginx_common.sh"

source "${SCRIPT_DIR}/modules/freellmapi.sh"
source "${SCRIPT_DIR}/modules/xray.sh"
source "${SCRIPT_DIR}/modules/ccr.sh"

FORCE_RENEW=false
if [[ "${1:-}" == "--force-renew" ]]; then
  FORCE_RENEW=true
fi

main() {
  echo -e "${BOLD}nginx-setup${NC} — Ubuntu server app setup"

  local choice
  choice=$(prompt_menu "Select an option" \
    "Setup FreeLLMAPI" \
    "Setup Xray (Not implemented yet)" \
    "Setup claude-code-router (Not implemented yet)" \
    "Exit")

  case "$choice" in
    1) setup_freellmapi "$FORCE_RENEW" ;;
    2) setup_xray ;;
    3) setup_ccr ;;
    4) echo "Bye."; exit 0 ;;
  esac
}

main "$@"
