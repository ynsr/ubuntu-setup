#!/bin/bash
# logging.sh — log/error/success/warning helpers used by every module.
# Source this file after colors.sh; do not execute directly.
#
# Requires: colors.sh sourced first.
# Honors:   LOG_FILE (set by setup.sh; defaults below if unset).

LOG_FILE="${LOG_FILE:-/var/log/nginx-setup.log}"

log() {
  echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

success() {
  echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "$LOG_FILE"
}

warning() {
  echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$LOG_FILE"
}

# error: logs the message and exits the whole script (set -e style hard stop).
error() {
  echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
  exit 1
}
