#!/bin/bash
# modules/xray.sh — Sets up Xray behind Nginx, mapped to /freeworld on the
# bare domain.
#
# NOT IMPLEMENTED YET.
#
# Notes for future implementation:
#   - Xray is typically fronted over WebSocket or gRPC, not plain HTTP proxy,
#     so the Nginx location block will need Upgrade/Connection headers
#     (WebSocket) or grpc_pass (gRPC) depending on the chosen transport.
#   - Confirm which transport (VMess/VLESS over WS, gRPC, etc.) before
#     writing the Nginx template.
#   - This module should live on the bare domain (not a subdomain) per the
#     project's path layout: https://<domain>/freeworld
#
# Invoked by setup.sh; expects lib/colors.sh, lib/logging.sh, lib/prompt.sh,
# and lib/nginx_common.sh to already be sourced.

setup_xray() {
  warning "Xray setup is not implemented yet."
  echo "This module is a placeholder. Contributions/implementation welcome."
}
