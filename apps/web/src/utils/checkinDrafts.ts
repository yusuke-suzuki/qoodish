export const CHECKIN_GAP_MS = 60 * 60 * 1000;

export const CHECKIN_IMAGE_LIMIT = 4;

export const SAME_VISIT_MS = 2 * 60 * 60 * 1000;

export const CLOCK_SKEW_MS = 5 * 60 * 1000;

const MINUTE_MS = 60 * 1000;

export type DatedPhoto = {
  capturedAt: number;
};

export type KeyedPhoto = DatedPhoto & {
  key: string;
};

export type CheckinDraft<T extends KeyedPhoto> = {
  photos: T[];
  selected: string[];
  pinId: number | null;
};

export function draftCheckin<T extends KeyedPhoto>(
  photos: T[]
): CheckinDraft<T> {
  return {
    photos,
    selected: photos.slice(0, CHECKIN_IMAGE_LIMIT).map((photo) => photo.key),
    pinId: null
  };
}

function mergedWithPrevious<T extends KeyedPhoto>(
  drafts: CheckinDraft<T>[],
  index: number
): CheckinDraft<T>[] {
  const previous = drafts[index - 1];
  const current = drafts[index];

  if (!previous || !current) {
    return drafts;
  }

  const merged: CheckinDraft<T> = {
    photos: [...previous.photos, ...current.photos],
    selected: [...previous.selected, ...current.selected].slice(
      0,
      CHECKIN_IMAGE_LIMIT
    ),
    pinId: previous.pinId
  };

  return drafts.toSpliced(index - 1, 2, merged);
}

function sameVisit<T extends KeyedPhoto>(
  earlier: CheckinDraft<T> | undefined,
  later: CheckinDraft<T> | undefined
): boolean {
  return (
    earlier !== undefined &&
    later !== undefined &&
    earlier.pinId !== null &&
    earlier.pinId === later.pinId &&
    later.photos[0].capturedAt - earlier.photos[0].capturedAt < SAME_VISIT_MS
  );
}

export function withPin<T extends KeyedPhoto>(
  drafts: CheckinDraft<T>[],
  index: number,
  pinId: number
): CheckinDraft<T>[] {
  let updated = drafts.map((draft, i) =>
    i === index ? { ...draft, pinId } : draft
  );

  if (sameVisit(updated[index], updated[index + 1])) {
    updated = mergedWithPrevious(updated, index + 1);
  }

  if (sameVisit(updated[index - 1], updated[index])) {
    updated = mergedWithPrevious(updated, index);
  }

  return updated;
}

export function groupPhotos<T extends DatedPhoto>(
  photos: T[],
  gapMs: number = CHECKIN_GAP_MS
): T[][] {
  const groups: T[][] = [];

  for (const photo of photos.toSorted((a, b) => a.capturedAt - b.capturedAt)) {
    const current = groups.at(-1);
    const previous = current?.at(-1);

    if (
      current &&
      previous &&
      photo.capturedAt - previous.capturedAt <= gapMs
    ) {
      current.push(photo);
    } else {
      groups.push([photo]);
    }
  }

  return groups;
}

export function journeyPeriod(times: number[]): {
  startedAt: string;
  finishedAt: string;
} {
  const start = Math.min(...times);
  const finish = Math.max(...times);

  return {
    startedAt: new Date(
      finish > start ? start : start - MINUTE_MS
    ).toISOString(),
    finishedAt: new Date(finish).toISOString()
  };
}
