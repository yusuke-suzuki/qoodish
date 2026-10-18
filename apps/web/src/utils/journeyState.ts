import type { Image, Journey, JourneyCheckin, Pin } from '../../types/index.ts';

export const INACTIVITY_PAUSE_MS = 8 * 60 * 60 * 1000;

export type RemainingSpots = {
  pins: Pin[];
  checkins: JourneyCheckin[];
  departures: ReadonlySet<number>;
  spots: Pin[];
  lingering: Pin[];
};

export function remainingSpots(
  previous: RemainingSpots | null,
  pins: Pin[],
  checkins: JourneyCheckin[],
  departures: ReadonlySet<number>
): RemainingSpots {
  if (
    previous &&
    previous.pins === pins &&
    previous.checkins === checkins &&
    previous.departures === departures
  ) {
    return previous;
  }

  const visitedIds = new Set(checkins.map((checkin) => checkin.pin_id));
  const spots: Pin[] = [];
  const lingering: Pin[] = [];

  for (const pin of pins) {
    if (!visitedIds.has(pin.id) || departures.has(pin.id)) {
      spots.push(pin);
    } else {
      lingering.push(pin);
    }
  }

  return { pins, checkins, departures, spots, lingering };
}

export function withDepartures(
  departures: ReadonlySet<number>,
  pins: Pin[]
): ReadonlySet<number> {
  return pins.length > 0
    ? new Set([...departures, ...pins.map((pin) => pin.id)])
    : departures;
}

export function withoutDeparture(
  departures: ReadonlySet<number>,
  pinId: number
): ReadonlySet<number> {
  if (!departures.has(pinId)) {
    return departures;
  }

  const next = new Set(departures);
  next.delete(pinId);

  return next;
}

export function isRecording(
  canRecord: boolean,
  journey: Journey | null,
  paused: boolean
): boolean {
  return Boolean(
    canRecord && journey?.started_at && !journey.finished_at && !paused
  );
}

export function isInactive(
  lastPositionAt: number | null,
  now: number
): boolean {
  if (!lastPositionAt) return false;

  return now - lastPositionAt >= INACTIVITY_PAUSE_MS;
}

export function isEmptyPlan(journey: Journey): boolean {
  return (
    !journey.started_at &&
    journey.milestones.length < 1 &&
    journey.checkins.length < 1
  );
}

export function withReplacedCheckin(
  journey: Journey,
  next: JourneyCheckin
): Journey {
  return {
    ...journey,
    checkins: journey.checkins.map((checkin) =>
      checkin.id === next.id ? next : checkin
    )
  };
}

export function withoutCheckin(journey: Journey, checkinId: number): Journey {
  return {
    ...journey,
    checkins: journey.checkins.filter((checkin) => checkin.id !== checkinId)
  };
}

export function imageIdsWith(images: Image[], imageId: number): number[] {
  return [...images.map((image) => image.id), imageId];
}

export function imageIdsWithout(images: Image[], imageId: number): number[] {
  return images
    .filter((image) => image.id !== imageId)
    .map((image) => image.id);
}
