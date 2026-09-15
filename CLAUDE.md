# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A Rapid7 InsightVM vulnerability tracker. Security staff upload CSV exports from Rapid7 (one row per asset+vulnerability finding); the app parses them into a normalized dataset of Assets, Vulnerabilities, and Findings so the same host/vulnerability can be tracked across multiple imports over time.

Stack: Rails 8.1, PostgreSQL, Tailwind CSS (via `tailwindcss-rails`, no Node build step), Turbo/Stimulus, Rails 8's built-in `has_secure_password` authentication (no Devise).

## Commands

```bash
bin/setup                 # install deps, prepare db
bin/dev                    # run the app (Puma + Tailwind watcher via Procfile.dev)
bin/rails db:prepare       # create/migrate dev+test db
bin/rails db:reset         # drop/recreate/migrate (destructive)

bin/rubocop                 # lint (rubocop-rails-omakase config)
bin/brakeman                # static security scan
bundle exec rspec           # test suite
bundle exec rspec spec/services/rapid7_csv_importer_spec.rb   # single file
bundle exec rspec spec/models/finding_spec.rb:12               # single example, by line
bin/rails zeitwerk:check    # verify autoloading resolves cleanly

bin/rails console
bin/rails runner 'SomeService.new(...).call'   # good for exercising importer logic ad hoc
```

There is a local Postgres via Homebrew (`postgresql@16`); start it with `brew services start postgresql@16` if `db:prepare` can't connect.

## Architecture

### Data model

Rapid7's CSV export is one row per (asset, vulnerability) pairing, repeated across scans. The importer normalizes this into three tables rather than storing raw rows:

- **`Asset`** — one row per physical/virtual host, keyed on `asset_uid` (Rapid7's `Asset Unique Identifier`, stable across scans). Holds host-level fields: hostname, IP, OS fields, risk score, malware/PCI flags.
- **`Vulnerability`** — the vulnerability catalog, keyed on `vulnerability_uid` (Rapid7's `Vulnerability Unique Identifier`, e.g. `google-chrome-cve-2026-2441`). Holds CVE/CVSS metadata that doesn't vary per-asset: title, severity, CVSS vector components, exploit info.
- **`Finding`** — the join between an `Asset` and a `Vulnerability` (unique on `[asset_id, vulnerability_id]`), holding the scan-instance data that *does* vary: due date, past-due flag, first/last found dates, grace period, discovery date, and a `status` (`open`/`closed`, see below). Each `Finding` also belongs to the `CsvImport` that most recently touched it.
- **`CsvImport`** — an audit record of each upload: uploading user, filename, row count, status (`pending`/`processing`/`completed`/`failed`), error message.

Re-uploading a CSV **upserts** rather than duplicates: `Asset`/`Vulnerability` are looked up by their Rapid7 UID and updated in place, and `Finding` is looked up by `[asset, vulnerability]` and updated in place.

### Import pipeline & open/close reconciliation

`app/services/rapid7_csv_importer.rb` (`Rapid7CsvImporter`) is the single entry point for turning an uploaded file into rows. Each Rapid7 export is a **full current snapshot** of what's vulnerable, so every import reconciles `Finding.status` against what's in the file, not just upserts:
1. Creates a `CsvImport` record up front (status `processing`).
2. Streams the file with `CSV.foreach(..., headers: true)`, matching Rapid7's exact column names (see the header comment mapping in that file — column names are the contract, not positions). Every `[asset, vulnerability]` pairing seen is upserted with `status: "open"` (reopening it with `closed_at: nil` if it had previously been closed) and its `id` is collected into `seen_finding_ids`.
3. After the file is fully read (and only if no row errored), any `Finding` that's still `status: "open"` but *wasn't* in `seen_finding_ids` is bulk-closed (`status: "closed"`, `closed_at: Time.current`) — it dropped out of Rapid7's report, meaning it's been remediated.
4. The whole thing (steps 2–3) runs in one DB transaction; if any row errored, everything rolls back and `CsvImport` is marked `failed` with collected error messages. Otherwise `CsvImport` is marked `completed`.

`CsvImportsController#create` is the only caller today (a synchronous multipart upload — no background job). If imports need to handle large files, that's the seam to move to Solid Queue (already installed).

### Sorting

`app/controllers/concerns/sortable.rb` (`Sortable`) is a shared concern for click-to-sort table headers, included in `FindingsController`, `AssetsController`, and `VulnerabilitiesController`. Each including controller defines a `SORTABLE_COLUMNS` hash (public sort key → whitelisted SQL column/expression), plus `DEFAULT_SORT_COLUMN`/`DEFAULT_SORT_DIRECTION`. The `sort`/`direction` query params drive it; `ApplicationHelper#sortable_header(title, column)` renders the linked header (toggling direction, showing an arrow, and preserving other filter query params via `request.query_parameters`). `VulnerabilitiesController` sorts by `findings_count` — a `COUNT(findings.id)` computed via `left_joins(:findings).select(...).group("vulnerabilities.id")`, safe in Postgres because grouping by the primary key makes the rest of `vulnerabilities.*` functionally dependent.

`config/brakeman.ignore` has one documented false-positive suppression for `Sortable#sort_order`'s `Arel.sql` interpolation — the interpolated values only ever come from the whitelisted `SORTABLE_COLUMNS` constant and a strict `asc`/`desc` ternary, never raw params.

### Routing note

`/assets` is reserved by Propshaft for compiled CSS/JS — do not route the `Asset` resource there. It's mounted at `/inventory` (`resources :assets, path: "inventory"` in `config/routes.rb`) while keeping the `asset`/`assets` route helper names and `AssetsController`/`Asset` model names for domain clarity.

### Authentication

Generated via `bin/rails generate authentication` (Rails 8 built-in, not Devise). `Authentication` concern in `ApplicationController` requires login on every action by default; use `allow_unauthenticated_access` in a controller to opt out. `Current.user` / `Current.session` (via `app/models/current.rb`) is how controllers/views access the logged-in user — there is no `current_user` helper.

The login field is `email_address` (not a real username field) but has no format validation, so the seeded default account (`db/seeds.rb`, run via `bin/rails db:seed`) logs in as `itadmin@email.com` / `itadmin`. Seeding is idempotent (`find_or_create_by!`) so it's safe to run on every deploy — it will never overwrite a password the admin has since changed.

There are two separate password-change paths, don't conflate them:
- `PasswordsController` (`/passwords`) — the *forgot password* flow: emails a signed reset token via `PasswordsMailer`. Requires working mail delivery to be useful.
- `PasswordSettingsController` (`/password_setting`) — a self-service *change password while logged in* page (current password + new password, no email involved). This is what the seeded `itadmin` account is expected to use, since its "email" isn't deliverable.

### Testing

RSpec (not Minitest — `config/application.rb` sets `config.generators.test_framework :rspec`, and `require "rails/test_unit/railtie"` is commented out in `config/application.rb`, so `rails generate` produces spec files). FactoryBot factories live in `spec/factories/`; `shoulda-matchers` is configured in `spec/rails_helper.rb` for terse validation/association specs.

Coverage is intentionally scoped to models (`spec/models/`) and the one piece of real business logic, the importer (`spec/services/rapid7_csv_importer_spec.rb`, using fixture CSVs under `spec/fixtures/files/` to exercise the open → close → reopen reconciliation across sequential imports). No request/controller/system specs yet — add them the same way if that coverage becomes worth it.

### Error tracking (Rollbar)

`config/initializers/rollbar.rb` reads `ROLLBAR_ACCESS_TOKEN` (and optionally `ROLLBAR_ENVIRONMENT`, `GIT_SHA`) from ENV — see `.env.example`. `dotenv` is in the Gemfile for `:development, :test` so a local `.env` loads automatically; no token is checked into the repo. `config.enabled` is explicitly forced `false` in `test` even if a token happens to be loaded, so running the spec suite never sends real errors to the dashboard.

`ApplicationController#rollbar_person` (private) points Rollbar's `person_method` at `Current.user` so reported errors show which user hit them — this app uses `Current.user`, not a `current_user` method, so that indirection is required. `ActionController::RoutingError` is downgraded to `"ignore"` via `exception_level_filters` (404s from bots/scanners shouldn't page anyone).

`GET /rollbar/test` (routed only when `Rails.env.development?`, see `config/routes.rb`) deliberately raises in `RollbarController#test` — hit it locally to confirm delivery end-to-end, then check the Rollbar dashboard (the response is a normal Rails 500 error page; that's expected).

### Logging (Lograge)

`config/initializers/lograge.rb` replaces Rails' multi-line per-request log output with one structured JSON line per request (`Lograge::Formatters::Json`) — but **only in production** (`config.lograge.enabled = Rails.env.production?`); development keeps Rails' normal verbose/human-readable logging, which is more useful when working locally.

The JSON line includes `request_id` and `remote_ip` (pulled from `event.payload[:headers]`, the standard Lograge idiom — not literal request headers, `ActionDispatch::Http::Headers` also exposes Rack env keys like `action_dispatch.request_id`) plus `user_id`, added via `ApplicationController#append_info_to_payload` reading `Current.user&.id`. `params` are included but `password`/`password_confirmation`/`current_password`/`authenticity_token`/`controller`/`action` are stripped — on top of that, Rails' own `config.filter_parameters` (in `config/initializers/filter_parameter_logging.rb`) separately masks anything matching `:email`, `:passw`, etc. wherever params get logged, lograge included.

If you need to see the JSON format without a full production boot, temporarily force it on, e.g. `Rails.application.config.lograge.enabled = true` in a `bin/rails runner` script run *before* anything logs (Lograge wires itself to the log subscribers at boot, so toggling it after `Rails.application.initialize!` has already run has no effect) — don't leave a bypass like this checked in.

### Gemfile pins worth knowing about

- `json` is pinned to `2.13.2`. The `json` gem's newer major line (3.x, which Bundler resolves to by default) changed `JSON.parse`'s arity and breaks `ActiveSupport::Messages::Metadata` (used for signed cookies/sessions) on this Rails version — every authenticated request 500s otherwise. Don't let `bundle update` drift this off 2.x without retesting login.
- `csv` is an explicit gem dependency (Ruby 3.4 dropped it from default gems); needed for `Rapid7CsvImporter`.
