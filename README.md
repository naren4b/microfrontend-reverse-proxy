# Micro-Frontend Reverse Proxy Lab

This repository demonstrates path-based routing for multiple static micro-frontends behind a single Nginx edge proxy. The proxy terminates TLS on `localhost`, redirects HTTP to HTTPS, and forwards traffic to isolated Electronics and Clothing department frontends based on the URL prefix.

<img width="826" height="487" alt="image" src="https://github.com/user-attachments/assets/94a2070c-0c29-488f-ac9e-05e286c4a82a" />



## Architecture

- `my-lb`: edge Nginx instance that serves the landing page, terminates TLS, and proxies `/red` and `/blue`
- `dep-electronics`: static Nginx site for the Electronics department
- `dep-clothing`: static Nginx site for the Clothing department
- `lab-net`: shared bridge network used for container-to-container DNS resolution

Route layout:

- `/` -> landing page served by `my-lb`
- `/red` -> Electronics department root page
- `/red/scores/` -> Electronics department scores page
- `/red/users/` -> Electronics department users page
- `/blue` -> Clothing department root page
- `/blue/jobs/` -> Clothing department jobs page

## Repository Layout

```text
.
├── compose.yaml
├── README.md
├── my-lb/
│   ├── certs/
│   │   ├── tls.crt
│   │   └── tls.key
│   ├── config/
│   │   └── nginx.conf
│   └── html/
│       └── index.html
├── dep-clothing/
│   └── html/
│       ├── index.html
│       └── jobs/
│           └── index.html
├── dep-electronics/
│   └── html/
│       ├── index.html
│       ├── scores/
│       │   └── index.html
│       └── users/
│           └── index.html
└── util/
    ├── create-certificates.sh
    └── howto.md
```

## How It Works

The edge configuration lives in `my-lb/config/nginx.conf`.

- Port `80` redirects all requests to HTTPS.
- Port `443` serves the landing page and proxies `/red` and `/blue` to separate upstream containers.
- `ip_hash` is enabled for both upstreams so client requests remain sticky.
- `rewrite` and `proxy_redirect` preserve the path prefix when the backend responds with redirects for nested directories.

This avoids a common issue where a backend redirect drops the `/red` or `/blue` prefix and sends the browser to the wrong location.

## Prerequisites

- Podman with Compose support
- OpenSSL
- A shell that can run the helper script in `util/create-certificates.sh`

## Start the Lab

Create the local TLS certificate before starting the stack:

```bash
./util/create-certificates.sh
```

Then start the stack:

```bash
podman compose up -d
```

Stop the stack:

```bash
podman compose down
```

## Verify Routing

Basic checks:

```bash
curl -I http://localhost
curl -k https://localhost
curl -k https://localhost/red
curl -k https://localhost/red/scores/
curl -k https://localhost/red/users/
curl -k https://localhost/blue
curl -k https://localhost/blue/jobs/
```

Expected behavior:

- `http://localhost` returns a `301` redirect to HTTPS
- `https://localhost` serves the landing page from `my-lb/html`
- `/red...` routes to `dep-electronics`
- `/blue...` routes to `dep-clothing`

Because the certificate is self-signed, browsers and `curl` will treat it as untrusted unless you import it into your local trust store.

## Troubleshooting

If requests to nested paths redirect incorrectly:

- confirm the request includes the trailing slash for directory-style URLs such as `/red/scores/`
- confirm `my-lb/config/nginx.conf` still contains the `rewrite` and `proxy_redirect` rules for both teams

If the proxy cannot reach the backends:

- confirm all services are running with `podman ps`
- confirm the shared `lab-net` network exists
- confirm the service names in `compose.yaml` still match the upstream names in `nginx.conf`

If TLS fails to start:

- confirm `my-lb/certs/tls.crt` and `my-lb/certs/tls.key` exist
- regenerate them with `./util/create-certificates.sh` if needed

## Notes

`util/howto.md` contains the earlier manual Podman workflow. The checked-in `compose.yaml` is the simpler way to run the lab and should be the default path for this repository.
