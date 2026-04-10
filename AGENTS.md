# SubConv - Agent Instructions

## Project Overview

Subscription converter for Clash/mihomo proxy configs. Takes proxy subscription URLs (Clash YAML or V2Ray base64) and generates a complete mihomo-compatible config with proxy-providers, rule-providers, and proxy groups. Licensed under MPL-2.0.

## Architecture

Two separate components that ship together:

- **Backend** (`api.py` + `modules/`): Python FastAPI app. Single entrypoint `api.py`, all logic in `modules/`.
  - `modules/config.py` — Loads `config.yaml` at startup via pydantic-settings-yaml. Exits on missing/invalid config.
  - `modules/config_template.py` — Two hardcoded templates (`template_default`, `template_zju`) used by `--generate-config` CLI flag.
  - `modules/parse.py` — Parses subscription content (Clash YAML or V2Ray base64) into proxy lists.
  - `modules/pack.py` — Assembles the final Clash config: proxy-groups, proxy-providers, rule-providers, rules.
  - `modules/convert/converter.py` — Converts V2Ray share links (vmess, vless, trojan, ss, ssr, hysteria, hysteria2, tuic, tg) to Clash proxy dicts.
  - `modules/convert/v.py` — Shared handler for vless/vmess share link parsing.
  - `modules/convert/util.py` — Base64 helpers, unique name dedup, random user-agent.

- **Frontend** (`mainpage/`): Vue 3 + Element Plus SPA. Built with Vite, output goes to `static/`. The `static/` directory is committed and served directly by the backend.

## Running Locally

```bash
# Install dependencies (requires uv — https://docs.astral.sh/uv/)
uv sync

# Backend (requires config.yaml — generate one first)
uv run python api.py -G default   # generates config.yaml (default template)
uv run python api.py -G zju       # generates config.yaml (ZJU template)
uv run python api.py              # starts on 0.0.0.0:8080, 4 uvicorn workers

# Custom host/port
uv run python api.py -H 127.0.0.1 -P 3000

# Frontend dev server (separate)
cd mainpage && yarn && yarn dev
```

- Default port is **8080** (changed from older versions).
- No `config.yaml` = immediate exit. Always generate or provide one first.
- `DISALLOW_ROBOTS=True` env var enables `/robots.txt` disallow.

## API Endpoints

| Route | Purpose |
|-------|---------|
| `GET /` | Serves `static/index.html` (Web UI) |
| `GET /sub` | Main conversion API. Params: `url`, `interval`, `short`, `npr`, `urlstandby` |
| `GET /provider` | Converts a single subscription URL to proxy-provider YAML |
| `GET /proxy` | Proxies rule-provider URLs (whitelisted to RULESET entries only) |
| `GET /robots.txt` | Conditional based on `DISALLOW_ROBOTS` env |

## Config File (`config.yaml`)

- Loaded at startup by `modules/config.py` using `pydantic-settings-yaml`.
- Three top-level keys: `HEAD` (Clash config header with DNS/etc.), `TEST_URL`, `RULESET` (list of `[group_name, url]` pairs), `CUSTOM_PROXY_GROUP` (list of proxy group definitions).
- `RULESET` entries starting with `[]` are inline rules (e.g., `[]GEOIP,CN`, `[]FINAL`).
- `CUSTOM_PROXY_GROUP` items have: `name`, `type` (select/url-test/fallback/load-balance), `rule` (bool — whether group appears in rule-based selection), `manual` (bool — uses standby subs), `prior` (DIRECT/PROXY/REJECT), `regex` (filter proxies by name pattern).

## Frontend Build

```bash
cd mainpage
yarn
yarn build        # outputs to mainpage/dist/
```

The CI workflow (`generate-mainpage.yml`) builds the frontend and **commits the output to `static/`** on main/dev. If you change `mainpage/` code, `static/` must also be updated (either manually or via CI).

- Node 18.15.0 (pinned in CI).
- Uses **yarn**, not npm.
- No lock files committed (all three lockfiles are gitignored).

## Docker

```bash
# Build uses Nuitka to compile Python → native binary
docker build -t subconv .

# Run
docker run -p 8080:8080 -v ./config.yaml:/app/config.yaml subconv
```

- Docker image: `wouisb/subconv` on DockerHub.
- Multi-platform build: linux/amd64 + linux/arm64.
- Binary is compiled with Nuitka (clang, onefile mode) during Docker build.
- Alpine-based builder: uv is bootstrapped via `pip3 install uv` (uv's musl wheel), then `uv sync --locked --group build` installs project deps + nuitka.

## Vercel Deployment

`vercel.json` routes `/sub`, `/provider`, `/proxy`, `/robots.txt` to `api.py` via `@vercel/python`, static assets via `@vercel/static`. Vercel's Python builder natively supports `pyproject.toml` + `uv.lock` — no `requirements.txt` needed.

## CI Workflows

- **`build.yml`** — Builds native binaries (Windows/macOS/Linux) using Nuitka. Triggered on pushes touching Python/static files.
- **`build-image-dev.yml`** — Builds and pushes `wouisb/subconv:dev` on push to main/dev.
- **`release.yml`** — On `v*` tags: builds binaries + Docker image (tagged with version + latest), creates GitHub Release with zip artifacts.
- **`generate-mainpage.yml`** — Builds frontend and commits to `static/` on main/dev push.
- **`test-mainpage.yml`** — Builds frontend (no commit) on PRs and non-main/dev branches.

## Contributing / Branch Conventions

From README: Create branch from main, PR to **dev**. Or merge main into dev first, make changes in dev, then PR to dev.
Dependabot targets the **dev** branch.

## Key Gotchas

- `config.yaml` is required at runtime but not version-controlled meaningfully (it's deployment-specific). Use `--generate-config` to create one.
- `static/` is committed — frontend changes require rebuilding and committing the output.
- `pack.py` mutates the first proxy-group's proxies list when filtering out groups with no matching proxies — this is intentional, not a bug.
- The `converter.py` uses bare `except:` in several places — this is by design to skip malformed proxy links gracefully, not a bug to fix.
- `DISALLOW_ROBOTS` env var is evaluated with Python `eval()` — only set to `"True"` or `"False"`.
- `docker-compose.yml` mounts `config.yml` (note: `.yml` not `.yaml`) — filename mismatch with actual `config.yaml`.
- Dependencies managed via `pyproject.toml` + `uv.lock` (uv). Nuitka is in the `build` dependency group. Use `uv sync --group build` to include it.
- The Dockerfile uses Alpine (must stay Alpine — Nuitka binary is libc-linked). uv is bootstrapped via `pip3 install uv` since `ghcr.io/astral-sh/uv` binary is glibc-linked.
