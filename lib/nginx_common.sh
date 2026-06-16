#!/bin/bash
# nginx_common.sh — shared system/Nginx/Certbot helpers used by every module.
# Source this file after colors.sh and logging.sh; do not execute directly.

readonly DEFAULT_WEBROOT="/var/www/html"
readonly DEFAULT_CERT_RENEW_THRESHOLD_DAYS=30

# check_root
# Exits if not running as root.
check_root() {
  [[ $EUID -eq 0 ]] || error "This script must be run as root. Use: sudo $0"
}

# check_dns DOMAIN
# Warns (does not fail) if DOMAIN does not currently point at this server's
# public IP. DNS propagation delays or split IPv4/IPv6 setups are common and
# not always a real misconfiguration, so this is informational only.
check_dns() {
  local domain="$1"
  log "Checking DNS resolution for ${domain}..."

  local server_ip domain_ip
  server_ip=$(curl -sf -4 ifconfig.me) || warning "Could not determine server public IPv4 address"
  domain_ip=$(dig +short "$domain" | head -1)

  if [[ -z "$domain_ip" ]]; then
    error "Domain ${domain} does not resolve. Configure DNS first."
  fi

  if [[ -n "$server_ip" && "$domain_ip" != "$server_ip" ]]; then
    warning "Domain resolves to ${domain_ip} but server IPv4 is ${server_ip}. Verify DNS if this is unexpected."
  else
    success "DNS resolves correctly"
  fi
}

# install_packages PACKAGE [PACKAGE...]
# apt-get update + install, quiet, non-interactive.
install_packages() {
  log "Installing required packages: $*"
  apt-get update -y -qq
  apt-get install -y -qq "$@"
}

# clean_nginx_conflicts
# Removes default/enabled sites and any config still binding the legacy
# port 8080 (left over from older single-app setups). Safe to re-run.
clean_nginx_conflicts() {
  log "Removing default and conflicting Nginx configurations..."
  rm -f /etc/nginx/sites-enabled/default
  rm -f /etc/nginx/sites-available/default
  # grep exits 1 on "no matches" which is the expected common case — don't
  # let that trip set -e / pipefail and abort the script.
  grep -rl "listen.*8080" /etc/nginx/conf.d/ /etc/nginx/sites-available/ 2>/dev/null | xargs -r rm -f || true
  success "Conflicting configurations removed"
}

# enable_nginx_site SITE_AVAILABLE_PATH SITE_ENABLED_PATH
# Symlinks an available site into sites-enabled.
enable_nginx_site() {
  local available="$1"
  local enabled="$2"
  ln -sf "$available" "$enabled"
}

# test_nginx
# Validates the full Nginx config; exits on failure.
test_nginx() {
  log "Testing Nginx configuration..."
  nginx -t || error "Nginx configuration test failed"
  success "Nginx configuration is valid"
}

# start_nginx
# Starts and enables the Nginx service.
start_nginx() {
  log "Starting Nginx..."
  systemctl start nginx
  systemctl enable nginx >/dev/null 2>&1
  success "Nginx started and enabled"
}

# reload_nginx
reload_nginx() {
  systemctl reload nginx
}

# stop_port_listener PORT
# Kills whatever process is listening on PORT (TCP), if any. Tries SIGTERM
# before SIGKILL.
stop_port_listener() {
  local port="$1"
  log "Checking for processes using port ${port}..."

  if ss -tlnp | grep -q ":${port}"; then
    local pid
    pid=$(ss -tlnp | grep ":${port}" | awk '{print $6}' | cut -d',' -f2 | cut -d'=' -f2)
    warning "Port ${port} is used by PID ${pid}. Stopping process..."
    kill -TERM "$pid" 2>/dev/null || kill -KILL "$pid" 2>/dev/null || true
    success "Stopped process on port ${port}"
  fi
}

# cert_days_left CERT_FILE
# Echoes days remaining until CERT_FILE's expiry, or 0 if it doesn't exist.
cert_days_left() {
  local cert_file="$1"
  [[ -f "$cert_file" ]] || { echo "0"; return; }

  local end_date end_epoch now_epoch
  end_date=$(openssl x509 -enddate -noout -in "$cert_file" | cut -d= -f2)
  end_epoch=$(date -d "$end_date" +%s)
  now_epoch=$(date +%s)
  echo $(( (end_epoch - now_epoch) / 86400 ))
}

# obtain_ssl_webroot DOMAIN WEBROOT CERT_FILE [FORCE_RENEW]
# Obtains/renews a Let's Encrypt certificate via the webroot method.
# Skips renewal if the cert is valid for >= threshold days, unless
# FORCE_RENEW is "true".
obtain_ssl_webroot() {
  local domain="$1"
  local webroot="$2"
  local cert_file="$3"
  local force_renew="${4:-false}"

  local days_left
  days_left=$(cert_days_left "$cert_file")

  if [[ "$days_left" -ge "$DEFAULT_CERT_RENEW_THRESHOLD_DAYS" && "$force_renew" != true ]]; then
    success "Valid certificate found, expires in ${days_left} days. Skipping renewal (use --force-renew to override)."
    return
  fi

  if [[ "$force_renew" == true ]]; then
    log "Force renewal requested. Renewing certificate regardless of expiry."
  else
    log "Certificate expires in ${days_left} days. Proceeding with renewal."
  fi

  systemctl stop nginx 2>/dev/null || true
  systemctl start nginx
  sleep 2

  certbot certonly --webroot \
    --webroot-path "$webroot" \
    --non-interactive \
    --agree-tos \
    --email "admin@${domain}" \
    --domains "${domain}" \
    --keep-until-expiring \
    || error "Certbot failed to obtain/renew the certificate"

  success "SSL certificate obtained/renewed with webroot method"
}

# setup_cert_auto_renewal WEBROOT
# Installs/refreshes a daily cron job for certbot renewal (webroot method).
# Idempotent: removes any prior "certbot renew" line before adding the new one.
setup_cert_auto_renewal() {
  local webroot="$1"
  log "Setting up automatic certificate renewal (webroot)..."

  {
    crontab -l 2>/dev/null | grep -v "certbot renew" || true
    echo "0 2 * * * /usr/bin/certbot renew --webroot --webroot-path ${webroot} --quiet --post-hook 'systemctl reload nginx' >> /var/log/letsencrypt-renewal.log 2>&1"
  } | crontab -

  success "Cron job added for auto-renewal (webroot method)"

  certbot renew --dry-run --webroot --webroot-path "$webroot" --quiet
  success "Auto-renewal dry-run passed"
}
