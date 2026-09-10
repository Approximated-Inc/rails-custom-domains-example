# Coding agent notes

## Commands

Use Ruby 4.0.6 and Bundler 4.0.16.

```sh
bundle install
bin/rails db:prepare db:seed
APPROXIMATED_MODE=mock bin/rails server -b 127.0.0.1 -p 3086
APPROXIMATED_MODE=mock bin/rails db:test:prepare
APPROXIMATED_MODE=mock bin/rails test
APPROXIMATED_MODE=mock bin/rails zeitwerk:check
APPROXIMATED_MODE=mock RAILS_ENV=production SECRET_KEY_BASE_DUMMY=1 bin/rails assets:precompile
APPROXIMATED_MODE=mock PORT=3086 scripts/smoke.sh
docker compose config
docker compose run --rm web bin/rails db:prepare db:seed
```

The smoke script expects a seeded development server on port 3086.
The Compose service must remain bound to `127.0.0.1:${PORT:-3086}:3086`.

## File map

- `app/models/{tenant,custom_domain}.rb`: tenant data, reservation validation, and the routable scope.
- `app/services/domain_name.rb`: normalization and control-host rejection.
- `app/services/approximated.rb`: fixed-origin HTTP transport, response validation, environment mode selection, and the process-local mock.
- `app/services/domain_lifecycle.rb`: create, refresh, and deletion state machine.
- `app/controllers/{sessions,custom_domains,public_pages}_controller.rb`: local login, tenant management, and public host routing.
- `config/routes.rb`: control-host/public-host separation.
- `db/seeds.rb`: the two explicit `.test` fixtures.
- `test/services/`: lifecycle and loopback HTTP contract regressions.

## Invariants

- Derive the tenant from the encrypted session; never accept a tenant ID from a domain mutation request.
- Normalize before reserving and keep hostnames globally unique.
- Keep the API key server-only and address confirmed records by stored provider ID.
- Missing or blank `APPROXIMATED_API_KEY` selects the local mock; a nonempty key selects the fixed cloud API. `APPROXIMATED_MODE=mock` is the only supported override and the dashboard must show when results are simulated.
- An ambiguous create retains an unconfirmed owner reservation. Never adopt or delete by hostname.
- Real domains route only when lifecycle is `active`, provider ID is present, and both `apx_hit` and `has_ssl` are strictly true. Only explicit `fixture` rows bypass readiness.
- Keep `is_resolving` as a reachability diagnostic; do not substitute it for `apx_hit`.
- Mark removal pending before DELETE. Retain the disabled reservation on failure and release it only after GET by the same provider ID returns 404.
- Conditional refresh and deletion writes must match tenant, local ID, hostname, provider ID, and lifecycle so a stale response cannot alter a replacement.
- Ignore client-supplied forwarding host headers. This demo uses the actual HTTP Host because the provider request sets `keep_host: true`.
- Rails CSRF protection remains enabled for browser mutations. The fixture login must stay unavailable outside development and test.
