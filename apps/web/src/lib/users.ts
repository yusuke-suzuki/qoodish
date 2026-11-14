import type {
  AppMap,
  BlockedAccount,
  CursorPage,
  Journal,
  MutedAccount,
  Notification,
  Pin,
  Profile,
  UserProfile
} from '../../types/index.ts';
import {
  apiFetch,
  apiFetchList,
  apiFetchPage,
  assertApiAvailable
} from './api.ts';
import { MAPS_TAG, userTag } from './cacheTags.ts';
import { cachePublic } from './publicCache.ts';

async function fetchProfile(
  userId: string,
  lang: string,
  guest: boolean
): Promise<UserProfile | null> {
  const { data, status } = await apiFetch<UserProfile>(`/users/${userId}`, {
    lang,
    guest
  });
  assertApiAvailable(status, `/users/${userId}`);
  return data;
}

async function getPublicProfile(
  userId: string,
  lang: string
): Promise<UserProfile | null> {
  'use cache';
  await cachePublic(300, [userTag(userId)]);
  return fetchProfile(userId, lang, true);
}

export function getProfile(
  userId: string,
  lang: string,
  token?: string
): Promise<UserProfile | null> {
  return token
    ? fetchProfile(userId, lang, false)
    : getPublicProfile(userId, lang);
}

export async function getMyProfile(
  lang: string,
  token?: string
): Promise<Profile | null> {
  if (!token) {
    return null;
  }

  const { data } = await apiFetch<Profile>('/me/profile', {
    lang
  });
  return data;
}

function fetchUserMaps(
  userId: string,
  lang: string,
  guest: boolean
): Promise<AppMap[]> {
  return apiFetchList<AppMap>(`/users/${userId}/maps`, { lang, guest });
}

async function getPublicUserMaps(
  userId: string,
  lang: string
): Promise<AppMap[]> {
  'use cache';
  await cachePublic(300, [userTag(userId), MAPS_TAG]);
  return fetchUserMaps(userId, lang, true);
}

export function getUserMaps(
  userId: string,
  lang: string,
  token?: string
): Promise<AppMap[]> {
  return token
    ? fetchUserMaps(userId, lang, false)
    : getPublicUserMaps(userId, lang);
}

export function getMyMaps(lang: string, token?: string): Promise<AppMap[]> {
  if (!token) {
    return Promise.resolve([]);
  }

  return apiFetchList<AppMap>('/me/maps', {
    lang
  });
}

export async function getUserJournal(
  userId: string,
  lang: string,
  token?: string
): Promise<Journal | null> {
  if (!token) {
    return null;
  }

  const path = `/users/${userId}/journal`;
  const { data, status } = await apiFetch<Journal>(path, {
    lang
  });
  assertApiAvailable(status, path);
  return data;
}

export async function getMyJournal(
  lang: string,
  token?: string
): Promise<Journal | null> {
  if (!token) {
    return null;
  }

  const { data, status } = await apiFetch<Journal>('/me/journal', {
    lang
  });
  assertApiAvailable(status, '/me/journal');
  return data;
}

export function getBookmarkedMaps(
  lang: string,
  token?: string
): Promise<AppMap[]> {
  if (!token) {
    return Promise.resolve([]);
  }

  return apiFetchList<AppMap>('/me/bookmarks/maps', {
    lang
  });
}

export function getBookmarkedJournals(
  lang: string,
  token?: string
): Promise<Journal[]> {
  if (!token) {
    return Promise.resolve([]);
  }

  return apiFetchList<Journal>('/me/bookmarks/journals', {
    lang
  });
}

export function getUserPins(
  userId: string,
  lang?: string,
  cursor?: string
): Promise<CursorPage<Pin>> {
  return apiFetchPage<Pin>(`/v2/users/${userId}/pins`, {
    lang,
    cursor
  });
}

export function getMyPins(
  lang?: string,
  cursor?: string
): Promise<CursorPage<Pin>> {
  return apiFetchPage<Pin>('/v2/me/pins', {
    lang,
    cursor
  });
}

export function getBlockedAccounts(
  lang?: string,
  cursor?: string
): Promise<CursorPage<BlockedAccount>> {
  return apiFetchPage<BlockedAccount>('/v2/me/blocks', {
    lang,
    cursor
  });
}

export function getMutedAccounts(
  lang?: string,
  cursor?: string
): Promise<CursorPage<MutedAccount>> {
  return apiFetchPage<MutedAccount>('/v2/me/mutes', {
    lang,
    cursor
  });
}

export function getNotifications(
  lang: string,
  { cursor, read }: { cursor?: string; read?: boolean } = {}
): Promise<CursorPage<Notification>> {
  return apiFetchPage<Notification>('/v2/me/notifications', {
    lang,
    cursor,
    query: read === undefined ? undefined : { read: String(read) }
  });
}
