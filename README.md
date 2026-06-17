# nginx-setup

Interactive Ubuntu server setup scripts for self-hosted apps behind Nginx,
with Let's Encrypt SSL handled automatically. Run the entry point, pick an
app from the menu, answer a couple of prompts, done.

```
sudo ./setup.sh
```

```
nginx-setup — Ubuntu server app setup

Select an option
  1. Setup FreeLLMAPI
  2. Setup Xray (Not implemented yet)
  3. Setup claude-code-router (Not implemented yet)
  4. Exit
Enter your choice [1-4]:
```

## Project layout

```
nginx-setup/
├── setup.sh                          # entry point — menu + dispatch only
├── lib/
│   ├── colors.sh                     # ANSI color constants
│   ├── logging.sh                    # log / success / warning / error helpers
│   ├── prompt.sh                     # prompt_with_default, confirm, prompt_menu
│   └── nginx_common.sh               # shared Nginx/Certbot/system helpers
├── modules/
│   ├── freellmapi.sh                 # FreeLLMAPI setup (implemented)
│   ├── xray.sh                       # placeholder (not implemented)
│   └── ccr.sh                        # placeholder (not implemented)
├── templates/
│   ├── freellmapi.nginx.conf.tpl          # Full HTTPS Nginx template
│   └── freellmapi.nginx.conf.http-only.tpl # HTTP-only template for initial setup
└── README.md
```

`setup.sh` contains no app-specific logic — it only sources `lib/` and
`modules/`, shows the menu, and calls the matching `setup_<app>` function.
Everything reusable (root check, DNS check, apt install, Nginx site
enable/test/reload, port-conflict killer, Let's Encrypt obtain/renew, cron
auto-renewal) lives in `lib/nginx_common.sh` so every future module can pull
from the same toolbox instead of re-implementing it.

## How app placement is decided

Each app gets either its own **subdomain** or a **path under the bare
domain**, depending on whether its frontend was built with absolute or
relative asset paths:

| App                | Address                                         | Why |
|--------------------|--------------------------------------------------|-----|
| FreeLLMAPI         | `https://freellmapi.<domain>/`                    | Its frontend references assets with absolute paths (`/assets/...`). Serving it from a sub-path breaks those references unless the app supports a configurable base path. A dedicated subdomain puts it back at `/`, so nothing needs rewriting, and it can't collide with any other app. |
| Xray *(planned)*    | `https://<domain>/freeworld`                     | Not a browser-facing SPA — fine as a path under the bare domain. |
| claude-code-router *(planned)* | `https://<domain>/ccr/`              | To be confirmed once implemented — check whether its frontend (if any) uses absolute paths before deciding sub-path vs subdomain. |

This means the bare domain (`<domain>`) stays free for path-based apps like
`/ccr/` and `/freeworld`, and FreeLLMAPI never has to share that namespace.

## FreeLLMAPI module

Run option 1 from the menu. You'll be prompted for:

- **Domain** — defaults to `freellmapi.evx.imageanalysisgroup.top`. Must
  already point (an A/AAAA record) at this server before running, or the
  script will stop at the DNS check.
- **Local port** — defaults to `3001`, the port FreeLLMAPI listens on
  locally.

What it does, in order:

1. Verifies you're running as root.
2. Installs `nginx`, `certbot`, `python3-certbot-nginx`, `dnsutils`,
   `curl`, `openssl`, `gettext-base`.
3. Checks the domain resolves to this server's public IP (warns, doesn't
   fail, if it doesn't match — useful for split IPv4/IPv6 setups).
4. Removes conflicting/default Nginx site configs.
5. Stops anything already listening on the chosen port.
6. Renders an HTTP-only Nginx config and enables it.
7. Starts Nginx.
8. Obtains a Let's Encrypt certificate via the webroot method (skips
   renewal if the existing cert is valid for 30+ days).
9. Upgrades to the full HTTPS config, tests and reloads Nginx.
10. Installs a daily cron job for automatic renewal.
11. Prints a summary with the panel URL, API base URL, and health-check URL.

### Force SSL renewal

```
sudo ./setup.sh --force-renew
```

Forces certificate renewal regardless of how many days are left until
expiry. Applies to whichever module you select that supports it
(currently FreeLLMAPI).

### Result

- Panel: `https://<domain>/`
- API base URL: `https://<domain>/v1`
- Health check: `https://<domain>/health`

## Adding a new module

1. Create `modules/<name>.sh` with a single entry function, e.g.
   `setup_<name>()`. Source whatever you need from `lib/` — it's already
   sourced by `setup.sh` before your module runs.
2. If you need an Nginx server block, drop a template in
   `templates/<name>.nginx.conf.tpl` and render it with `envsubst`, the
   same way `modules/freellmapi.sh` does. Use a separate `.http-only.tpl`
   template if the module needs to start Nginx before SSL certificates exist.
3. In `setup.sh`:
   - `source "${SCRIPT_DIR}/modules/<name>.sh"`
   - add the menu label to the `prompt_menu` call
   - add a `case` branch calling `setup_<name>`
4. Decide subdomain vs. sub-path using the table above as a guide — check
   whether the app's frontend (if any) uses absolute asset paths before
   choosing a sub-path.

No existing module or lib file needs to change to add a new app.

## Requirements

- Ubuntu (tested target; uses `apt-get`, `systemctl`, `ss`).
- Run as root (`sudo`).
- DNS for the target domain/subdomain already pointed at the server before
  running — the script will stop and tell you if it can't resolve.

## Logs

All output is also written to `/var/log/nginx-setup.log` for later review.
