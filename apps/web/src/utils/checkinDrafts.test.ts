import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import {
  CHECKIN_GAP_MS,
  CHECKIN_IMAGE_LIMIT,
  draftCheckin,
  groupPhotos,
  journeyPeriod,
  SAME_VISIT_MS,
  withPin
} from './checkinDrafts.ts';

const MINUTE_MS = 60 * 1000;

describe('groupPhotos', () => {
  const at = (minutes: number) => ({ capturedAt: minutes * MINUTE_MS });

  it('keeps photos within the gap in one group', () => {
    const photos = [at(0), at(30), at(60)];

    assert.deepEqual(groupPhotos(photos), [photos]);
  });

  it('starts a new group after a gap longer than the threshold', () => {
    const drafts = groupPhotos([at(0), at(61), at(62)]);

    assert.deepEqual(drafts, [[at(0)], [at(61), at(62)]]);
  });

  it('orders photos by capture time before grouping', () => {
    const drafts = groupPhotos([at(200), at(0), at(10)]);

    assert.deepEqual(drafts, [[at(0), at(10)], [at(200)]]);
  });

  it('measures the gap from the previous photo, not the first', () => {
    const photos = [at(0), at(50), at(100), at(150)];

    assert.deepEqual(groupPhotos(photos), [photos]);
  });

  it('uses the given gap', () => {
    assert.deepEqual(groupPhotos([at(0), at(10)], 5 * MINUTE_MS), [
      [at(0)],
      [at(10)]
    ]);
    assert.equal(CHECKIN_GAP_MS, 60 * MINUTE_MS);
  });

  it('returns no groups without photos', () => {
    assert.deepEqual(groupPhotos([]), []);
  });
});

describe('journeyPeriod', () => {
  it('spans the earliest to the latest capture time', () => {
    assert.deepEqual(
      journeyPeriod([
        Date.parse('2026-10-17T03:00:00Z'),
        Date.parse('2026-10-17T01:00:00Z'),
        Date.parse('2026-10-17T02:00:00Z')
      ]),
      {
        startedAt: '2026-10-17T01:00:00.000Z',
        finishedAt: '2026-10-17T03:00:00.000Z'
      }
    );
  });

  it('starts a minute before the finish when every photo shares a time', () => {
    assert.deepEqual(journeyPeriod([Date.parse('2026-10-17T01:00:00Z')]), {
      startedAt: '2026-10-17T00:59:00.000Z',
      finishedAt: '2026-10-17T01:00:00.000Z'
    });
  });
});

const photo = (key: string, minutes = 0) => ({
  key,
  capturedAt: minutes * MINUTE_MS
});

describe('draftCheckin', () => {
  it('selects the first photos up to the check-in limit', () => {
    const photos = ['a', 'b', 'c', 'd', 'e'].map((key) => photo(key));

    assert.deepEqual(draftCheckin(photos), {
      photos,
      selected: ['a', 'b', 'c', 'd'],
      pinId: null
    });
    assert.equal(CHECKIN_IMAGE_LIMIT, 4);
  });
});

describe('withPin', () => {
  const first = {
    ...draftCheckin([photo('a', 0), photo('b', 1), photo('c', 2)]),
    pinId: 1
  };
  const second = draftCheckin([photo('d', 90), photo('e', 91)]);
  const third = draftCheckin([photo('f', 200)]);

  it('sets the pin of a check-in', () => {
    assert.deepEqual(withPin([first, second, third], 1, 2), [
      first,
      { ...second, pinId: 2 },
      third
    ]);
  });

  it('joins a check-in to the one before it at the same pin as one visit', () => {
    assert.deepEqual(withPin([first, second, third], 1, 1), [
      {
        photos: [...first.photos, ...second.photos],
        selected: ['a', 'b', 'c', 'd'],
        pinId: 1
      },
      third
    ]);
  });

  it('joins the check-in after it at the same pin as one visit', () => {
    const later = { ...second, pinId: 3 };

    assert.deepEqual(
      withPin([first, draftCheckin([photo('x', 30)]), later], 1, 3),
      [
        first,
        {
          photos: [photo('x', 30), ...second.photos],
          selected: ['x', 'd', 'e'],
          pinId: 3
        }
      ]
    );
  });

  it('keeps check-ins at the same pin apart once they are too far apart for one visit', () => {
    const drafts = withPin([first, third], 1, 1);

    assert.equal(SAME_VISIT_MS, 120 * MINUTE_MS);
    assert.deepEqual(drafts, [first, { ...third, pinId: 1 }]);
  });
});
