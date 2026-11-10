import { readFile } from 'node:fs/promises';
import path from 'node:path';
import { cloudflare } from '@cloudflare/vite-plugin';
import { runBuildCommand } from '@serwist/cli';
import { responseStoreAdapter } from '@vinext/cloudflare/cache/response-store-adapter';
import vinext from 'vinext';
import { defineConfig, type Plugin } from 'vite';
import serwistConfig from './serwist.config.mts';

function serviceWorker(): Plugin {
  return {
    name: 'qoodish:service-worker',
    apply: 'build',
    buildApp: {
      order: 'post',
      async handler(builder) {
        const { root, build } = builder.environments.client.config;
        const config = serwistConfig(root, path.resolve(root, build.outDir));

        await runBuildCommand({ config, watch: false });

        const source = await readFile(config.swDest, 'utf8');

        if (!source.includes('/_next/static/')) {
          throw new Error(
            `${config.swDest} precaches none of the client chunks in ${config.globDirectory}`
          );
        }
      }
    }
  };
}

export default defineConfig({
  plugins: [
    vinext({
      cache: responseStoreAdapter({ mode: 'self-contained' }),
      react: { compiler: true }
    }),
    cloudflare({
      viteEnvironment: {
        name: 'rsc',
        childEnvironments: ['ssr']
      }
    }),
    serviceWorker()
  ]
});
