import describeError from '../utils/describeError.ts';
import { type Dictionary, getDictionary } from '../utils/getDictionary.ts';

type MaintenanceLocale = 'en' | 'ja';

export type Maintenance = {
  message?: Partial<Record<MaintenanceLocale, string>>;
};

const KV_KEY = 'maintenance';
const CACHE_TTL_MS = 30_000;

type CacheEntry = {
  readAt: number;
  maintenance: Maintenance | null;
};

let cache: CacheEntry | undefined;

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === 'object' && value !== null && !Array.isArray(value);
}

function isOptionalString(value: unknown): value is string | undefined {
  return value === undefined || typeof value === 'string';
}

function parseMaintenance(value: unknown): Maintenance | null {
  if (!isRecord(value)) return null;

  const { message } = value;

  if (message === undefined) return {};

  if (
    !isRecord(message) ||
    !isOptionalString(message.en) ||
    !isOptionalString(message.ja)
  ) {
    return null;
  }

  return { message: { en: message.en, ja: message.ja } };
}

async function readMaintenanceFlag(): Promise<unknown> {
  const { env } = await import('./workerEnv.ts');
  const store = env.MAINTENANCE;
  return store ? store.get(KV_KEY, 'json') : null;
}

export async function getMaintenance(): Promise<Maintenance | null> {
  if (cache && Date.now() - cache.readAt < CACHE_TTL_MS) {
    return cache.maintenance;
  }

  try {
    const maintenance = parseMaintenance(await readMaintenanceFlag());
    cache = { readAt: Date.now(), maintenance };
    return maintenance;
  } catch (error) {
    console.error(`Maintenance flag unavailable: ${describeError(error)}`);
    return null;
  }
}

function toMaintenanceLocale(locale: string): MaintenanceLocale {
  return locale === 'ja' ? 'ja' : 'en';
}

export function maintenanceMessage(
  maintenance: Maintenance | null,
  locale: string,
  dictionary: Dictionary
): string | null {
  if (!maintenance) return null;

  return (
    maintenance.message?.[toMaintenanceLocale(locale)] ||
    dictionary['maintenance in progress']
  );
}

export function maintenanceWriteBlockedMessage(acceptLanguage: string): string {
  return getDictionary(acceptLanguage.split('-')[0])[
    'maintenance write blocked'
  ];
}
