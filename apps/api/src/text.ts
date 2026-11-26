export function characters(text: string): number {
  return [...text].length;
}

const graphemeSegmenter = new Intl.Segmenter(undefined, {
  granularity: 'grapheme'
});

export function graphemes(text: string): number {
  return [...graphemeSegmenter.segment(text)].length;
}

// Format and control characters that render as nothing and so hide or
// reorder text. Tag characters are allowed only inside a flag emoji.
const HIDING_CHARACTER =
  /(?![\t\n\r])\p{Cc}|[\u00AD\u180E\u200B\u202A-\u202E\u2060-\u2064\u2066-\u206F\uFEFF\uFFF9-\uFFFB\u{E0000}-\u{E007F}]/u;
const FLAG_TAG_SEQUENCE =
  /\u{1F3F4}[\u{E0030}-\u{E0039}\u{E0061}-\u{E007A}]+\u{E007F}/gu;

// Default ignorable characters, such as the Hangul fillers and the combining
// grapheme joiner, draw nothing even outside the format category, and the
// braille blank is a symbol with an empty cell; all of them can make a name
// look empty.
const BLANK_CHARACTER = /[\s\p{Cf}\p{Default_Ignorable_Code_Point}\u2800]/gu;

export function containsInvisibleCharacters(text: string): boolean {
  return HIDING_CHARACTER.test(text.replace(FLAG_TAG_SEQUENCE, ''));
}

export function looksBlank(text: string): boolean {
  return text.replace(BLANK_CHARACTER, '') === '';
}

export function withoutCarriageReturns(text: string): string {
  return text.replaceAll('\r', '');
}

export function truncate(text: string, length: number): string {
  const omission = '...';

  if (characters(text) <= length) {
    return text;
  }

  return `${[...text].slice(0, length - omission.length).join('')}${omission}`;
}
