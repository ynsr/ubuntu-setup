#!/bin/bash
# modules/freellmapi.sh — Sets up FreeLLMAPI behind Nginx on its own
# subdomain, secured with a Let's Encrypt certificate (webroot method).
#
# Why a subdomain (and not a sub-path like /freellmapi/): FreeLLMAPI's
# built frontend references assets with absolute paths (e.g.
# /assets/index-*.js). Serving it under a sub-path breaks those references
# unless the app is rebuilt with a configurable base path. A dedicated
# subdomain puts the app back at "/", so nothing needs rewriting — and it
# keeps this app from ever colliding with future sub-path apps on the bare
# domain (e.g. /ccr/, /freeworld).
#
# Invoked by setup.sh; expects lib/colors.sh, lib/logging.sh, lib/prompt.sh,
# and lib/nginx_common.sh to already be sourced.

readonly FREELLMAPI_DEFAULT_DOMAIN="freellmapi.evx.imageanalysisgroup.top"
readonly FREELLMAPI_DEFAULT_PORT="3001"
readonly FREELLMAPI_TEMPLATE="${SCRIPT_DIR}/templates/freellmapi.nginx.conf.tpl"
readonly FREELLMAPI_TEMPLATE_HTTP="${SCRIPT_DIR}/templates/freellmapi.nginx.conf.http-only.tpl"

setup_freellmapi() {
  local force_renew="${1:-false}"

  echo -e "\n${BOLD}=== FreeLLMAPI Setup ===${NC}"
  echo "Sample address: https://${FREELLMAPI_DEFAULT_DOMAIN}"

  local domain api_port
  domain=$(prompt_with_default "Domain for FreeLLMAPI" "$FREELLMAPI_DEFAULT_DOMAIN")
  api_port=$(prompt_with_default "Local port FreeLLMAPI listens on" "$FREELLMAPI_DEFAULT_PORT")

  local site_available="/etc/nginx/sites-available/${domain}"
  local site_enabled="/etc/nginx/sites-enabled/${domain}"
  local webroot="$DEFAULT_WEBROOT"
  local cert_file="/etc/letsencrypt/live/${domain}/fullchain.pem"

  log "Starting FreeLLMAPI setup for ${domain}"

  check_root
  install_packages nginx certbot python3-certbot-nginx dnsutils curl openssl gettext-base
  check_dns "$domain"

  clean_nginx_conflicts
  stop_port_listener "$api_port"

  log "Creating HTTP-only Nginx configuration for ${domain}..."
  mkdir -p "$webroot"
  DOMAIN="$domain" \
    envsubst '${DOMAIN}' < "$FREELLMAPI_TEMPLATE_HTTP" > "$site_available"
  enable_nginx_site "$site_available" "$site_enabled"
  success "HTTP-only Nginx configuration created"

  start_nginx

  obtain_ssl_webroot "$domain" "$webroot" "$cert_file" "$force_renew"

  log "Upgrading to HTTPS configuration..."
  DOMAIN="$domain" API_PORT="$api_port" WEBROOT="$webroot" \
    envsubst '${DOMAIN} ${API_PORT} ${WEBROOT}' < "$FREELLMAPI_TEMPLATE" > "$site_available"

  test_nginx
  reload_nginx

  setup_cert_auto_renewal "$webroot"

  freellmapi_display_summary "$domain"
}

freellmapi_display_summary() {
  local domain="$1"

  success "\n══════════════════════════════════════════════════════"
  success "FreeLLMAPI SETUP COMPLETE"
  success "══════════════════════════════════════════════════════"
  echo -e "\n${GREEN}Panel:${NC}        https://${domain}/"
  echo -e "${GREEN}API Base URL:${NC} https://${domain}/v1"
  echo -e "${GREEN}Health Check:${NC} https://${domain}/health"
  echo -e "\n${BLUE}Test API call:${NC}"
  echo "  curl https://${domain}/v1/your-endpoint"
  echo -e "\n${BLUE}Setup log:${NC} ${LOG_FILE}"
}
