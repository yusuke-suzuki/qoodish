import { convertV4MiniflareOptions, Miniflare } from 'miniflare';
import { DEVELOPMENT } from '../../environments.ts';
import { seedWorld } from './world.ts';

const miniflare = new Miniflare(
  convertV4MiniflareOptions({
    resourcePersistencePath: '.cloudflare/state/v3',
    workers: [
      {
        name: 'seed',
        modules: true,
        script: 'export default { fetch() { return new Response(null); } }',
        d1Databases: { DB: DEVELOPMENT.databaseId }
      }
    ]
  })
);

try {
  await seedWorld(await miniflare.getD1Database('DB'));
} finally {
  await miniflare.dispose();
}
