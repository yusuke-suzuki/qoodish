import { applyD1Migrations, type D1Migration, env } from 'cloudflare:test';

declare global {
  namespace Cloudflare {
    interface Env {
      TEST_MIGRATIONS: D1Migration[];
      MIGRATION_DB: D1Database;
    }
  }
}

await applyD1Migrations(env.DB, env.TEST_MIGRATIONS);
