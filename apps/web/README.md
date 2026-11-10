# qoodish-web

The Next.js app behind https://qoodish.com, built with [vinext](https://github.com/cloudflare/vinext) and deployed to Cloudflare Workers. It reaches the API Worker in [`apps/api`](../api/README.md). Run the commands below from `apps/web`.

## Environment variables

`.env.example` lists every variable the build reads. Copy it to `.env.local` and fill in the values. `.env` files are ignored by git, so never commit one.

`APP_ENV`, `API_ENDPOINT` and the bindings of each environment are declared in `cloudflare.config.ts`.

## Develop

```bash
pnpm dev
```

The dev server runs the app in the Workers runtime on http://localhost:5000 with the bindings of the dev environment, simulated locally.

To run the worker as it is deployed, build it for the dev environment and serve it on http://localhost:8787:

```bash
pnpm cf:build:dev
pnpm preview
```

## Tests

```bash
pnpm test        # unit tests (node:test)
pnpm e2e         # Playwright smoke tests
```

`pnpm e2e` serves the worker with `pnpm preview` unless `E2E_BASE_URL` points at a running app, so build it with `pnpm cf:build:dev` first. The tests find content through the API at `E2E_API_URL`, which defaults to the dev API. Pull requests run the smoke tests in CI, and every push to `master` runs them against production once it serves that commit.

## Deploy

Workers Builds deploys the worker from `master`, so a merge is the release, and deploys every other branch of the dev worker as a Worker Preview. It runs the `cf:*` scripts, so they keep their names. To deploy the checked-out revision from a machine that is logged in to Cloudflare:

```bash
pnpm cf:build && pnpm cf:deploy            # qoodish.com
pnpm cf:build:dev && pnpm cf:deploy:dev    # the dev environment
```

`vite build` writes the service worker into the build output once the bundle is done, and fails if the worker would precache none of the bundle's chunks. `pnpm cf:preview` builds and deploys the branch as a Worker Preview of the dev worker.

## Caching

Rendered responses and cached fetches live in the [Workers Response Store](https://vinext.dev/docs/guides/caching): the bodies in the R2 bucket `<worker name>-response-store`, their metadata and tags in a Durable Object of the worker itself. `revalidateTag` reaches every isolate through it.

## Maintenance mode

The `MAINTENANCE` KV namespace holds one key, `maintenance`. While it is set, every page shows a maintenance notice to signed-in users and guests alike, and every write the app would send to the API answers `503` without reaching it: Server Actions, the image upload allocation and the account registration that follows a sign-in. Reads keep working, and a visitor who already holds a session stays signed in. The flag is read per environment, so the dev worker and the production worker are toggled independently through the ID of their namespace, which `cloudflare.config.ts` lists as `maintenanceNamespaceId`.

Turn it on by storing an empty object:

```bash
pnpm exec cf kv keys put maintenance --namespace-id <namespace ID> --body '{}'
```

The notice says that posting and editing are unavailable, in the viewer's language. To replace it, add a `message` with the text for either or both languages:

```bash
pnpm exec cf kv keys put maintenance --namespace-id <namespace ID> --body '{"message":{"en":"Qoodish is moving to a new database until 15:00 JST.","ja":"15:00 までデータベースを移行しています。"}}'
```

Turn it off by deleting the key:

```bash
pnpm exec cf kv keys delete maintenance --namespace-id <namespace ID>
```

Each isolate rereads the flag every 30 seconds, so a change takes up to that long to reach every visitor. A value the app cannot parse is treated as no maintenance.
