# Claude Code Context for Qoodish

This document provides essential context for Claude Code to understand the Qoodish project. Please use this information to generate code that is consistent with the existing architecture, conventions, and dependencies.

## 1. Project Overview

- **Name:** Qoodish
- **Description:** A Ruby on Rails API for sharing and discovering information about places through maps. This is the backend for the Qoodish-Web frontend.
- **Repository (Backend):** `github.com/yusuke-suzuki/qoodish`
- **Repository (Frontend):** `github.com/yusuke-suzuki/qoodish-web`

## 2. Technology Stack

- **Framework:** Ruby on Rails
- **Language:** Ruby
- **Database:** MySQL
- **API Style:** RESTful JSON API
- **Authentication:** Google Sign-In via Firebase.
- **Package Manager:** Bundler

## 3. Architectural Patterns & Conventions

- **Directory Structure:** Standard Rails MVC architecture.
    - `app/controllers`: Controllers handle HTTP requests and render JSON responses.
    - `app/models`: Defines business logic. This includes ActiveRecord models for database interaction and plain Ruby objects (POROs) for other logic.
    - `app/views`: Primarily used for mailer templates.
    - `config/routes.rb`: Defines all API endpoints.
    - `app/jobs`: Active Job for background processing.
    - `db/migrate`: Database schema changes are managed through migration files.
    - `test`: Minitest is used for testing.
- **Deployment:** The application is deployed to Google Cloud Run. Deployment manifests are located in the `run/` directory for different environments (e.g., `dev`, `prod`).
- **Coding Style:** Follows standard Ruby and Rails conventions.
- **Data Handling:** Controllers receive parameters, interact with models, and serialize model data into JSON responses.

## 4. Code Generation & Modification Guidelines

- When adding new features, adhere to the Rails "Convention over Configuration" philosophy.
- Do not create service classes (Service Objects).
- Use Rails generators (`bin/rails g`) to create new models, controllers, migrations, etc., to ensure consistency.
- Business logic should primarily reside in models. For logic tied to a database table, use an ActiveRecord model. For logic not directly tied to a table, create a plain Ruby model (a class that does not inherit from `ApplicationRecord`).
- All new API endpoints must be defined in `config/routes.rb`.
- Ensure new features are covered by tests in the `test/` directory.
- Write all text committed to the repository — PR descriptions, issue bodies, code comments, commit messages — in English.

## 5. Commit Message Generation Rules

When generating commit messages, please follow these rules:

- Use conventional commit message format (e.g., `fix:`, `feat:`, `docs:`, `refactor:`).
- Write in English.
- Use imperative mood (e.g., "add feature" not "added feature").
- Use the present tense.
- **CRITICAL: The subject line MUST be 50 characters or less. Count characters carefully before committing. If the subject exceeds 50 characters, rephrase it to be more concise.**
- Separate the subject from the body with a blank line.
- Ensure each line in the body does not exceed 72 characters by inserting line breaks where necessary, including within sentences.
- Separate distinct paragraphs with a blank line.
- Use the body to explain what and why vs. how.
- Reference pull requests when applicable.

## 6. Release & Operations Guidelines

These rules cover database migrations, releases, and backward compatibility. Follow them to avoid breaking production or the `qoodish-web` frontend.

### Migrations and Data Migration

- Migration files in `db/migrate` must contain schema changes only. Do not write data-manipulation Ruby (model updates, backfills, record rewrites) inside a migration.
- Perform all data migration through scripts in `lib/tasks`, kept separate from schema migrations. These are plain Ruby scripts loaded by `bin/rails runner`, not Rake tasks, so they are invoked by path.

### Running Tasks in Production

- `db:migrate` runs as part of the release, through the `qoodish-runner` Cloud Run Job. Do not plan a release around applying migrations by hand.
- Data-migration scripts are executed on demand by invoking the same Job with `bin/rails runner lib/tasks/<script>.rb`. The Job carries the released image, so a script is only available once the release carrying it is out.

### Release Flow

- Releases are driven by `release-please`. Merging the release PR into `master` tags a new version, which builds the image, deploys it to the `qoodish-runner` Job, runs `db:migrate` through that Job, and only then deploys the new application revision with traffic shifted to it.
- A migration therefore applies before any instance serves the code that reads it. It also applies while the previous version is still serving, so a migration must leave that version working: add and backfill in one release, and read the result in the same release or a later one, but never remove or rename what the running version still reads.
- A release cannot apply a migration before its own image exists. Nothing in a release procedure can run `db:migrate` earlier than the release itself.

### Dropping Columns

- Removing a column takes two separate releases. First, ship a PR that only adds the column to `ignored_columns`, and release it. Only after that release is live, ship a second PR with the column-drop migration.
- Never combine the `ignored_columns` addition and the column-drop migration in the same PR or the same release version.

### Backward Compatibility with qoodish-web

- Do not create a PR whose release would immediately break the behavior of the current `qoodish-web` version. Keep the API backward compatible, and plan a release sequence that includes the corresponding `qoodish-web` changes.
- When a large change has ordering constraints across releases (or across the backend and frontend), document the release procedure in the PR description.
