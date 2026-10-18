# Qoodish

https://qoodish.com

This repository is a pnpm workspace of four Cloudflare Workers under `apps/` and one shared package under `packages/`:

- [`api`](apps/api/README.md): the API, a Hono app that keeps its records in D1 through Drizzle ORM
- [`web`](apps/web/README.md): the web app, a Next.js app deployed through [OpenNext](https://opennext.js.org/cloudflare)
- [`admin`](apps/admin/README.md): the moderation dashboard
- [`synthetics`](apps/synthetics/README.md): scheduled checks against production
- [`api-contract`](packages/api-contract): the JSON shapes of the API's responses, shared by the API and the apps that call it

Each app's README covers how to run, test and deploy it.

## Installation

```bash
pnpm install
```

## Checks

From the repository root:

```bash
pnpm lint        # Biome, across the repository
pnpm typecheck   # TypeScript, in every workspace
pnpm test        # unit tests, in the workspaces that have them
```

Pull requests run all of these in CI, along with the web app's smoke tests.

## Deployment

Cloudflare Workers Builds deploys every worker from `master`, so a merge is the release. The workers deploy at the same time, in no guaranteed order, so a change in one worker that relies on a change in another being live is split into separate pull requests, and the one that relies on it is merged only after the other is deployed.
