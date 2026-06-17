# Template variables (substituted by modules/freellmapi.sh via envsubst):
#   DOMAIN    - subdomain this site serves, e.g. freellmapi.evx.imageanalysisgroup.top

# HTTP server block - used for initial setup and ACME challenges
server {
    listen 80;
    server_name ${DOMAIN};

    location /.well-known/acme-challenge/ {
        root /var/www/html;
    }

    location / {
        return 301 https://$server_name$request_uri;
    }
}