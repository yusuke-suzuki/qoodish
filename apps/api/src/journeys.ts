import type {
  Journey,
  JourneyCheckin,
  JourneySummary,
  MapRef,
  Milestone
} from '@qoodish/api-contract';
import {
  and,
  asc,
  desc,
  eq,
  inArray,
  isNotNull,
  isNull,
  max,
  ne,
  notExists,
  type SQL,
  type SQLWrapper,
  sql
} from 'drizzle-orm';
import { QueryBuilder } from 'drizzle-orm/sqlite-core';
import { z } from 'zod';
import { detachJourneys } from './chapters.ts';
import {
  changedColumns,
  chunks,
  currentTimestamp,
  type Database,
  generatedId,
  scalar,
  selected
} from './db/client.ts';
import {
  chapters,
  images,
  journeyCheckinImages,
  journeyCheckins,
  journeys,
  maps,
  milestones
} from './db/schema.ts';
import {
  decryptAttribute,
  type EncryptionSecrets,
  encryptAttribute
} from './encryption.ts';
import { ApiError } from './errors.ts';
import type { MessageKey } from './i18n/index.ts';
import {
  image,
  imageOwnersQuery,
  sameIds,
  unownedImageErrors,
  unownedImages
} from './images.ts';
import { type PinRow, referenceablePinQuery } from './pins.ts';
import { first, present } from './routing.ts';
import { characters, withoutCarriageReturns } from './text.ts';
import { parseTimestamp } from './timestamps.ts';
import { imageIds, optionalId } from './validation.ts';
import type { Viewer } from './visibility.ts';

const ENCODED_PATH_LIMIT = 1_000_000;
const CHECKIN_NOTE_LIMIT = 500;
const CHECKIN_IMAGE_LIMIT = 4;
const IMAGES_PER_INSERT = 10;
const CLIENT_CLOCK_SKEW_MS = 5 * 60 * 1000;

const qb = new QueryBuilder();

export type JourneyRecord = typeof journeys.$inferSelect;

export type JourneyOwner = { userId: number; journeyId: number };

type CheckinRow = typeof journeyCheckins.$inferSelect;

type CheckinSpot = {
  pinId: number | null;
  name: string;
  latitude: number;
  longitude: number;
};

type CheckinContent = CheckinSpot & {
  note: string | null;
  checkedInAt: string;
  status: 'recorded' | 'deleted';
};

type CheckinImage = { checkinId: number; id: number; url: string };

const journeyColumns = {
  id: journeys.id,
  mapId: journeys.mapId,
  startedAt: journeys.startedAt,
  finishedAt: journeys.finishedAt,
  encodedPath: journeys.encodedPath,
  createdAt: journeys.createdAt,
  updatedAt: journeys.updatedAt,
  chapterId: sql<number | null>`${qb
    .select({ id: chapters.id })
    .from(chapters)
    .where(eq(chapters.journeyId, journeys.id))
    .orderBy(asc(chapters.id))
    .limit(1)}`.as('chapter_id'),
  mapName: maps.name,
  mapPrivate: maps.private
};

function journeysQuery(db: Database, condition: SQL | undefined) {
  return db
    .select(journeyColumns)
    .from(journeys)
    .leftJoin(maps, eq(maps.id, journeys.mapId))
    .where(condition);
}

type JourneyRow = Awaited<ReturnType<typeof journeysQuery>>[number];

function mapRef(row: JourneyRow): MapRef | null {
  return row.mapId === null || row.mapName === null
    ? null
    : { id: row.mapId, name: row.mapName, private: row.mapPrivate as boolean };
}

const recorded = ne(journeyCheckins.status, 'deleted');

function milestoneOf(milestone: typeof milestones.$inferSelect): Milestone {
  return {
    id: milestone.id,
    pin_id: milestone.pinId,
    name: milestone.name,
    latitude: milestone.latitude,
    longitude: milestone.longitude
  };
}

function checkinImagesQuery(db: Database, condition: SQL | undefined) {
  return db
    .select({
      checkinId: journeyCheckinImages.journeyCheckinId,
      id: images.id,
      url: images.url
    })
    .from(journeyCheckinImages)
    .innerJoin(images, eq(images.id, journeyCheckinImages.imageId))
    .where(
      inArray(
        journeyCheckinImages.journeyCheckinId,
        db
          .select({ id: journeyCheckins.id })
          .from(journeyCheckins)
          .where(condition)
      )
    )
    .orderBy(asc(images.id));
}

function checkinOf(
  checkin: CheckinRow,
  imagesByCheckin: Map<number, CheckinImage[]>
): JourneyCheckin {
  return {
    id: checkin.id,
    pin_id: checkin.pinId,
    spot: {
      name: checkin.name,
      latitude: checkin.latitude,
      longitude: checkin.longitude
    },
    note: checkin.note,
    images: (imagesByCheckin.get(checkin.id) ?? []).map((item) =>
      image(item.id, item.url)
    ),
    checked_in_at: checkin.checkedInAt,
    origin: checkin.origin
  };
}

export async function journeySummaries(
  db: Database,
  userId: number
): Promise<JourneySummary[]> {
  const rows = await db
    .select({
      ...journeyColumns,
      milestonesCount: db
        .$count(milestones, eq(milestones.journeyId, journeys.id))
        .as('milestones_count'),
      checkinsCount: db
        .$count(
          journeyCheckins,
          and(eq(journeyCheckins.journeyId, journeys.id), recorded)
        )
        .as('checkins_count')
    })
    .from(journeys)
    .leftJoin(maps, eq(maps.id, journeys.mapId))
    .where(eq(journeys.userId, userId))
    .orderBy(
      desc(sql`coalesce(${journeys.startedAt}, ${journeys.createdAt})`),
      asc(journeys.id)
    );

  return rows.map((row) => ({
    id: row.id,
    map_id: row.mapId,
    started_at: row.startedAt,
    finished_at: row.finishedAt,
    milestones_count: row.milestonesCount,
    checkins_count: row.checkinsCount,
    chapter_id: row.chapterId,
    map: mapRef(row),
    created_at: row.createdAt,
    updated_at: row.updatedAt
  }));
}

export async function journeyDetail(
  db: Database,
  condition: SQL | undefined,
  secrets: EncryptionSecrets
): Promise<Journey> {
  const row = first(await journeysQuery(db, condition));
  const recordedCheckins = and(eq(journeyCheckins.journeyId, row.id), recorded);
  const [milestoneRows, checkinRows, checkinImages] = await db.batch([
    db
      .select()
      .from(milestones)
      .where(eq(milestones.journeyId, row.id))
      .orderBy(asc(milestones.position)),
    db
      .select()
      .from(journeyCheckins)
      .where(recordedCheckins)
      .orderBy(asc(journeyCheckins.checkedInAt), asc(journeyCheckins.id)),
    checkinImagesQuery(db, recordedCheckins)
  ]);
  const imagesByCheckin = Map.groupBy(checkinImages, (item) => item.checkinId);

  return {
    id: row.id,
    map_id: row.mapId,
    started_at: row.startedAt,
    finished_at: row.finishedAt,
    milestones: milestoneRows.map(milestoneOf),
    checkins: checkinRows.map((checkin) => checkinOf(checkin, imagesByCheckin)),
    encoded_path:
      row.encodedPath === null
        ? null
        : await decryptAttribute(row.encodedPath, secrets),
    chapter_id: row.chapterId,
    map: mapRef(row),
    created_at: row.createdAt,
    updated_at: row.updatedAt
  };
}

export async function journeyCheckin(
  db: Database,
  checkinId: number
): Promise<JourneyCheckin> {
  const condition = eq(journeyCheckins.id, checkinId);
  const [rows, checkinImages] = await db.batch([
    db.select().from(journeyCheckins).where(condition),
    checkinImagesQuery(db, condition)
  ]);

  return checkinOf(
    first(rows),
    Map.groupBy(checkinImages, (item) => item.checkinId)
  );
}

const pinId = z
  .union([z.number(), z.string()])
  .optional()
  .transform(optionalId);

function timestamp(error: MessageKey) {
  return z.string({ error }).transform((value, ctx) => {
    const parsed = parseTimestamp(value);

    if (parsed === null) {
      ctx.addIssue({ code: 'custom', input: value, message: error });
      return z.NEVER;
    }

    return parsed;
  });
}

function checkinOrigin(
  checkedInAt: string | null | undefined
): CheckinRow['origin'] {
  return typeof checkedInAt === 'string' ? 'manual' : 'tracked';
}

const checkinFields = {
  note: z
    .string()
    .overwrite(withoutCarriageReturns)
    .refine((value) => characters(value) <= CHECKIN_NOTE_LIMIT, {
      error: 'checkin_note_exceeded'
    })
    .nullable()
    .optional(),
  checked_in_at: timestamp('checkin_time_invalid').nullable().optional(),
  image_ids: imageIds({
    max: CHECKIN_IMAGE_LIMIT,
    error: 'images_per_checkin_reached_limit'
  }).optional()
};

export const milestoneInput = z.object({ pin_id: pinId });

export const newCheckinInput = z
  .object({ pin_id: pinId, ...checkinFields })
  .transform((input) => ({
    ...input,
    origin: checkinOrigin(input.checked_in_at)
  }));

export const checkinInput = z.object({
  pin_id: z.union([z.number(), z.string()]).optional(),
  ...checkinFields
});

export const finishInput = z.object({
  encoded_path: z
    .string()
    .refine((value) => characters(value) <= ENCODED_PATH_LIMIT, {
      error: 'journey_encoded_path_exceed'
    })
    .nullish()
});

function unfinishedJourneyOf(userId: number, mapId: SQLWrapper) {
  return qb
    .select({ id: journeys.id })
    .from(journeys)
    .where(
      and(
        eq(journeys.userId, userId),
        eq(journeys.mapId, mapId),
        isNull(journeys.finishedAt)
      )
    );
}

const journeyTime = timestamp('journey_period_invalid');

export type JourneyPeriod = { startedAt: string; finishedAt: string };

export const newJourneyInput = z
  .object({
    started_at: journeyTime.optional(),
    finished_at: journeyTime.optional()
  })
  .transform(({ started_at, finished_at }, ctx): JourneyPeriod | undefined => {
    if (started_at === undefined && finished_at === undefined) {
      return undefined;
    }

    if (
      started_at === undefined ||
      finished_at === undefined ||
      started_at >= finished_at
    ) {
      ctx.addIssue({ code: 'custom', message: 'journey_period_invalid' });
      return z.NEVER;
    }

    const latestFinish = new Date(Date.now() + CLIENT_CLOCK_SKEW_MS)
      .toISOString()
      .replace('Z', '000Z');

    if (finished_at > latestFinish) {
      ctx.addIssue({ code: 'custom', message: 'journey_period_in_future' });
      return z.NEVER;
    }

    return { startedAt: started_at, finishedAt: finished_at };
  });

export async function createJourney(
  db: Database,
  {
    userId,
    mapId,
    period
  }: { userId: number; mapId: number; period?: JourneyPeriod }
): Promise<number> {
  const now = currentTimestamp();
  const [created] = await db
    .insert(journeys)
    .select(
      db
        .select({
          id: generatedId(),
          createdAt: selected(now, 'created_at'),
          encodedPath: sql<string | null>`NULL`.as('encoded_path'),
          finishedAt: selected(period?.finishedAt ?? null, 'finished_at'),
          mapId: maps.id,
          startedAt: selected(period?.startedAt ?? null, 'started_at'),
          updatedAt: selected(now, 'updated_at'),
          userId: selected(userId, 'user_id')
        })
        .from(maps)
        .where(
          and(
            eq(maps.id, mapId),
            period ? undefined : notExists(unfinishedJourneyOf(userId, maps.id))
          )
        )
    )
    .returning({ id: journeys.id });

  if (!created) {
    throw ApiError.invalid(['duplicate_unfinished_journey']);
  }

  return created.id;
}

export function ownedJourney(
  { userId, journeyId }: JourneyOwner,
  condition?: SQL
): SQL | undefined {
  return and(
    eq(journeys.id, journeyId),
    eq(journeys.userId, userId),
    condition
  );
}

function ownedJourneyQuery(db: Database, owner: JourneyOwner, condition?: SQL) {
  return db.select().from(journeys).where(ownedJourney(owner, condition));
}

export async function ownJourney(
  db: Database,
  owner: JourneyOwner,
  condition?: SQL
): Promise<JourneyRecord> {
  return first(await ownedJourneyQuery(db, owner, condition));
}

const unfinishedJourney = isNull(journeys.finishedAt);

export async function startJourney(
  db: Database,
  owner: JourneyOwner
): Promise<void> {
  const unfinished = ownedJourney(owner, unfinishedJourney);
  const now = currentTimestamp();
  const [[journey]] = await db.batch([
    db
      .select({ startedAt: journeys.startedAt })
      .from(journeys)
      .where(unfinished),
    db
      .update(journeys)
      .set({ startedAt: now, updatedAt: now })
      .where(and(unfinished, isNull(journeys.startedAt)))
  ]);

  if (!journey) {
    throw new ApiError('NotFound');
  }

  if (journey.startedAt !== null) {
    throw new ApiError('Conflict', undefined, ['journey_already_started']);
  }
}

export async function finishJourney(
  db: Database,
  owner: JourneyOwner,
  {
    encodedPath,
    secrets
  }: { encodedPath: string | null | undefined; secrets: EncryptionSecrets }
): Promise<void> {
  const journey = await ownJourney(db, owner, unfinishedJourney);

  if (journey.startedAt === null) {
    throw new ApiError('Conflict', undefined, ['journey_not_started']);
  }

  const encrypted =
    encodedPath !== null && present(encodedPath)
      ? await encryptAttribute(encodedPath, secrets)
      : undefined;
  const now = currentTimestamp();
  const finished = await db
    .update(journeys)
    .set({
      finishedAt: now,
      updatedAt: now,
      ...(encrypted === undefined ? {} : { encodedPath: encrypted })
    })
    .where(
      and(ownedJourney(owner, unfinishedJourney), isNotNull(journeys.startedAt))
    )
    .returning({ id: journeys.id });

  first(finished);
}

export function journeyDependentsDeletion(
  db: Database,
  journeyIds: SQLWrapper
) {
  const checkinIds = db
    .select({ id: journeyCheckins.id })
    .from(journeyCheckins)
    .where(inArray(journeyCheckins.journeyId, journeyIds));

  return [
    db
      .delete(journeyCheckinImages)
      .where(inArray(journeyCheckinImages.journeyCheckinId, checkinIds)),
    db
      .delete(journeyCheckins)
      .where(inArray(journeyCheckins.journeyId, journeyIds)),
    db.delete(milestones).where(inArray(milestones.journeyId, journeyIds)),
    detachJourneys(db, journeyIds)
  ] as const;
}

export function checkinImagesOfImagesDeletion(
  db: Database,
  imageIds: SQLWrapper
) {
  return db
    .delete(journeyCheckinImages)
    .where(inArray(journeyCheckinImages.imageId, imageIds));
}

export function journeysDeletion(db: Database, journeyIds: SQLWrapper) {
  return db.delete(journeys).where(inArray(journeys.id, journeyIds));
}

export function detachJourneysFromPins(db: Database, pinIds: SQLWrapper) {
  return [
    db
      .update(milestones)
      .set({ pinId: null })
      .where(inArray(milestones.pinId, pinIds)),
    db
      .update(journeyCheckins)
      .set({ pinId: null })
      .where(inArray(journeyCheckins.pinId, pinIds))
  ] as const;
}

export function detachJourneysFromMaps(db: Database, mapIds: SQLWrapper) {
  return db
    .update(journeys)
    .set({ mapId: null })
    .where(inArray(journeys.mapId, mapIds));
}

export async function destroyJourney(
  db: Database,
  owner: JourneyOwner
): Promise<void> {
  const journeyIds = db
    .select({ id: journeys.id })
    .from(journeys)
    .where(ownedJourney(owner));
  const results = await db.batch([
    ...journeyDependentsDeletion(db, journeyIds),
    db
      .delete(journeys)
      .where(ownedJourney(owner))
      .returning({ id: journeys.id })
  ]);

  first(results[results.length - 1] as { id: number }[]);
}

function pinErrors(journey: JourneyRecord, pin: PinRow): MessageKey[] {
  return pin.mapId === journey.mapId ? [] : ['pin_not_on_journey_map'];
}

function spotOf(pin: PinRow): CheckinSpot {
  return {
    pinId: pin.id,
    name: pin.name,
    latitude: pin.latitude,
    longitude: pin.longitude
  };
}

function assertValid(errors: readonly MessageKey[]): void {
  if (errors.length > 0) {
    throw ApiError.invalid(errors);
  }
}

export async function addMilestone(
  db: Database,
  viewer: Viewer,
  { owner, pinId }: { owner: JourneyOwner; pinId: number | undefined }
): Promise<Milestone> {
  if (pinId === undefined) {
    throw new ApiError('NotFound');
  }

  const [[journey], [pin]] = await db.batch([
    ownedJourneyQuery(db, owner, unfinishedJourney),
    referenceablePinQuery(db, viewer, pinId)
  ]);

  if (!journey || !pin) {
    throw new ApiError('NotFound');
  }

  assertValid(pinErrors(journey, pin));

  const now = currentTimestamp();
  const [added] = await db
    .insert(milestones)
    .select(
      db
        .select({
          id: generatedId(),
          createdAt: selected(now, 'created_at'),
          journeyId: journeys.id,
          latitude: selected(pin.latitude, 'latitude'),
          longitude: selected(pin.longitude, 'longitude'),
          name: selected(pin.name, 'name'),
          pinId: selected(pin.id, 'pin_id'),
          position: sql<number>`${scalar(
            qb
              .select({
                position:
                  sql<number>`coalesce(max(${milestones.position}), 0) + 1`.as(
                    'position'
                  )
              })
              .from(milestones)
              .where(eq(milestones.journeyId, journey.id))
          )}`.as('position'),
          updatedAt: selected(now, 'updated_at')
        })
        .from(journeys)
        .where(and(eq(journeys.id, journey.id), unfinishedJourney))
    )
    .onConflictDoNothing()
    .returning();

  if (!added) {
    const [duplicate] = await db
      .select({ id: milestones.id })
      .from(milestones)
      .where(
        and(eq(milestones.journeyId, journey.id), eq(milestones.pinId, pin.id))
      )
      .limit(1);

    throw ApiError.invalid([
      duplicate ? 'duplicate_milestone' : 'journey_already_finished'
    ]);
  }

  return milestoneOf(added);
}

export async function removeMilestone(
  db: Database,
  {
    userId,
    journeyId,
    milestoneId
  }: { userId: number; journeyId: number; milestoneId: number }
): Promise<void> {
  const removed = await db
    .delete(milestones)
    .where(
      and(
        eq(milestones.id, milestoneId),
        inArray(
          milestones.journeyId,
          db
            .select({ id: journeys.id })
            .from(journeys)
            .where(ownedJourney({ userId, journeyId }, unfinishedJourney))
        )
      )
    )
    .returning({ id: milestones.id });

  first(removed);
}

function periodErrors(
  journey: JourneyRecord,
  checkedInAt: string | null
): MessageKey[] {
  if (journey.startedAt === null) {
    return ['journey_not_started'];
  }

  const upperBound = journey.finishedAt ?? currentTimestamp();

  return checkedInAt !== null &&
    checkedInAt >= journey.startedAt &&
    checkedInAt <= upperBound
    ? []
    : ['checkin_time_outside_journey_period'];
}

function assertWithinPeriod(
  journey: JourneyRecord,
  checkedInAt: string | null
): asserts checkedInAt is string {
  assertValid(periodErrors(journey, checkedInAt));
}

function checkinImagesInsertion(
  db: Database,
  {
    checkinId,
    imageIds,
    now
  }: { checkinId: number | SQL; imageIds: readonly number[]; now: string }
) {
  return chunks(imageIds, IMAGES_PER_INSERT).map((ids) =>
    db.insert(journeyCheckinImages).values(
      ids.map((imageId) => ({
        journeyCheckinId: checkinId,
        imageId,
        createdAt: now
      }))
    )
  );
}

export async function recordCheckin(
  db: Database,
  viewer: Viewer,
  {
    owner,
    changes
  }: { owner: JourneyOwner; changes: z.output<typeof newCheckinInput> }
): Promise<number> {
  const pinId = changes.pin_id;

  if (pinId === undefined) {
    throw new ApiError('NotFound');
  }

  const imageIds = changes.image_ids ?? [];
  const [[journey], [pin], imageOwners] = await db.batch([
    ownedJourneyQuery(db, owner),
    referenceablePinQuery(db, viewer, pinId),
    imageOwnersQuery(db, imageIds)
  ]);

  if (!journey || !pin) {
    throw new ApiError('NotFound');
  }

  const now = currentTimestamp();
  const checkedInAt = changes.checked_in_at ?? now;
  const editorId = viewer.id;

  assertValid([
    ...pinErrors(journey, pin),
    ...periodErrors(journey, checkedInAt)
  ]);
  assertValid(unownedImages(imageOwners, imageIds, editorId));

  const content: CheckinContent = {
    ...spotOf(pin),
    note: changes.note ?? null,
    checkedInAt,
    status: 'recorded'
  };
  const checkinId = scalar(
    db
      .select({ id: max(journeyCheckins.id).as('id') })
      .from(journeyCheckins)
      .where(eq(journeyCheckins.journeyId, journey.id))
  );

  const [inserted] = await db.batch([
    db
      .insert(journeyCheckins)
      .values({
        ...content,
        origin: changes.origin,
        journeyId: journey.id,
        createdAt: now,
        updatedAt: now
      })
      .returning({ id: journeyCheckins.id }),
    ...checkinImagesInsertion(db, { checkinId, imageIds, now })
  ]);

  return first(inserted).id;
}

export async function recordedCheckin(
  db: Database,
  { journeyId, checkinId }: { journeyId: number; checkinId: number }
): Promise<CheckinRow> {
  return first(
    await db
      .select()
      .from(journeyCheckins)
      .where(
        and(
          eq(journeyCheckins.id, checkinId),
          eq(journeyCheckins.journeyId, journeyId),
          recorded
        )
      )
  );
}

async function currentCheckinImageIds(
  db: Database,
  checkin: CheckinRow
): Promise<number[]> {
  const rows = await db
    .select({ id: journeyCheckinImages.imageId })
    .from(journeyCheckinImages)
    .where(eq(journeyCheckinImages.journeyCheckinId, checkin.id))
    .orderBy(asc(journeyCheckinImages.imageId));

  return rows.map((row) => row.id);
}

function currentCheckinContent(checkin: CheckinRow): CheckinContent {
  return {
    pinId: checkin.pinId,
    name: checkin.name,
    latitude: checkin.latitude,
    longitude: checkin.longitude,
    note: checkin.note,
    checkedInAt: checkin.checkedInAt,
    status: checkin.status === 'deleted' ? 'deleted' : 'recorded'
  };
}

type SubmittedImages = { imageIds: number[]; editorId: number };

async function replacedImages(
  db: Database,
  checkin: CheckinRow,
  submitted: SubmittedImages | undefined
): Promise<number[] | undefined> {
  if (
    submitted === undefined ||
    sameIds(submitted.imageIds, await currentCheckinImageIds(db, checkin))
  ) {
    return undefined;
  }

  assertValid(
    await unownedImageErrors(db, submitted.imageIds, submitted.editorId)
  );

  return submitted.imageIds;
}

async function writeCheckin(
  db: Database,
  checkin: CheckinRow,
  {
    content,
    submitted
  }: {
    content: CheckinContent;
    submitted?: SubmittedImages;
  }
): Promise<void> {
  const current = currentCheckinContent(checkin);
  const { pinId, name, latitude, longitude, ...details } = content;
  const changes = {
    ...changedColumns(current, details),
    ...(pinId === current.pinId ? {} : { pinId, name, latitude, longitude })
  };
  const replacement = await replacedImages(db, checkin, submitted);

  if (Object.keys(changes).length === 0 && replacement === undefined) {
    return;
  }

  const now = currentTimestamp();

  const [updated] = await db.batch([
    db
      .update(journeyCheckins)
      .set({ ...changes, updatedAt: now })
      .where(and(eq(journeyCheckins.id, checkin.id), recorded))
      .returning({ id: journeyCheckins.id }),
    ...(replacement === undefined
      ? []
      : [
          db
            .delete(journeyCheckinImages)
            .where(eq(journeyCheckinImages.journeyCheckinId, checkin.id)),
          ...checkinImagesInsertion(db, {
            checkinId: checkin.id,
            imageIds: replacement,
            now
          })
        ])
  ]);

  first(updated);
}

async function revisedSpot(
  db: Database,
  viewer: Viewer,
  {
    journey,
    checkin,
    current,
    submitted
  }: {
    journey: JourneyRecord;
    checkin: CheckinRow;
    current: CheckinSpot;
    submitted: number | string | undefined;
  }
): Promise<CheckinSpot> {
  if (submitted === undefined) {
    return current;
  }

  const pinId = optionalId(submitted);

  if (pinId === undefined) {
    throw new ApiError('NotFound');
  }

  if (pinId === current.pinId) {
    return current;
  }

  if (checkin.origin === 'tracked') {
    throw ApiError.invalid(['tracked_checkin_pin_fixed']);
  }

  const [pin] = await referenceablePinQuery(db, viewer, pinId);

  if (!pin) {
    throw new ApiError('NotFound');
  }

  assertValid(pinErrors(journey, pin));

  return spotOf(pin);
}

export async function reviseCheckin(
  db: Database,
  checkin: CheckinRow,
  {
    journey,
    viewer,
    changes
  }: {
    journey: JourneyRecord;
    viewer: Viewer;
    changes: z.output<typeof checkinInput>;
  }
): Promise<void> {
  const current = currentCheckinContent(checkin);
  const checkedInAt =
    changes.checked_in_at === undefined
      ? current.checkedInAt
      : changes.checked_in_at;

  if (checkedInAt !== current.checkedInAt) {
    assertWithinPeriod(journey, checkedInAt);
  }

  const spot = await revisedSpot(db, viewer, {
    journey,
    checkin,
    current,
    submitted: changes.pin_id
  });

  await writeCheckin(db, checkin, {
    content: {
      ...current,
      ...spot,
      note: changes.note === undefined ? current.note : changes.note,
      checkedInAt
    },
    submitted:
      changes.image_ids === undefined
        ? undefined
        : { imageIds: changes.image_ids, editorId: viewer.id }
  });
}

export async function discardCheckin(
  db: Database,
  checkin: CheckinRow
): Promise<void> {
  await writeCheckin(db, checkin, {
    content: { ...currentCheckinContent(checkin), status: 'deleted' }
  });
}
