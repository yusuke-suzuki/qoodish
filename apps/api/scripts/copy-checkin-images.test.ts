import { env } from 'cloudflare:test';
import { asc, eq } from 'drizzle-orm';
import { beforeAll, expect, it } from 'vitest';
import { database } from '../src/db/client.ts';
import {
  journeyCheckinImages,
  journeyCheckinRevisionImages,
  journeyCheckinRevisions,
  journeyCheckins
} from '../src/db/schema.ts';
import { checkinImage, seedMe } from '../src/test/me.ts';
import { runScript } from '../src/test/scripts.ts';
import { at, ids, seedWorld } from '../src/test/world.ts';
import script from './copy-checkin-images.sql?raw';

const db = () => database(env.DB);

beforeAll(async () => {
  await seedWorld(env.DB);
  await seedMe(env.DB);
});

function copyCheckinImages() {
  return runScript(script);
}

async function reviseCheckin() {
  const revision = (id: number) => ({
    id,
    journeyCheckinId: 1,
    userId: ids.alice,
    checkedInAt: at(5, 10),
    note: 'Note 1',
    createdAt: at(id),
    updatedAt: at(id)
  });

  await db()
    .insert(journeyCheckinRevisions)
    .values([revision(2), revision(3)]);
  await db()
    .insert(journeyCheckinRevisionImages)
    .values([
      { journeyCheckinRevisionId: 2, imageId: ids.shoyuImage, ...stamp(2) },
      { journeyCheckinRevisionId: 3, imageId: checkinImage, ...stamp(3) }
    ]);
  await db()
    .update(journeyCheckins)
    .set({ currentRevisionId: 3 })
    .where(eq(journeyCheckins.id, 1));
}

function stamp(day: number) {
  return { createdAt: at(day), updatedAt: at(day) };
}

function checkinImagePairs() {
  return db()
    .select({
      journeyCheckinId: journeyCheckinImages.journeyCheckinId,
      imageId: journeyCheckinImages.imageId,
      createdAt: journeyCheckinImages.createdAt
    })
    .from(journeyCheckinImages)
    .orderBy(asc(journeyCheckinImages.journeyCheckinId));
}

it('replaces the images of every checkin with those of its current revision', async () => {
  await reviseCheckin();
  await db().delete(journeyCheckinImages);
  await db()
    .insert(journeyCheckinImages)
    .values([
      { journeyCheckinId: 1, imageId: ids.shoyuImage, createdAt: at(2) },
      { journeyCheckinId: 2, imageId: ids.shoyuImage, createdAt: at(2) }
    ]);

  await copyCheckinImages();

  const copied = [
    { journeyCheckinId: 1, imageId: checkinImage, createdAt: at(3) },
    { journeyCheckinId: 3, imageId: checkinImage, createdAt: at(1) }
  ];

  expect(await checkinImagePairs()).toEqual(copied);

  await copyCheckinImages();

  expect(await checkinImagePairs()).toEqual(copied);
});
