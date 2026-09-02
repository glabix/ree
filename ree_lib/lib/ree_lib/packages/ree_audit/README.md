# ree_audit

An opt-in trail of audited action calls.

The package answers one question: **who called what, when, and how did it end.**
It says nothing about what happened inside the action, and nothing about files
downloaded straight from object storage — see *Boundaries* below.

## Why it exists

An application that serves an internal (admin) API eventually has to answer a
customer, an auditor or a regulator: *did your staff look at my data, and when?*
Answering that from request logs does not work — they rotate, they contain
secrets, and they cannot be handed to a customer. This package produces a
structured record per audited call that an application can persist wherever it
wants and export as-is.

## Off by default

`AUDIT_ENABLED` defaults to `false`, and an application that never passes
`audit:` to the `ree_routes` plugin behaves exactly as it did before the gem was
bumped. Both properties are covered by specs: a shared framework must not start
recording anything because someone upgraded a dependency.

When audit is disabled, `Audit#around` costs a single `if`.

## Wiring it up

```ruby
class MyApp < ReeRoda::App
  link :audit, from: :ree_audit, import: -> { Audit }
  link :my_sink, from: :my_package, import: -> { MySink }

  AUDIT = Audit.new          # singleton bean
  AUDIT.sink = MySink.new    # the one and only mutation, at boot

  plugin :ree_routes, audit: AUDIT
end
```

A sink implements one method:

```ruby
class MySink < ReeAudit::Sink
  def write(event)
    # persist it
  end
end
```

The package ships `NullSink` (default) and `LoggerSink` (dev). A sink that
raises never fails the request: `Audit#write_safely` catches it and reports
through `ree_logger`.

## What gets audited

`Route#audited?` returns `internal?` unless the route says otherwise:

```ruby
get "api/v1/admin/users" do
  visibility :internal    # audited by default
end

get "api/v1/admin/health" do
  visibility :internal
  audit false             # deliberately silent
end

get "api/v1/exports" do
  audit true              # public route reaching into someone else's data
end
```

Tying the default to `visibility` rather than to a hand-kept list is deliberate:
`visibility` is mandatory on admin paths (the routes DSL fails at boot without
it), so the audited set cannot drift away from the set of routes that actually
touch client data.

## The event

| field | meaning |
|---|---|
| `action_name`, `package_name` | which action ran |
| `summary`, `sections` | route metadata, useful for grouping and for classifying sensitivity |
| `request_method`, `path`, `request_path` | `path` is the DSL template (stable), `request_path` is the actual path (shows the object) |
| `params` | what the action received, after filtering |
| `accessor` | the authenticated object — the application decides how to read it |
| `status` | `:ok`, `:denied`, `:error` |
| `error_type`, `error_message` | present when the call failed; message truncated to 512 chars |
| `started_at`, `duration_ms` | timing (monotonic clock) |
| `annotations` | whatever the application attached during the call |

`:denied` means the action raised a `ReeErrors::Error` whose type is
`:permission`. A refusal to show client data is as much an audit fact as
showing it.

There is **no HTTP status** on the event, and that is not an oversight: the
wrapper sits around the action call, while Roda sets the status afterwards (and,
on an exception, in the application's `error` block). Observing it here is
impossible, and deriving it from the error type would put a guess into an audit
trail. `status` carries the fact instead.

## Annotations

Product code attaches what only it knows:

```ruby
class MyPackage::AdminUploadQuery
  action :admin_upload_query do
    link :annotate_audit, from: :ree_audit
  end

  def call(access, attrs)
    upload = find_upload(attrs)
    annotate_audit(organization_id: upload.organization_id,
                   subject: {type: :upload, id: upload.uuid})
    ...
  end
end
```

`annotate_audit` returns `nil` when audit is off or the code was reached from
outside an audited route, so it is always safe to call.

Use the `annotate_audit` fn rather than `ReeAudit.annotate` directly. A bare
constant works, but Ree only verifies a declared package dependency for
`link`/`import` — so removing `depends_on :ree_audit` as "unused" would compile
fine and blow up with `NameError` in production. With `link`, the same removal
fails loudly at load time.

## Params filtering

Two limits, applied before the event reaches the sink:

* keys containing any `filter_words` are replaced with `'FILTERED'` **at any
  depth** (the logger only inspects the top level);
* anything nested deeper than `AUDIT_MAX_PARAMS_DEPTH` becomes
  `'[TRUNCATED_DEPTH]'`, and a payload whose JSON exceeds
  `AUDIT_MAX_PARAMS_BYTES` is replaced with `{truncated: true, size: N}`.

This is a blacklist, and it is the framework's job: it protects any host
application from leaking a credential. An application that exports the trail to
its customers should apply its own **whitelist** on top — a blacklist silently
passes through a key someone adds six months from now.

## Nested calls

Events live on a per-fiber stack (`ReeAudit::Context`), so an audited action may
call another one without the inner call stealing the outer one's annotations.
The stack is unwound in `ensure`, including when the action raises — a leftover
event would attach one client's context to the next request served by the same
fiber.

## Configuration

| variable | default | meaning |
|---|---|---|
| `AUDIT_ENABLED` | `false` | master switch |
| `AUDIT_MAX_PARAMS_BYTES` | `4096` | size limit for the serialized params |
| `AUDIT_MAX_PARAMS_DEPTH` | `4` | nesting limit |
| `AUDIT_FILTER_WORDS` | see `Config::DEFAULT_FILTER_WORDS` | comma-separated |

## Boundaries

The package answers *who called what*. It does not see anything that bypasses
the application: direct database access, an object-storage console, or a file
fetched with a pre-signed URL that was handed out earlier. An application that
needs those answers has to record them where they happen.

## Specs

```
cd ree_lib/lib/ree_lib && bundle exec ree spec ree_audit
```
