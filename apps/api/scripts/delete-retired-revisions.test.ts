import { env } from 'cloudflare:test';
import { eq } from 'drizzle-orm';
import { beforeAll, expect, it } from 'vitest';
import { database } from '../src/db/client.ts';
import {
  journeyCheckinImages,
  journeyCheckinRevisionImages,
  journeyCheckinRevisions,
  journeyCheckins,
  pinProperties,
  pinPropertyOptionRevisions,
  pinPropertyOptions,
  pinPropertyRevisions
} from '../src/db/schema.ts';
import { checkinImage, seedMe } from '../src/test/me.ts';
import { runScript } from '../src/test/scripts.ts';
import { at, ids, seedWorld } from '../src/test/world.ts';
import script from './delete-retired-revisions.sql?raw';

const db = () => database(env.DB);

beforeAll(async () => {
  await seedWorld(env.DB);
  await seedMe(env.DB);
});

function deleteRetiredRevisions() {
  return runScript(script);
}

async function revisePinTags() {
  const stamp = { createdAt: at(2), updatedAt: at(2) };
  const [propertyRevision] = await db()
    .insert(pinPropertyRevisions)
    .values({ pinPropertyId: ids.taste, name: 'Taste', position: 0, ...stamp })
    .returning({ id: pinPropertyRevisions.id });
  const [optionRevision] = await db()
    .insert(pinPropertyOptionRevisions)
    .values({
      pinPropertyOptionId: ids.sweet,
      name: 'Sweet',
      position: 0,
      ...stamp
    })
    .returning({ id: pinPropertyOptionRevisions.id });

  await db()
    .update(pinProperties)
    .set({ currentRevisionId: propertyRevision.id })
    .where(eq(pinProperties.id, ids.taste));
  await db()
    .update(pinPropertyOptions)
    .set({ currentRevisionId: optionRevision.id })
    .where(eq(pinPropertyOptions.id, ids.sweet));
}

async function foreignKeyViolations() {
  const { results } = await env.DB.prepare('PRAGMA foreign_key_check').all();

  return results;
}

it('deletes the revisions of checkins and pin tags and keeps what they describe', async () => {
  await revisePinTags();

  await deleteRetiredRevisions();

  expect(await db().select().from(journeyCheckinRevisionImages)).toEqual([]);
  expect(await db().select().from(journeyCheckinRevisions)).toEqual([]);
  expect(await db().select().from(pinPropertyOptionRevisions)).toEqual([]);
  expect(await db().select().from(pinPropertyRevisions)).toEqual([]);
  expect(
    await db()
      .select({
        id: journeyCheckins.id,
        currentRevisionId: journeyCheckins.currentRevisionId
      })
      .from(journeyCheckins)
      .where(eq(journeyCheckins.id, 3))
  ).toEqual([{ id: 3, currentRevisionId: null }]);
  expect(
    await db()
      .select({
        journeyCheckinId: journeyCheckinImages.journeyCheckinId,
        imageId: journeyCheckinImages.imageId
      })
      .from(journeyCheckinImages)
  ).toEqual([{ journeyCheckinId: 3, imageId: checkinImage }]);
  expect(
    await db()
      .select({
        name: pinProperties.name,
        currentRevisionId: pinProperties.currentRevisionId
      })
      .from(pinProperties)
      .where(eq(pinProperties.id, ids.taste))
  ).toEqual([{ name: 'Taste', currentRevisionId: null }]);
  expect(
    await db()
      .select({
        name: pinPropertyOptions.name,
        currentRevisionId: pinPropertyOptions.currentRevisionId
      })
      .from(pinPropertyOptions)
      .where(eq(pinPropertyOptions.id, ids.sweet))
  ).toEqual([{ name: 'Sweet', currentRevisionId: null }]);
  expect(await foreignKeyViolations()).toEqual([]);

  await deleteRetiredRevisions();

  expect(await foreignKeyViolations()).toEqual([]);
});
