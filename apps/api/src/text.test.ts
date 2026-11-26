import { describe, expect, it } from 'vitest';
import { containsInvisibleCharacters, looksBlank } from './text.ts';

describe('containsInvisibleCharacters', () => {
  it.each([
    ['a zero width space', 'Al\u200Bice'],
    ['a right-to-left override', 'Alice\u202Egnp.exe'],
    ['a directional isolate', '\u2066Alice\u2069'],
    ['a byte order mark', '\uFEFFAlice'],
    ['a soft hyphen', 'Al\u00ADice'],
    ['a null character', 'Alice\u0000'],
    ['an escape character', '\u001B[31mAlice'],
    ['tag characters outside a flag', 'Alice\u{E0068}\u{E0069}'],
    ['tag characters that no flag uses', '\u{1F3F4}\u{E0021}\u{E007F}'],
    [
      'a flag emoji followed by stray tag characters',
      '\u{1F3F4}\u{E0067}\u{E007F}\u{E0068}'
    ]
  ])('finds %s', (_, text) => {
    expect(containsInvisibleCharacters(text)).toBe(true);
  });

  it.each([
    ['plain text', 'Alice'],
    ['Japanese text', '\u6771\u4EAC\u306E\u30E9\u30FC\u30E1\u30F3'],
    ['line breaks and tabs', 'first line\r\n\tsecond line'],
    [
      'an emoji joined by zero width joiners',
      '\u{1F468}\u200D\u{1F469}\u200D\u{1F467}'
    ],
    [
      'a subdivision flag emoji',
      '\u{1F3F4}\u{E0067}\u{E0062}\u{E0065}\u{E006E}\u{E0067}\u{E007F}'
    ],
    [
      'a zero width non-joiner in Persian',
      '\u0645\u06CC\u200C\u062E\u0648\u0627\u0647\u0645'
    ],
    ['a right-to-left mark', '\u05E9\u05DC\u05D5\u05DD\u200F'],
    ['an Arabic number sign', '\u0600\u0661\u0662'],
    ['a CJK compatibility ideograph', '\uFA19']
  ])('accepts %s', (_, text) => {
    expect(containsInvisibleCharacters(text)).toBe(false);
  });
});

describe('looksBlank', () => {
  it.each([
    ['spaces and line breaks', ' \n\u3000'],
    ['zero width joiners', '\u200D\u200D'],
    ['a right-to-left mark', '\u200F'],
    ['a Hangul filler', '\u3164'],
    ['a braille blank', '\u2800'],
    ['a combining grapheme joiner', '\u034F']
  ])('treats %s as blank', (_, text) => {
    expect(looksBlank(text)).toBe(true);
  });

  it('does not treat a name with a visible character as blank', () => {
    expect(looksBlank(' \u3164Alice ')).toBe(false);
  });
});
