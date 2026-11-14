import type {
  AppMap,
  Chapter,
  Coauthor,
  Pin,
  PinProperty
} from '../../types/index.ts';
import { apiFetch, apiFetchList, assertApiAvailable } from './api.ts';
import { CHAPTERS_TAG, CONTENT_TAG, MAPS_TAG, mapTag } from './cacheTags.ts';
import { cachePublic } from './publicCache.ts';

async function fetchMap(
  mapId: string,
  lang: string,
  guest: boolean
): Promise<AppMap | null> {
  const { data, status } = await apiFetch<AppMap>(`/maps/${mapId}`, {
    lang,
    guest
  });
  assertApiAvailable(status, `/maps/${mapId}`);
  return data;
}

async function getPublicMap(
  mapId: string,
  lang: string
): Promise<AppMap | null> {
  'use cache';
  await cachePublic(300, [mapTag(mapId), CONTENT_TAG]);
  return fetchMap(mapId, lang, true);
}

export function getMap(
  mapId: string,
  lang: string,
  token?: string
): Promise<AppMap | null> {
  return token ? fetchMap(mapId, lang, false) : getPublicMap(mapId, lang);
}

export async function getFeaturedMap(lang: string): Promise<AppMap | null> {
  'use cache';
  await cachePublic(900, [MAPS_TAG]);
  // A 404 here means nothing is featured, which the discover page renders as an
  // empty slot — only an unreachable API should surface as an error.
  const { data, status } = await apiFetch<AppMap>('/maps/featured', {
    lang,
    guest: true
  });
  assertApiAvailable(status, '/maps/featured');
  return data;
}

type MapResource = 'pins' | 'coauthors' | 'chapters' | 'pin_properties';

function fetchMapResource<T>(
  mapId: string,
  resource: MapResource,
  lang: string,
  guest: boolean
): Promise<T[]> {
  return apiFetchList<T>(`/maps/${mapId}/${resource}`, { lang, guest });
}

async function getPublicMapResource<T>(
  mapId: string,
  resource: MapResource,
  lang: string
): Promise<T[]> {
  'use cache';
  const tags =
    resource === 'chapters'
      ? [mapTag(mapId), CHAPTERS_TAG, CONTENT_TAG]
      : [mapTag(mapId), CONTENT_TAG];
  await cachePublic(300, tags);
  return fetchMapResource<T>(mapId, resource, lang, true);
}

function getMapResource<T>(
  mapId: string,
  resource: MapResource,
  lang: string,
  token?: string
): Promise<T[]> {
  return token
    ? fetchMapResource<T>(mapId, resource, lang, false)
    : getPublicMapResource<T>(mapId, resource, lang);
}

export function getMapPins(
  mapId: string,
  lang: string,
  token?: string
): Promise<Pin[]> {
  return getMapResource<Pin>(mapId, 'pins', lang, token);
}

export function getMapCoauthors(
  mapId: string,
  lang: string,
  token?: string
): Promise<Coauthor[]> {
  return getMapResource<Coauthor>(mapId, 'coauthors', lang, token);
}

export function getMapChapters(
  mapId: string,
  lang: string,
  token?: string
): Promise<Chapter[]> {
  return getMapResource<Chapter>(mapId, 'chapters', lang, token);
}

export function getMapPinProperties(
  mapId: string,
  lang: string,
  token?: string
): Promise<PinProperty[]> {
  return getMapResource<PinProperty>(mapId, 'pin_properties', lang, token);
}

export async function getActiveMaps(lang: string): Promise<AppMap[]> {
  'use cache';
  await cachePublic(900, [MAPS_TAG]);
  return apiFetchList<AppMap>('/maps?active=true', { lang, guest: true });
}

export async function getPopularMaps(lang: string): Promise<AppMap[]> {
  'use cache';
  await cachePublic(900, [MAPS_TAG]);
  return apiFetchList<AppMap>('/maps?popular=true', { lang, guest: true });
}

export async function getRecentMaps(lang: string): Promise<AppMap[]> {
  'use cache';
  await cachePublic(900, [MAPS_TAG]);
  return apiFetchList<AppMap>('/maps?recent=true', { lang, guest: true });
}

function fetchRecommendMaps(lang: string, guest: boolean): Promise<AppMap[]> {
  return apiFetchList<AppMap>('/maps?recommend=true', { lang, guest });
}

async function getPublicRecommendMaps(lang: string): Promise<AppMap[]> {
  'use cache';
  await cachePublic(300, [MAPS_TAG]);
  return fetchRecommendMaps(lang, true);
}

export function getRecommendMaps(
  lang: string,
  token?: string
): Promise<AppMap[]> {
  return token ? fetchRecommendMaps(lang, false) : getPublicRecommendMaps(lang);
}
