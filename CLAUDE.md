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

bin/rubocop                # lint (rubocop-rails-omakase config)
bin/brakeman                # static security scan
bin/rails test              # test suite (minitest; no fixtures/tests written yet)
bin/rails test test/models/asset_test.rb   # single test file
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
- **`Finding`** — the join between an `Asset` and a `Vulnerability` (unique on `[asset_id, vulnerability_id]`), holding the scan-instance data that *does* vary: due date, past-due flag, first/last found dates, grace period, discovery date. Each `Finding` also belongs to the `CsvImport` that most recently touched it.
- **`CsvImport`** — an audit record of each upload: uploading user, filename, row count, status (`pending`/`processing`/`completed`/`failed`), error message.

Re-uploading a CSV **upserts** rather than duplicates: `Asset`/`Vulnerability` are looked up by their Rapid7 UID and updated in place, and `Finding` is looked up by `[asset, vulnerability]` and updated in place. There is currently no reconciliation for findings that disappear from a new export (e.g. a remediated vuln no longer present in the CSV) — they remain in the DB pointing at the last `CsvImport` that saw them.

### Import pipeline

`app/services/rapid7_csv_importer.rb` (`Rapid7CsvImporter`) is the single entry point for turning an uploaded file into rows. It:
1. Creates a `CsvImport` record up front (status `processing`).
2. Streams the file with `CSV.foreach(..., headers: true)`, matching Rapid7's exact column names (see the header comment mapping in that file — column names are the contract, not positions).
3. Wraps the whole file in one DB transaction; if any row errors, the entire import rolls back and `CsvImport` is marked `failed` with collected error messages.
4. On success, marks `CsvImport` `completed` with the row count.

`CsvImportsController#create` is the only caller today (a synchronous multipart upload — no background job). If imports need to handle large files, that's the seam to move to Solid Queue (already installed).

### Routing note

`/assets` is reserved by Propshaft for compiled CSS/JS — do not route the `Asset` resource there. It's mounted at `/inventory` (`resources :assets, path: "inventory"` in `config/routes.rb`) while keeping the `asset`/`assets` route helper names and `AssetsController`/`Asset` model names for domain clarity.

### Authentication

Generated via `bin/rails generate authentication` (Rails 8 built-in, not Devise). `Authentication` concern in `ApplicationController` requires login on every action by default; use `allow_unauthenticated_access` in a controller to opt out. `Current.user` / `Current.session` (via `app/models/current.rb`) is how controllers/views access the logged-in user — there is no `current_user` helper.

The login field is `email_address` (not a real username field) but has no format validation, so the seeded default account (`db/seeds.rb`, run via `bin/rails db:seed`) logs in as `itadmin` / `itadmin`. Seeding is idempotent (`find_or_create_by!`) so it's safe to run on every deploy — it will never overwrite a password the admin has since changed.

There are two separate password-change paths, don't conflate them:
- `PasswordsController` (`/passwords`) — the *forgot password* flow: emails a signed reset token via `PasswordsMailer`. Requires working mail delivery to be useful.
- `PasswordSettingsController` (`/password_setting`) — a self-service *change password while logged in* page (current password + new password, no email involved). This is what the seeded `itadmin` account is expected to use, since its "email" isn't deliverable.

### Gemfile pins worth knowing about

- `json` is pinned to `2.13.2`. The `json` gem's newer major line (3.x, which Bundler resolves to by default) changed `JSON.parse`'s arity and breaks `ActiveSupport::Messages::Metadata` (used for signed cookies/sessions) on this Rails version — every authenticated request 500s otherwise. Don't let `bundle update` drift this off 2.x without retesting login.
- `csv` is an explicit gem dependency (Ruby 3.4 dropped it from default gems); needed for `Rapid7CsvImporter`.
