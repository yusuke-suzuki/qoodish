import { env } from 'cloudflare:test';
import { asc } from 'drizzle-orm';
import { beforeAll, expect, it } from 'vitest';
import { database } from '../src/db/client.ts';
import { blocks, mutes, unblocks, unmutes } from '../src/db/schema.ts';
import { runScript } from '../src/test/scripts.ts';
import { at, ids, seedWorld } from '../src/test/world.ts';
import script from './delete-lifted-blocks-and-mutes.sql?raw';

const db = () => database(env.DB);

beforeAll(async () => {
  await seedWorld(env.DB);
});

async function seedBlocks() {
  const [lifted, onlyLifted] = await db()
    .insert(blocks)
    .values([
      { blockerId: ids.alice, blockedId: ids.carol, createdAt: at(1) },
      { blockerId: ids.carol, blockedId: ids.alice, createdAt: at(1) },
      { blockerId: ids.alice, blockedId: ids.bob, createdAt: at(1) },
      { blockerId: ids.bob, blockedId: ids.carol, createdAt: at(1) },
      { blockerId: ids.bob, blockedId: ids.carol, createdAt: at(2) },
      { blockerId: ids.alice, blockedId: ids.carol, createdAt: at(3) }
    ])
    .returning({ id: blocks.id });

  await db()
    .insert(unblocks)
    .values([
      { blockId: lifted.id, createdAt: at(2) },
      { blockId: onlyLifted.id, createdAt: at(2) }
    ]);
}

async function seedMutes() {
  const [lifted, onlyLifted] = await db()
    .insert(mutes)
    .values([
      { muterId: ids.alice, mutedId: ids.carol, createdAt: at(1) },
      { muterId: ids.carol, mutedId: ids.alice, createdAt: at(1) },
      { muterId: ids.alice, mutedId: ids.bob, createdAt: at(1) },
      { muterId: ids.bob, mutedId: ids.carol, createdAt: at(1) },
      { muterId: ids.bob, mutedId: ids.carol, createdAt: at(2) },
      { muterId: ids.alice, mutedId: ids.carol, createdAt: at(3) }
    ])
    .returning({ id: mutes.id });

  await db()
    .insert(unmutes)
    .values([
      { muteId: lifted.id, createdAt: at(2) },
      { muteId: onlyLifted.id, createdAt: at(2) }
    ]);
}

function blockPairs() {
  return db()
    .select({
      blockerId: blocks.blockerId,
      blockedId: blocks.blockedId,
      createdAt: blocks.createdAt
    })
    .from(blocks)
    .orderBy(asc(blocks.id));
}

function mutePairs() {
  return db()
    .select({
      muterId: mutes.muterId,
      mutedId: mutes.mutedId,
      createdAt: mutes.createdAt
    })
    .from(mutes)
    .orderBy(asc(mutes.id));
}

async function expectOnePairEach() {
  expect(await blockPairs()).toEqual([
    { blockerId: ids.alice, blockedId: ids.bob, createdAt: at(1) },
    { blockerId: ids.bob, blockedId: ids.carol, createdAt: at(1) },
    { blockerId: ids.alice, blockedId: ids.carol, createdAt: at(3) }
  ]);
  expect(await mutePairs()).toEqual([
    { muterId: ids.alice, mutedId: ids.bob, createdAt: at(1) },
    { muterId: ids.bob, mutedId: ids.carol, createdAt: at(1) },
    { muterId: ids.alice, mutedId: ids.carol, createdAt: at(3) }
  ]);
  expect(await db().select().from(unblocks)).toEqual([]);
  expect(await db().select().from(unmutes)).toEqual([]);
}

it('keeps the earliest block and mute in effect per pair, also when run again', async () => {
  await seedBlocks();
  await seedMutes();

  await runScript(script);
  await expectOnePairEach();

  await runScript(script);
  await expectOnePairEach();
});
