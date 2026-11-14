import type { CursorPage, Pin } from '../../types/index.ts';
import {
  apiFetch,
  apiFetchList,
  apiFetchPage,
  assertApiAvailable
} from './api.ts';
import { CONTENT_TAG, PINS_TAG, pinTag } from './cacheTags.ts';
import { cachePublic } from './publicCache.ts';

async function fetchPin(
  pinId: string,
  lang: string,
  guest: boolean
): Promise<Pin | null> {
  const path = `/pins/${pinId}`;
  const { data, status } = await apiFetch<Pin>(path, { lang, guest });
  assertApiAvailable(status, path);
  return data;
}

async function getPublicPin(pinId: string, lang: string): Promise<Pin | null> {
  'use cache';
  await cachePublic(300, [pinTag(pinId), CONTENT_TAG]);
  return fetchPin(pinId, lang, true);
}

export function getPin(
  pinId: string,
  lang: string,
  token?: string
): Promise<Pin | null> {
  return token ? fetchPin(pinId, lang, false) : getPublicPin(pinId, lang);
}

export async function getPopularPins(lang: string): Promise<Pin[]> {
  'use cache';
  await cachePublic(900, [PINS_TAG]);
  return apiFetchList<Pin>('/pins?popular=true', { lang, guest: true });
}

export async function getRecentPins(lang: string): Promise<Pin[]> {
  'use cache';
  await cachePublic(900, [PINS_TAG]);
  return apiFetchList<Pin>('/pins?recent=true', { lang, guest: true });
}

export async function getPinFeed(
  lang: string,
  cursor?: string
): Promise<CursorPage<Pin>> {
  'use cache';
  await cachePublic(cursor ? 300 : 900, [PINS_TAG]);
  return apiFetchPage<Pin>('/v2/pins', { lang, guest: true, cursor });
}

export function getTimelinePins(cursor?: string): Promise<CursorPage<Pin>> {
  return apiFetchPage<Pin>('/v2/pins', {
    cursor
  });
}
