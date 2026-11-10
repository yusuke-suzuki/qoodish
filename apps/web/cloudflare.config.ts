import { createWorkersResponseStoreSelfContainedConfig } from '@vinext/cloudflare/cache/config';
import { bindings, defineConfig, exports } from 'cf/config';

const ACCOUNT_ID = '9671c836ad132f87d892b12ccd1809e0';

type Environment = {
  appEnv: string;
  apiEndpoint: string;
  maintenanceNamespaceId: string;
  analyticsDataset: string;
  imageUploadBurstNamespace: string;
  imageUploadNamespace: string;
};

const PRODUCTION: Environment = {
  appEnv: 'production',
  apiEndpoint: 'https://api.qoodish.com',
  maintenanceNamespaceId: '6c78b3e0223e45889bce5d43c6a96844',
  analyticsDataset: 'prod_qoodish_web_events',
  imageUploadBurstNamespace: '1001',
  imageUploadNamespace: '1002'
};

const DEVELOPMENT: Environment = {
  appEnv: 'development',
  apiEndpoint: 'https://api-dev.qoodish.com',
  maintenanceNamespaceId: '8a56a701dfff4c26842908926149f651',
  analyticsDataset: 'dev_qoodish_web_events',
  imageUploadBurstNamespace: '2001',
  imageUploadNamespace: '2002'
};

const PREVIEW: Environment = {
  ...DEVELOPMENT,
  imageUploadBurstNamespace: '3001',
  imageUploadNamespace: '3002'
};

async function defineWebWorker(name: string, environment: Environment) {
  const responseStore = await createWorkersResponseStoreSelfContainedConfig({
    worker: name,
    bucket: `${name}-response-store`
  });

  return {
    ...responseStore,
    name,
    entrypoint: 'vinext/server/fetch-handler',
    compatibilityDate: '2026-11-10',
    compatibilityFlags: ['nodejs_compat', 'global_fetch_strictly_public'],
    observability: {
      enabled: true,
      traces: { enabled: true },
      logs: { enabled: true },
      issues: { enabled: true }
    },
    assets: {
      htmlHandling: 'none' as const,
      notFoundHandling: 'none' as const,
      runWorkerFirst: [
        '/*',
        '!/_next/static/*',
        '!/*/_next/static/*',
        '!/icons/*',
        '!/og/*',
        '!/screenshots/*',
        // vinext lists the public files while bundling, before sw.js exists.
        '!/sw.js'
      ]
    },
    env: {
      ...responseStore.env,
      ASSETS: bindings.assets(),
      APP_ENV: bindings.text(environment.appEnv),
      API_ENDPOINT: bindings.text(environment.apiEndpoint),
      MAINTENANCE: bindings.kv({ id: environment.maintenanceNamespaceId }),
      ANALYTICS_EVENTS: bindings.analyticsEngineDataset({
        name: environment.analyticsDataset
      }),
      // Cloudflare Images is paid for and shared, so one account allocating
      // uploads in a loop is held to a burst and a per-minute ceiling.
      IMAGE_UPLOAD_BURST_LIMIT: bindings.rateLimit({
        namespace: environment.imageUploadBurstNamespace,
        simple: { limit: 10, period: 10 }
      }),
      IMAGE_UPLOAD_LIMIT: bindings.rateLimit({
        namespace: environment.imageUploadNamespace,
        simple: { limit: 30, period: 60 }
      })
    },
    exports: {
      ...responseStore.exports,
      DOQueueHandler: exports.durableObject({ state: 'deleted' }),
      DOShardedTagCache: exports.durableObject({ state: 'deleted' })
    }
  };
}

async function selectWorker(mode: string | undefined, isPreview: boolean) {
  if (isPreview) {
    return defineWebWorker('dev-qoodish-web', PREVIEW);
  }

  if (mode === 'production') {
    return {
      ...(await defineWebWorker('prod-qoodish-web', PRODUCTION)),
      workersDev: false,
      previewUrls: false,
      domains: ['qoodish.com']
    };
  }

  return {
    ...(await defineWebWorker('dev-qoodish-web', DEVELOPMENT)),
    workersDev: false,
    previewUrls: true,
    domains: ['dev.qoodish.com']
  };
}

export default defineConfig(async ({ mode, isPreview }) => ({
  accountId: ACCOUNT_ID,
  worker: await selectWorker(mode, isPreview)
}));
