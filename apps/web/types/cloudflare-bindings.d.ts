interface RateLimit {
  limit(options: { key: string }): Promise<{ success: boolean }>;
}

interface AnalyticsEngineDataset {
  writeDataPoint(event: {
    indexes?: string[];
    blobs?: string[];
    doubles?: number[];
  }): void;
}

interface KVNamespace<Key extends string = string> {
  get(key: Key, type: 'json'): Promise<unknown>;
}

type WebWorkerConfig = import('cf/config').UnwrapConfig<
  import('cf/config').UnwrapConfig<
    typeof import('../cloudflare.config.ts').default
  >['worker']
>;

declare module 'cloudflare:workers' {
  export const env: import('cf/config').InferEnv<WebWorkerConfig>;
}
