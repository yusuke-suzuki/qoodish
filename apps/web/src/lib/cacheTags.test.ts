import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import { pinListTags } from './cacheTags.ts';

describe('pinListTags', () => {
  it('tags each pin and each of their maps once', () => {
    const pins = [
      { id: 1, map: { id: 10 } },
      { id: 2, map: { id: 10 } },
      { id: 3, map: { id: 20 } }
    ];

    assert.deepEqual(pinListTags(pins), [
      'pin:1',
      'map:10',
      'pin:2',
      'pin:3',
      'map:20'
    ]);
  });
});
