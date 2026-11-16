import type { JourneySummary } from '../../types/index.ts';

export function journeyHeadline(
  journey: JourneySummary,
  untitledChapter: string
): string | null {
  const chapterTitle = journey.chapter?.title.trim();

  if (chapterTitle && chapterTitle !== untitledChapter) {
    return chapterTitle;
  }

  const first = journey.checkin_spot_names.at(0);
  const last = journey.checkin_spot_names.at(-1);

  if (!first || !last) {
    return null;
  }

  return first === last ? first : `${first} → ${last}`;
}
