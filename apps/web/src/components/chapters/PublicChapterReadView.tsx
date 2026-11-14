import {
  CHAPTERS_TAG,
  CONTENT_TAG,
  chapterTag,
  mapTag,
  userTag
} from '../../lib/cacheTags.ts';
import {
  getChapter,
  getChapterComments,
  getUserChapters
} from '../../lib/chapters.ts';
import { getMap } from '../../lib/maps.ts';
import { cachePublic } from '../../lib/publicCache.ts';
import ChapterContent from './ChapterContent.tsx';
import ChapterReadView from './ChapterReadView.tsx';

type Props = {
  chapterId: string;
  lang: string;
};

export default async function PublicChapterReadView({
  chapterId,
  lang
}: Props) {
  'use cache';
  await cachePublic(300, [chapterTag(chapterId), CONTENT_TAG]);
  const [chapter, comments] = await Promise.all([
    getChapter(chapterId, lang),
    getChapterComments(chapterId, lang)
  ]);

  if (!chapter) {
    return null;
  }

  await cachePublic(300, [
    userTag(chapter.author.id),
    CHAPTERS_TAG,
    ...(chapter.map_id ? [mapTag(chapter.map_id)] : [])
  ]);

  const [map, authorChapters] = await Promise.all([
    chapter.map_id ? getMap(String(chapter.map_id), lang) : null,
    getUserChapters(chapter.author.id, lang)
  ]);

  return (
    <ChapterReadView
      chapter={chapter}
      body={<ChapterContent content={chapter.content} />}
      map={map}
      authorJournal={null}
      authorPageCount={authorChapters.length}
      comments={comments}
    />
  );
}
