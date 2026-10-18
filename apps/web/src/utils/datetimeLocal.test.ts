import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import { toDatetimeLocal } from './datetimeLocal.ts';

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
