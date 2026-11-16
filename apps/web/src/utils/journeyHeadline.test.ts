import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import type { JourneySummary } from '../../types/index.ts';
import { journeyHeadline } from './journeyHeadline.ts';

function summary(overrides: Partial<JourneySummary> = {}): JourneySummary {
  return {
    id: 1,
    map_id: 10,
    started_at: '2026-08-01T00:00:00Z',
    finished_at: '2026-08-01T06:00:00Z',
    milestones_count: 0,
    checkins_count: 0,
    checkin_spot_names: [],
    cover_image: null,
    chapter_id: null,
    chapter: null,
    map: null,
    created_at: '2026-08-01T00:00:00Z',
    updated_at: '2026-08-01T00:00:00Z',
    ...overrides
  };
}

const UNTITLED = 'Untitled chapter';

function headline(overrides: Partial<JourneySummary>): string | null {
  return journeyHeadline(summary(overrides), UNTITLED);
}

const route = ['Station', 'Cafe', 'Temple'];

describe('journeyHeadline', () => {
  it('names the journey after its chapter', () => {
    assert.equal(
      headline({
        checkin_spot_names: route,
        chapter: { id: 3, title: 'Autumn walk', status: 'draft' }
      }),
      'Autumn walk'
    );
  });

  for (const title of [UNTITLED, '  ']) {
    it(`keeps the route while the chapter is titled ${JSON.stringify(title)}`, () => {
      assert.equal(
        headline({
          checkin_spot_names: route,
          chapter: { id: 3, title, status: 'draft' }
        }),
        'Station → Temple'
      );
    });
  }

  it('traces the journey from its first to its last spot', () => {
    assert.equal(headline({ checkin_spot_names: route }), 'Station → Temple');
  });

  it('names a journey that ends where it began after that spot', () => {
    assert.equal(
      headline({ checkin_spot_names: ['Station', 'Station'] }),
      'Station'
    );
  });

  it('has no headline before the first check-in', () => {
    assert.equal(headline({}), null);
  });
});
