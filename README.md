# Rails Custom Domains Example

A two-tenant publishing demo for adding custom domains to a Rails 8.1 application with [Approximated](https://approximated.app). The refresh shown here targets Ruby 4.0.6 and Rails 8.1.3.1.

## Versions

- Current Rails 8.1 example: [`guide-rails8.1-r1`](https://github.com/Approximated-Inc/rails-custom-domains-example/tree/guide-rails8.1-r1)
- Legacy Rails 8.0 example: [`guide-legacy-2026-09`](https://github.com/Approximated-Inc/rails-custom-domains-example/tree/guide-legacy-2026-09)

## What the demo proves

- `atlas.test` and `juniper.test` resolve to separate SQLite tenants.
- The management surface runs only on `CONTROL_HOST` and derives the tenant from an encrypted Rails session.
- Domain input is normalized before a globally unique reservation is created.
- A blank API key uses a clearly labeled process-local mock. A nonempty key uses the fixed Approximated cloud API, and credentials remain server-side.
- Provider records are confirmed and later addressed by their stored provider ID.
- Public routing requires a confirmed active record with an Approximated traffic hit and TLS readiness. Explicit `.test` fixtures are the only bypass.
- Removal keeps the local mapping disabled until a provider GET by ID returns 404.

This is an integration example. The development login is deliberately disabled outside development and test. Production authentication belongs in the host application.

## Setup

Install Ruby 4.0.6 and Bundler 4.0.16, then run:

```sh
bundle install
cp .env.example .env
bin/rails db:prepare db:seed
bin/rails server -b 127.0.0.1 -p 3086
```

Leave `APPROXIMATED_API_KEY` blank for local work. The dashboard shows **Local demo mode**, and domains you add use an in-process mock without making an external request. Open the control app through `http://localhost:3086`, sign in with tenant slug `atlas` or `juniper` and the `DEMO_LOGIN_PASSWORD`, then exercise the publishing hosts:

```sh
curl --resolve atlas.test:3086:127.0.0.1 http://atlas.test:3086/
curl --resolve juniper.test:3086:127.0.0.1 http://juniper.test:3086/
```

To use the real integration, set only `APPROXIMATED_API_KEY` and `APP_ORIGIN_HOST`; a nonempty key selects `https://cloud.approximated.app`. Set `APPROXIMATED_MODE=mock` when you deliberately want the local mock even though a key is present. The mock is process-local, so restart it whenever you want a clean simulated provider state.

The production-like container path publishes only on loopback:

```sh
cp .env.example .env
docker compose build
docker compose run --rm web bin/rails db:prepare db:seed
docker compose up
```

`compose.yaml` binds `127.0.0.1:${PORT:-3086}` on the host to port 3086 in the container. Put a deliberate reverse proxy in front of it before exposing the service elsewhere.

## Verification

```sh
APPROXIMATED_MODE=mock bin/rails db:test:prepare
APPROXIMATED_MODE=mock bin/rails test
APPROXIMATED_MODE=mock bin/rails zeitwerk:check
APPROXIMATED_MODE=mock RAILS_ENV=production SECRET_KEY_BASE_DUMMY=1 bin/rails assets:precompile
APPROXIMATED_MODE=mock PORT=3086 scripts/smoke.sh
```

Start the server and seed the database before running the smoke script. See [AGENTS.md](AGENTS.md) for the file map and invariants that coding agents must preserve.

## Lifecycle and trust boundaries

The browser never chooses a tenant ID. `CustomDomainsController` scopes every lookup to `current_tenant`, which comes from the encrypted session. A normalized hostname has one reservation across all tenants.

An API timeout or ambiguous error leaves that reservation `unconfirmed`, without a provider ID. It is not routable and cannot be refreshed or removed automatically. A successful create stores the returned provider ID only after the response hostname matches the reservation. Refresh and delete then use `/api/vhosts/{id}`. A refresh accepts a response only when both its ID and hostname still match the reservation, and its conditional write also matches the original tenant, local ID, hostname, provider ID, and lifecycle so a delayed response cannot alter a replacement.

`is_resolving` says an HTTP response was observed. `apx_hit` separately says the request reached Approximated, and `has_ssl` reports TLS readiness. Real public routing requires the latter two values to be strictly true. The mock returns simulated ready values so you can exercise the complete local flow, and its dashboard banner keeps those results visibly separate from live checks.

## Main files

- `app/models/custom_domain.rb` — persistence, validation, and fail-closed routing scope.
- `app/services/domain_name.rb` — hostname normalization and rejection rules.
- `app/services/approximated.rb` — fixed-origin HTTP adapter, environment factory, and process-local mock.
- `app/services/domain_lifecycle.rb` — reservation, confirmation, refresh, and removal state transitions.
- `app/controllers/custom_domains_controller.rb` — tenant-scoped management actions.
- `app/controllers/public_pages_controller.rb` — host lookup and tenant publishing response.
- `config/routes.rb` — control-host and public-host route split.
- `compose.yaml` — production-like container with loopback-only host publishing.
- `test/services/approximated_http_test.rb` — loopback HTTP contract tests.
- `test/services/domain_lifecycle_test.rb` — identity and deletion-race regressions.

## JSON compatibility pin

Rails 8.1.3.1 currently decodes encrypted cookie sessions through the JSON 2.x positional parse API. `json` 3.0.2 changed that call shape and caused session decoding to raise `ArgumentError`; the suite passed after pinning the current JSON 2.x release, 2.21.2. Keep the pin until Rails or the JSON integration removes that incompatibility.
