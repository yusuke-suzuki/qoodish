import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import { isPastPeriod, toDatetimeLocal } from './datetimeLocal.ts';

describe('toDatetimeLocal', () => {
  it('formats the local date and time to the minute', () => {
    const local = new Date(2026, 4, 1, 9, 5, 42);

    assert.equal(toDatetimeLocal(local.toISOString()), '2026-05-01T09:05');
  });

  it('pads a year below 1000 to four digits', () => {
    const local = new Date(2026, 4, 1, 9, 5);

    local.setFullYear(26);

    assert.equal(toDatetimeLocal(local), '0026-05-01T09:05');
  });
});

describe('isPastPeriod', () => {
  const now = '2026-05-10T12:00';

  it('accepts a period that starts before it finishes, by now', () => {
    assert.equal(
      isPastPeriod('2026-05-01T09:00', '2026-05-03T18:00', now),
      true
    );
    assert.equal(isPastPeriod('2026-05-10T09:00', now, now), true);
  });

  it('rejects a missing, reversed, empty or future period', () => {
    assert.equal(isPastPeriod('', '2026-05-03T18:00', now), false);
    assert.equal(isPastPeriod('2026-05-01T09:00', '', now), false);
    assert.equal(
      isPastPeriod('2026-05-03T18:00', '2026-05-01T09:00', now),
      false
    );
    assert.equal(
      isPastPeriod('2026-05-01T09:00', '2026-05-01T09:00', now),
      false
    );
    assert.equal(
      isPastPeriod('2026-05-10T09:00', '2026-05-10T12:01', now),
      false
    );
  });
});
