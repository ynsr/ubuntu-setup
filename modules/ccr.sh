#!/bin/bash
# modules/ccr.sh — Sets up claude-code-router (CCR) behind Nginx, mapped to
# /ccr on the bare domain.
# https://github.com/musistudio/claude-code-router
#
# NOT IMPLEMENTED YET.
#
# Notes for future implementation:
#   - This module should live on the bare domain (not a subdomain) per the
#     project's path layout: https://<domain>/ccr/
#   - Confirm whether CCR's frontend (if any) uses absolute or relative
#     asset paths before choosing between a plain prefix proxy and an
#     asset-path rewrite (sub_filter), to avoid the same issue solved for
#     FreeLLMAPI via subdomain.
#
# Invoked by setup.sh; expects lib/colors.sh, lib/logging.sh, lib/prompt.sh,
# and lib/nginx_common.sh to already be sourced.

setup_ccr() {
  warning "claude-code-router setup is not implemented yet."
  echo "This module is a placeholder. Contributions/implementation welcome."
}
