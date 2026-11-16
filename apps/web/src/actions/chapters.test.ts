import assert from 'node:assert/strict';
import { beforeEach, describe, it, mock } from 'node:test';
import type { SerializedEditorState } from 'lexical';
import type { Chapter, CursorPage } from '../../types/index.ts';
import { buildCheckin, buildJourney } from '../test/journeys.ts';
import {
  apiFetch,
  apiRequests,
  failWith,
  recordedEvents,
  resetServerActionMocks,
  respondWith,
  revalidatedTags
} from '../test/serverActionMocks.ts';
import { createChapterContent } from '../utils/chapterContent.ts';
import { createMapFeatures } from '../utils/mapFeatures.ts';

const getChapterFeed =
  mock.fn<(lang: string, cursor: string) => Promise<CursorPage<Chapter>>>();

mock.module(new URL('../lib/chapters.ts', import.meta.url).href, {
  namedExports: { getChapterFeed }
});

const actions = () => import('./chapters.ts');

const content = { root: { children: [] } } as unknown as SerializedEditorState;

function chapter(overrides: Partial<Chapter> = {}): Chapter {
  return {
    id: 5,
    map_id: 2,
    author: { id: 9 },
    ...overrides
  } as Chapter;
}

beforeEach(() => {
  resetServerActionMocks();
  getChapterFeed.mock.resetCalls();
});

describe('fetchMoreChapterFeed', () => {
  it('pages the chapter feed from the cursor', async () => {
    const { fetchMoreChapterFeed } = await actions();
    const page = { items: [chapter()], nextCursor: 'c2' };
    getChapterFeed.mock.mockImplementation(async () => page);

    const result = await fetchMoreChapterFeed('ja', 'c1');

    assert.equal(result, page);
    assert.deepEqual(getChapterFeed.mock.calls[0].arguments, ['ja', 'c1']);
  });
});

describe('createChapter', () => {
  it('creates the chapter on the map and records it', async () => {
    const { createChapter } = await actions();
    const created = chapter();
    respondWith(created, 201);

    const result = await createChapter(2, {
      title: 'Day one',
      content,
      journey_id: 11
    });

    assert.deepEqual(result, { success: true, data: created });
    assert.deepEqual(apiRequests(), [
      {
        path: '/maps/2/chapters',
        method: 'POST',
        body: { title: 'Day one', content, journey_id: 11 }
      }
    ]);
    assert.deepEqual(revalidatedTags(), ['chapters', 'map:2', 'user:9']);
    assert.deepEqual(recordedEvents(), [
      { name: 'create_chapter', params: { map_id: 2 } }
    ]);
  });

  it('reports the API error without side effects', async () => {
    const { createChapter } = await actions();
    failWith('Title is required', 422);

    const result = await createChapter(2, { title: '', content });

    assert.deepEqual(result, { success: false, error: 'Title is required' });
    assert.deepEqual(revalidatedTags(), []);
    assert.deepEqual(recordedEvents(), []);
  });
});

describe('writeJourneyChapter', () => {
  const journey = buildJourney([
    buildCheckin(1, '2026-08-01T01:00:00Z', { note: 'Slurped' })
  ]);

  function respondByPath(responses: Record<string, unknown>): void {
    apiFetch.mock.mockImplementation(async (path) => ({
      data: responses[path] ?? null,
      error: null,
      status: 200
    }));
  }

  it('creates a chapter on the journey map from its check-ins', async () => {
    const { writeJourneyChapter } = await actions();
    const created = chapter({ map_id: 10 });
    respondByPath({ '/me/journeys/1': journey, '/maps/10/chapters': created });

    const result = await writeJourneyChapter(1, 'Untitled');

    assert.deepEqual(result, { success: true, data: created });
    assert.deepEqual(apiRequests(), [
      { path: '/me/journeys/1', method: undefined, body: undefined },
      {
        path: '/maps/10/chapters',
        method: 'POST',
        body: JSON.parse(
          JSON.stringify({
            title: 'Untitled',
            content: createChapterContent(journey),
            map_features: createMapFeatures(journey),
            journey_id: 1
          })
        )
      }
    ]);
  });

  it('writes nothing for a journey whose map was deleted', async () => {
    const { writeJourneyChapter } = await actions();
    respondByPath({ '/me/journeys/1': { ...journey, map_id: null } });

    const result = await writeJourneyChapter(1, 'Untitled');

    assert.deepEqual(result, { success: false, error: undefined });
    assert.equal(apiRequests().length, 1);
  });

  it('reports a journey it cannot read', async () => {
    const { writeJourneyChapter } = await actions();
    failWith('Not Found', 404);

    const result = await writeJourneyChapter(1, 'Untitled');

    assert.deepEqual(result, { success: false, error: 'Not Found' });
    assert.equal(apiRequests().length, 1);
  });
});

describe('updateChapter', () => {
  it('saves a draft edit without recording a publish', async () => {
    const { updateChapter } = await actions();
    const updated = chapter({ status: 'draft' });
    respondWith(updated);

    const result = await updateChapter(5, {
      title: 'Renamed',
      status: 'draft'
    });

    assert.deepEqual(result, { success: true, data: updated });
    assert.deepEqual(apiRequests(), [
      {
        path: '/me/chapters/5',
        method: 'PUT',
        body: { title: 'Renamed', status: 'draft' }
      }
    ]);
    assert.deepEqual(revalidatedTags(), [
      'chapter:5',
      'chapters',
      'map:2',
      'user:9'
    ]);
    assert.deepEqual(recordedEvents(), []);
  });

  it('records a publish when the status becomes published', async () => {
    const { updateChapter } = await actions();
    respondWith(chapter({ status: 'published' }));

    await updateChapter(5, { status: 'published' });

    assert.deepEqual(recordedEvents(), [
      { name: 'publish_chapter', params: { chapter_id: 5 } }
    ]);
  });

  it('does not record a publish for an edit that leaves status alone', async () => {
    const { updateChapter } = await actions();
    respondWith(chapter({ status: 'published' }));

    await updateChapter(5, { image_ids: [1] });

    assert.deepEqual(recordedEvents(), []);
  });

  it('skips the map tag for a chapter outside any map', async () => {
    const { updateChapter } = await actions();
    respondWith(chapter({ map_id: null }));

    await updateChapter(5, { title: 'Loose' });

    assert.deepEqual(revalidatedTags(), ['chapter:5', 'chapters', 'user:9']);
  });

  it('reports a failed publish without recording it', async () => {
    const { updateChapter } = await actions();
    failWith('Forbidden', 403);

    const result = await updateChapter(5, { status: 'published' });

    assert.deepEqual(result, { success: false, error: 'Forbidden' });
    assert.deepEqual(revalidatedTags(), []);
    assert.deepEqual(recordedEvents(), []);
  });
});

describe('deleteChapter', () => {
  it('deletes the chapter and refreshes every list it appeared in', async () => {
    const { deleteChapter } = await actions();

    const result = await deleteChapter(5, 2, 9);

    assert.deepEqual(result, { success: true });
    assert.deepEqual(apiRequests(), [
      { path: '/me/chapters/5', method: 'DELETE', body: undefined }
    ]);
    assert.deepEqual(revalidatedTags(), [
      'chapter:5',
      'chapters',
      'map:2',
      'user:9'
    ]);
  });

  it('refreshes only what it knows when map and author are absent', async () => {
    const { deleteChapter } = await actions();

    await deleteChapter(5, null);

    assert.deepEqual(revalidatedTags(), ['chapter:5', 'chapters']);
  });

  it('reports the API error without refreshing', async () => {
    const { deleteChapter } = await actions();
    failWith();

    const result = await deleteChapter(5, 2, 9);

    assert.deepEqual(result, { success: false, error: 'Forbidden' });
    assert.deepEqual(revalidatedTags(), []);
  });
});
