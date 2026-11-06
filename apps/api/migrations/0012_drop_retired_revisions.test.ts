import { applyD1Migrations, env } from 'cloudflare:test';
import { beforeAll, describe, expect, it } from 'vitest';

const db = env.MIGRATION_DB;
const migration = env.TEST_MIGRATIONS.findIndex((m) =>
  m.name.startsWith('0012_')
);
const now = '2026-01-01T00:00:00Z';

async function rows(sql: string): Promise<Record<string, unknown>[]> {
  return (await db.prepare(sql).all()).results;
}

async function run(...statements: string[]): Promise<void> {
  await db.batch(statements.map((sql) => db.prepare(sql)));
}

beforeAll(async () => {
  await applyD1Migrations(db, env.TEST_MIGRATIONS.slice(0, migration));
  await run(
    `INSERT INTO users (id, created_at, uid, updated_at) VALUES (1, '${now}', 'u', '${now}')`,
    `INSERT INTO images (id, created_at, updated_at, url, user_id) VALUES (1, '${now}', '${now}', 'a', 1), (2, '${now}', '${now}', 'b', 1)`,
    `INSERT INTO maps (id, created_at, description, name, updated_at, user_id) VALUES (1, '${now}', '', 'm', '${now}', 1)`,
    `INSERT INTO pins (id, comment, created_at, latitude, longitude, map_id, name, updated_at, user_id) VALUES (1, '', '${now}', 1, 2, 1, 'p', '${now}', 1)`,
    `INSERT INTO pin_revisions (id, comment, created_at, latitude, longitude, name, pin_id, updated_at, user_id) VALUES (1, '', '${now}', 1, 2, 'p', 1, '${now}', 1)`,
    `INSERT INTO journeys (id, created_at, updated_at, user_id) VALUES (1, '${now}', '${now}', 1)`,
    `INSERT INTO journey_checkins (id, checked_in_at, created_at, journey_id, latitude, longitude, name, note, origin, pin_id, updated_at) VALUES (1, '${now}', '${now}', 1, 1, 2, 'a', 'n', 'manual', 1, '${now}'), (7, '${now}', '${now}', 1, 3, 4, 'b', NULL, 'tracked', NULL, '${now}'), (9, '${now}', '${now}', 1, 5, 6, 'c', NULL, 'tracked', NULL, '${now}')`,
    'DELETE FROM journey_checkins WHERE id = 9',
    `INSERT INTO journey_checkin_images (id, created_at, image_id, journey_checkin_id) VALUES (1, '${now}', 1, 1), (2, '${now}', 2, 1), (3, '${now}', 2, 7)`,
    `INSERT INTO pin_properties (id, map_id, name, position, multiple, created_at, updated_at) VALUES (1, 1, 'heat', 0, 1, '${now}', '${now}'), (2, 1, 'mood', 1, 0, '${now}', '${now}')`,
    `INSERT INTO pin_property_options (id, pin_property_id, name, position, created_at, updated_at) VALUES (1, 1, 'hot', 0, '${now}', '${now}'), (2, 1, 'mild', 1, '${now}', '${now}'), (3, 2, 'calm', 0, '${now}', '${now}')`,
    `INSERT INTO pin_revision_property_options (id, pin_revision_id, pin_property_option_id, created_at, updated_at) VALUES (1, 1, 1, '${now}', '${now}'), (2, 1, 3, '${now}', '${now}')`,
    `INSERT INTO pin_properties (id, map_id, name, created_at, updated_at) VALUES (3, 1, 'gone', '${now}', '${now}')`,
    `INSERT INTO pin_property_options (id, pin_property_id, name, created_at, updated_at) VALUES (4, 1, 'gone', '${now}', '${now}')`,
    'DELETE FROM pin_property_options WHERE id = 4',
    'DELETE FROM pin_properties WHERE id = 3',
    `INSERT INTO journey_checkin_revisions (id, checked_in_at, created_at, journey_checkin_id, updated_at, user_id) VALUES (1, '${now}', '${now}', 1, '${now}', 1)`,
    `INSERT INTO pin_property_revisions (id, pin_property_id, name, position, created_at, updated_at) VALUES (1, 1, 'heat', 0, '${now}', '${now}')`,
    `INSERT INTO pin_property_option_revisions (id, pin_property_option_id, name, position, created_at, updated_at) VALUES (1, 1, 'hot', 0, '${now}', '${now}')`,
    'UPDATE journey_checkins SET current_revision_id = 1 WHERE id = 1',
    'UPDATE pin_properties SET current_revision_id = 1 WHERE id = 1',
    'UPDATE pin_property_options SET current_revision_id = 1 WHERE id = 1'
  );
  await applyD1Migrations(db, env.TEST_MIGRATIONS.slice(0, migration + 1));
});

describe('0012_drop_retired_revisions', () => {
  it('drops the retired revision tables and the columns that pointed at them', async () => {
    expect(
      await rows(
        "SELECT name FROM sqlite_master WHERE type = 'table' AND (name IN ('journey_checkin_revisions', 'pin_property_revisions', 'pin_property_option_revisions') OR name GLOB '__*')"
      )
    ).toEqual([]);

    for (const table of [
      'journey_checkins',
      'pin_properties',
      'pin_property_options'
    ]) {
      expect(
        (await rows(`PRAGMA table_info(${table})`)).map((c) => c.name)
      ).not.toContain('current_revision_id');
    }
  });

  it('keeps every row of the rebuilt tables and of the tables that reference them', async () => {
    expect(
      await rows(
        'SELECT id, name, note, origin, pin_id FROM journey_checkins ORDER BY id'
      )
    ).toEqual([
      { id: 1, name: 'a', note: 'n', origin: 'manual', pin_id: 1 },
      { id: 7, name: 'b', note: null, origin: 'tracked', pin_id: null }
    ]);
    expect(
      await rows(
        'SELECT id, image_id, journey_checkin_id FROM journey_checkin_images ORDER BY id'
      )
    ).toEqual([
      { id: 1, image_id: 1, journey_checkin_id: 1 },
      { id: 2, image_id: 2, journey_checkin_id: 1 },
      { id: 3, image_id: 2, journey_checkin_id: 7 }
    ]);
    expect(
      await rows('SELECT id, name, multiple FROM pin_properties ORDER BY id')
    ).toEqual([
      { id: 1, name: 'heat', multiple: 1 },
      { id: 2, name: 'mood', multiple: 0 }
    ]);
    expect(
      await rows(
        'SELECT id, pin_property_id, name, position FROM pin_property_options ORDER BY id'
      )
    ).toEqual([
      { id: 1, pin_property_id: 1, name: 'hot', position: 0 },
      { id: 2, pin_property_id: 1, name: 'mild', position: 1 },
      { id: 3, pin_property_id: 2, name: 'calm', position: 0 }
    ]);
    expect(
      await rows(
        'SELECT id, pin_revision_id, pin_property_option_id FROM pin_revision_property_options ORDER BY id'
      )
    ).toEqual([
      { id: 1, pin_revision_id: 1, pin_property_option_id: 1 },
      { id: 2, pin_revision_id: 1, pin_property_option_id: 3 }
    ]);
  });

  it('keeps the autoincrement sequences, so a deleted id is not reused', async () => {
    expect(
      await rows(
        "SELECT name, seq FROM sqlite_sequence WHERE name IN ('journey_checkins', 'pin_properties', 'pin_property_options') ORDER BY name"
      )
    ).toEqual([
      { name: 'journey_checkins', seq: 9 },
      { name: 'pin_properties', seq: 3 },
      { name: 'pin_property_options', seq: 4 }
    ]);
  });

  it('keeps the foreign keys of the rebuilt tables and of the tables that reference them', async () => {
    expect(await rows('PRAGMA foreign_key_check')).toEqual([]);

    await expect(
      run(
        `INSERT INTO pin_property_options (pin_property_id, name, created_at, updated_at) VALUES (99, 'x', '${now}', '${now}')`
      )
    ).rejects.toThrow(/FOREIGN KEY/);
    await expect(
      run('DELETE FROM pin_property_options WHERE id = 1')
    ).rejects.toThrow(/FOREIGN KEY/);
    await expect(
      run('DELETE FROM pin_properties WHERE id = 1')
    ).rejects.toThrow(/FOREIGN KEY/);

    await run(
      `INSERT INTO journey_checkins (id, checked_in_at, created_at, journey_id, latitude, longitude, name, updated_at) VALUES (8, '${now}', '${now}', 1, 0, 0, 'e', '${now}')`,
      `INSERT INTO journey_checkin_images (created_at, image_id, journey_checkin_id) VALUES ('${now}', 1, 8)`,
      'DELETE FROM journey_checkins WHERE id = 8'
    );
    expect(
      await rows(
        'SELECT id FROM journey_checkin_images WHERE journey_checkin_id = 8'
      )
    ).toEqual([]);
  });
});
