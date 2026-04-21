# jwt-pq-web

Website and live verifier for the [jwt-pq](https://github.com/marcelopazzo/jwt-pq)
Ruby gem.

The app serves the landing page and documentation for the gem, plus a
live JWT debugger that verifies post-quantum tokens against the real
`jwt-pq` library server-side — no JavaScript reimplementation.

## Running locally

1. Install liboqs: `brew install liboqs`
2. `bundle install`
3. `bin/rails db:prepare`
4. `bin/dev`
5. http://localhost:3000

## Tests

```bash
bin/rails test           # Unit and controller tests
bin/rails test:system    # Debugger end-to-end (Selenium + headless Chrome)
bundle exec rubocop
bundle exec brakeman --no-pager
```

## Key endpoints

- `GET /` — landing page
- `GET /quickstart` `GET /algorithms` `GET /hybrid` `GET /security` `GET /debugger`
- `POST /verify` — accepts `{ token, pubkey }`, runs `jwt-pq` server-side,
  returns `{ valid, algorithm, header, payload }` or `{ valid: false, error }`
- `GET /samples/:id` — returns a freshly signed ML-DSA sample token and
  its public JWK (for the debugger "Load sample" buttons)
- `GET /.well-known/jwks.json` — stable public JWKS (ML-DSA-65) for
  integration testing
- `GET /up` — Rails health check

## JWKS rotation

Keys live on a persistent volume mounted at `/rails/storage` (see
`config/deploy.yml`). Rotation is manual:

```bash
bin/rails jwks:show      # Inspect current kid
bin/rails jwks:rotate    # Generate a fresh ML-DSA-65 key
```

## Deploy

Automatic on push to `main` via GitHub Actions, which builds a linux/arm64
image, pushes to GHCR, and runs Kamal against the configured host.
Required repository secrets:

- `RAILS_MASTER_KEY`
- `DEPLOY_SSH_KEY`
- `SERVER_IP`

Before the first deploy, update `config/deploy.yml` to replace
`<CAX11_IP>` with the actual server IP / DNS name.

## License

MIT
