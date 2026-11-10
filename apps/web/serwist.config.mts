import { randomUUID } from 'node:crypto';
import path from 'node:path';
import { LOCALES } from './src/utils/locales.ts';
import { offlinePath } from './src/utils/offline.ts';

export default function serwistConfig(root: string, assetsDirectory: string) {
  return {
    swSrc: path.join(root, 'src/worker/index.ts'),
    swDest: path.join(assetsDirectory, 'sw.js'),
    globDirectory: assetsDirectory,
    globPatterns: ['**/*'],
    globIgnores: [
      // Cloudflare's asset host consumes _headers instead of serving it, so a
      // precache entry for it never resolves and stalls the worker install.
      '_headers',
      'vinext-client-entry-manifest.json',
      '**/*.woff2',
      'sw.js',
      'sw.js.map'
    ],
    modifyURLPrefix: { '': '/' },
    dontCacheBustURLsMatching: /^\/_next\/static\//,
    additionalPrecacheEntries: LOCALES.map((locale) => ({
      url: offlinePath(locale),
      revision: randomUUID()
    })),
    esbuildOptions: {
      target: ['chrome111', 'edge111', 'firefox111', 'safari16.4']
    }
  };
}
