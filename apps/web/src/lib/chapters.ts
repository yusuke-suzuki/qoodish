import type { Chapter, CommentItem, CursorPage } from '../../types/index.ts';
import {
  apiFetch,
  apiFetchList,
  apiFetchPage,
  assertApiAvailable
} from './api.ts';
import { CHAPTERS_TAG, CONTENT_TAG, chapterTag, userTag } from './cacheTags.ts';
import { cachePublic } from './publicCache.ts';

async function fetchChapter(
  chapterId: string | number,
  lang: string,
  guest: boolean
): Promise<Chapter | null> {
  const { data, status } = await apiFetch<Chapter>(`/chapters/${chapterId}`, {
    lang,
    guest
  });
  assertApiAvailable(status, `/chapters/${chapterId}`);
  return data;
}

async function getPublicChapter(
  chapterId: string | number,
  lang: string
): Promise<Chapter | null> {
  'use cache';
  await cachePublic(300, [chapterTag(chapterId), CONTENT_TAG]);
  return fetchChapter(chapterId, lang, true);
}

export function getChapter(
  chapterId: string | number,
  lang: string,
  token?: string
): Promise<Chapter | null> {
  return token
    ? fetchChapter(chapterId, lang, false)
    : getPublicChapter(chapterId, lang);
}

function fetchChapterComments(
  chapterId: string | number,
  lang: string,
  guest: boolean
): Promise<CommentItem[]> {
  return apiFetchList<CommentItem>(`/chapters/${chapterId}/comments`, {
    lang,
    guest
  });
}

async function getPublicChapterComments(
  chapterId: string | number,
  lang: string
): Promise<CommentItem[]> {
  'use cache';
  await cachePublic(300, [chapterTag(chapterId), CONTENT_TAG]);
  return fetchChapterComments(chapterId, lang, true);
}

export function getChapterComments(
  chapterId: string | number,
  lang: string,
  token?: string
): Promise<CommentItem[]> {
  return token
    ? fetchChapterComments(chapterId, lang, false)
    : getPublicChapterComments(chapterId, lang);
}

export async function getRecentChapters(lang: string): Promise<Chapter[]> {
  'use cache';
  await cachePublic(900, [CHAPTERS_TAG]);
  return apiFetchList<Chapter>('/chapters', { lang, guest: true });
}

export async function getChapterFeed(
  lang: string,
  cursor?: string
): Promise<CursorPage<Chapter>> {
  'use cache';
  await cachePublic(cursor ? 300 : 900, [CHAPTERS_TAG]);
  return apiFetchPage<Chapter>('/v2/chapters', { lang, guest: true, cursor });
}

function fetchUserChapters(
  userId: string | number,
  lang: string,
  guest: boolean
): Promise<Chapter[]> {
  return apiFetchList<Chapter>(`/users/${userId}/chapters`, { lang, guest });
}

async function getPublicUserChapters(
  userId: string | number,
  lang: string
): Promise<Chapter[]> {
  'use cache';
  await cachePublic(300, [userTag(userId), CHAPTERS_TAG]);
  return fetchUserChapters(userId, lang, true);
}

export function getUserChapters(
  userId: string | number,
  lang: string,
  token?: string
): Promise<Chapter[]> {
  return token
    ? fetchUserChapters(userId, lang, false)
    : getPublicUserChapters(userId, lang);
}

export function getMyChapters(
  lang: string,
  token?: string
): Promise<Chapter[]> {
  if (!token) {
    return Promise.resolve([]);
  }

  return apiFetchList<Chapter>('/me/chapters', {
    lang
  });
}
