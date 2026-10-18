import { env } from 'cloudflare:test';
import { beforeAll, describe, expect, it } from 'vitest';
import { idsOf, send } from '../../test/client.ts';
import { ids, seedWorld } from '../../test/world.ts';

beforeAll(async () => {
  await seedWorld(env.DB);
});

const invalid = (detail: string) => ({
  status: 422,
  body: { title: 'UnprocessableContent', detail }
});

describe('POST /v2/maps/:mapId/journeys', () => {
  const create = (body: unknown, uid = 'alice', mapId: number = ids.ramen) =>
    send('POST', `/v2/maps/${mapId}/journeys`, uid, body);

  it('records a past journey with its period, beside an unfinished one', async () => {
    const planned = await create({});

    expect(planned).toMatchObject({
      status: 200,
      body: { map_id: ids.ramen, started_at: null, finished_at: null }
    });
    expect(await create({})).toEqual(
      invalid('An unfinished journey already exists on this map.')
    );

    const past = await create({
      started_at: '2026-05-01T09:00:00+09:00',
      finished_at: '2026-05-03 18:30:00Z'
    });

    expect(past).toMatchObject({
      status: 200,
      body: {
        map_id: ids.ramen,
        started_at: '2026-05-01T00:00:00.000000Z',
        finished_at: '2026-05-03T18:30:00.000000Z',
        milestones: [],
        checkins: [],
        encoded_path: null
      }
    });

    const checkIn = (checkedInAt: string) =>
      send('POST', `/me/journeys/${past.body.id}/checkins`, 'alice', {
        pin_id: ids.shoyu,
        checked_in_at: checkedInAt
      });

    expect((await checkIn('2026-05-02T12:00:00Z')).status).toBe(200);
    expect(await checkIn('2026-05-04T12:00:00Z')).toEqual(
      invalid('The checkin time is outside the journey period.')
    );
    expect(await idsOf('/me/journeys', 'alice')).toEqual([
      planned.body.id,
      past.body.id
    ]);
  });

  it('rejects a period that is incomplete, reversed or in the future', async () => {
    const periodInvalid = invalid('The journey must start before it finishes.');

    expect(await create({ started_at: '2026-05-01T09:00:00Z' })).toEqual(
      periodInvalid
    );
    expect(
      await create({
        started_at: '2026-05-03T09:00:00Z',
        finished_at: '2026-05-01T09:00:00Z'
      })
    ).toEqual(periodInvalid);
    expect(
      await create({
        started_at: '2026-05-01T09:00:00Z',
        finished_at: '2026-05-01T09:00:00Z'
      })
    ).toEqual(periodInvalid);
    expect(
      await create({ started_at: 'yesterday', finished_at: '2026-05-01' })
    ).toEqual(periodInvalid);
    expect(
      await create({
        started_at: '2026-05-01T09:00:00Z',
        finished_at: '2999-01-01T00:00:00Z'
      })
    ).toEqual(invalid('The journey cannot finish in the future.'));
  });

  it('tolerates a client clock running a few minutes ahead', async () => {
    const minutesFromNow = (minutes: number) =>
      new Date(Date.now() + minutes * 60_000).toISOString();

    expect(
      (
        await create({
          started_at: minutesFromNow(-60),
          finished_at: minutesFromNow(2)
        })
      ).status
    ).toBe(200);
    expect(
      await create({
        started_at: minutesFromNow(-60),
        finished_at: minutesFromNow(10)
      })
    ).toEqual(invalid('The journey cannot finish in the future.'));
  });

  it('answers 404 for a map the viewer may not see', async () => {
    const period = {
      started_at: '2026-05-01T09:00:00Z',
      finished_at: '2026-05-02T09:00:00Z'
    };

    expect((await create(period, 'bob', ids.secret)).status).toBe(404);
    expect((await create(period, 'bob', 999)).status).toBe(404);
  });
});
