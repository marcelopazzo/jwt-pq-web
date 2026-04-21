# CLAUDE.md — jwt-pq-web

## What is this?

Rails 8 website and live verifier for the [jwt-pq](https://github.com/marcelopazzo/jwt-pq) gem. Two jobs:

1. **Landing / docs** — explain post-quantum JWT signatures and how to use the gem.
2. **Live verifier** — `POST /verify` takes a token + JWK and validates them using the actual `jwt-pq` gem running server-side. A known-good JWKS is published at `/.well-known/jwks.json` and sample tokens are generated on demand at `/samples/:alg`.

Signing is deliberately not exposed. Adopters should not paste real private keys into a public web form.

## Development commands

```bash
bin/setup                       # Install deps + prepare DB (first run)
bin/dev                         # Start dev server (Puma + Tailwind watcher)
bin/rails test                  # Run unit tests
bin/rails test:system           # Run system tests (headless Chrome)
bundle exec rubocop             # Lint (Rails Omakase)
bundle exec rubocop -a          # Auto-fix
bundle exec brakeman --no-pager # Security scan
bin/rails jwks:show             # Print the current public JWKS
bin/rails jwks:rotate           # Rotate the long-lived JWKS key pair
```

## Architecture

- `app/controllers/verify_controller.rb` — `POST /verify` endpoint, rate-limited
- `app/controllers/jwks_controller.rb` — serves `/.well-known/jwks.json`
- `app/controllers/samples_controller.rb` — `GET /samples/:id` returns `{ token, jwk }`
- `app/controllers/pages_controller.rb` — static landing / docs pages
- `app/controllers/concerns/size_limited.rb` — input byte caps for `/verify`
- `app/services/verifier.rb` — wraps `JWT.decode` and normalises errors to a struct
- `app/services/sample_token_factory.rb` — generates ephemeral ML-DSA keys + signs a demo token
- `app/services/jwks_key_store.rb` — long-lived ML-DSA-65 key pair persisted on the Kamal volume
- `app/javascript/controllers/debugger_controller.js` — Stimulus controller for the `/debugger` page
- `config/deploy.yml` — Kamal config;
- `.github/workflows/deploy.yml` — manual-trigger deploy with `run_setup` flag for first-time bootstrap

## Stack

- Rails 8 + SQLite + Propshaft + Importmap + Tailwind + Stimulus + Turbo
- Solid Queue / Solid Cache / Solid Cable (no Redis)
- Puma behind Thruster
- Kamal 2 for deploy
- `jwt-pq ~> 0.5` (the whole reason this app exists)
- `ed25519 ~> 1.4` (reserved for hybrid samples once the gem exposes a canonical hybrid JWK export)

## System dependency

liboqs must be installed. On macOS: `brew install liboqs`. The production Docker image builds liboqs from source pinned to the same version the gem uses.

## Deploy

- **Host**: Hetzner CAX11 ARM server (`46.225.176.175`); kamal-proxy terminates SSL and routes by `Host:` header.
- **Domain**: `jwt-pq.marcelopazzo.com`
- **Trigger**: manual only via GitHub Actions `workflow_dispatch`. Use the `run_setup` checkbox for the first-time bootstrap; subsequent deploys leave it unchecked.
- **Secrets (GitHub)**: `SSH_PRIVATE_KEY`, `RAILS_MASTER_KEY`. `GITHUB_TOKEN` is used for GHCR registry auth.
- **Invariants** — do not break:
  - Service name stays `jwt-pq-web`.
  - Volume stays `jwt_pq_web_storage`.
  - SSH user is `jwt-pq-deploy` — a **dedicated** account, member of the `docker` group with no sudo rights.
  - Host key is pinned in the workflow — update if the server is ever rekeyed.

## Rules

- **Never expose a signing endpoint.** Verify and sample generation only. Samples use ephemeral keys destroyed (`Key#destroy!`) after signing.
- **Cap inputs aggressively.** `/verify` rejects tokens > 16 KB and pubkeys > 8 KB. Rate limit is 10/min per IP. Do not raise these casually.
- **Always destroy private key material** after use — `ensure key&.destroy!` in any path that allocates a `JWT::PQ::Key` or `JWT::PQ::HybridKey`.
- **Never log user input** — `priv` is in `filter_parameters`; do not add other params that could carry credentials.
- **Never commit `config/master.key`.** It's gitignored. If it ever lands in the index, stop and fix before committing.
- **Do not add auth, analytics, or user-submitted persistence.** The site is read-only public by design.
- **Double-quoted strings** everywhere in Ruby.
- **Conventional commits** (`feat:`, `fix:`, `chore:`, `docs:`, `test:`, `ci:`). One commit per logical step.
- **No `Co-Authored-By`** trailer on any commit.
- **No emojis** in code, commits, or UI copy.
- **All code, commits, docs, UI copy in English.**
- **Run tests after every change** — `bin/rails test && bundle exec rubocop`.
- **Do not push without explicit request.** Commit locally; user reviews before push.

## When the gem changes

This site is downstream of `jwt-pq`. When the gem releases a version:

- Bump the `Gemfile` constraint and run `bundle update jwt-pq`.
- Run the full test suite — fixture tokens / JWKs may need regenerating via `bin/rails runner script/generate_fixtures.rb`.
- If the gem adds a canonical hybrid JWK export, enable hybrid samples in `SampleTokenFactory` and un-hide the hybrid buttons in the `/debugger` view.
- Update copy on `/quickstart`, `/algorithms`, `/hybrid`, `/security` if the public API or threat model changed.
