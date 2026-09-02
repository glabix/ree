## [Unreleased]

## [1.3.12] - 2026-09-02

- `ree_audit`: `annotate_audit` fn — the entry point product code uses to attach
  facts to the current audited call. Declared `freeze false` so a host
  application can stub it in its own specs.

## [1.3.11] - 2026-09-02

- New `ree_audit` package: an opt-in trail of audited action calls (event,
  per-fiber context with `ReeAudit.annotate`, recursive params filter, sinks).
  Disabled by default via `AUDIT_ENABLED`.
- `ree_routes`: `Route#audited?` and the `audit true/false` route DSL. Internal
  routes are audited by default; public ones are not.
- `ree_routes`: `Route` got the missing `before` and `redirect` accessors —
  `RouteBuilder#before` and `#redirect` wrote to setters that did not exist.
- `ree_roda`: the `ree_routes` plugin accepts `audit:`. Without the option the
  plugin behaves exactly as before.

## [1.3.0] - 2025-05-14

- Forward compatibility fixes for ruby 3.4
- Update dependencies

## [0.1.0] - 2022-07-01

- Initial release
