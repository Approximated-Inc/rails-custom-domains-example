# Rails 8.1 refresh implementation plan

1. Pin Rails 8.1.3.1 and Ruby 4.0.6, resolve the lockfile in the official Ruby container, and preserve the original repository revision in the delivery notes.
2. Add failing model, lifecycle, HTTP-adapter, controller authorization/CSRF, and host-routing tests for two SQLite tenants.
3. Replace model callbacks with explicit tenant-scoped lifecycle services using confirmed provider IDs, fail-closed ambiguous states, nullable DNS/TLS readiness, and asynchronous deletion.
4. Add a local-only fixture login, direct-Host public routing, seeded tenant publishing pages, management views, environment/runtime documentation, and app-specific agent instructions.
5. Run the test suite, eager-load check, database seed, and four-host HTTP smoke in Ruby 4.0.6; then rewrite the guide and produce exact delivery metadata.
