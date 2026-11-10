import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import en from '../dictionaries/en.json' with { type: 'json' };
import ja from '../dictionaries/ja.json' with { type: 'json' };
import { EMOJI_CATEGORIES, emojiCategoryOf } from './emojiCategories.ts';

const segmenter = new Intl.Segmenter();

describe('EMOJI_CATEGORIES', () => {
  const emoji = EMOJI_CATEGORIES.flatMap((category) => category.emoji);

  it('lists each emoji once, as a single character shown as an emoji', () => {
    assert.equal(new Set(emoji).size, emoji.length);

    for (const candidate of emoji) {
      assert.equal([...segmenter.segment(candidate)].length, 1, candidate);
      assert.match(candidate, /\p{Emoji_Presentation}|\u{FE0F}/u);
    }
  });

  it('names every category in each dictionary', () => {
    for (const dictionary of [en, ja] as Record<string, string>[]) {
      for (const category of EMOJI_CATEGORIES) {
        assert.ok(dictionary[`emoji category ${category.id}`], category.id);
      }
    }
  });
});

describe('emojiCategoryOf', () => {
  it('finds the category that lists an emoji', () => {
    assert.equal(emojiCategoryOf('🍜'), 'food');
    assert.equal(emojiCategoryOf('👍'), 'people');
  });

  it('returns null for no emoji or one that no category lists', () => {
    assert.equal(emojiCategoryOf(null), null);
    assert.equal(emojiCategoryOf('🦄'), null);
  });
});
