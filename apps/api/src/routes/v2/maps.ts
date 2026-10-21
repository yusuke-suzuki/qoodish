import type { CountedMap, Journey } from '@qoodish/api-contract';
import { and, count, eq } from 'drizzle-orm';
import { Hono } from 'hono';
import { z } from 'zod';
import { inIds } from '../../db/client.ts';
import { journeys, maps, pins } from '../../db/schema.ts';
import { encryptionSecrets } from '../../encryption.ts';
import {
  createJourney,
  journeyDetail,
  newJourneyInput
} from '../../journeys.ts';
import { findMap, listedMaps, mapListQuery, viewerMaps } from '../../maps.ts';
import {
  authenticateUser,
  type ViewerEnv
} from '../../middleware/authenticate-user.ts';
import { id, jsonBody, pathParams } from '../../validation.ts';
import { referenceableMap, referenceablePin } from '../../visibility.ts';

const app = new Hono<ViewerEnv>();

app.use(authenticateUser);

app.get('/', mapListQuery, async (c) => {
  const db = c.get('db');
  const viewer = c.get('viewer');
  const rows = await listedMaps(db, viewer, c.req.valid('query'));
  const [listed, counts] = await Promise.all([
    viewerMaps(db, viewer, rows),
    rows.length === 0
      ? []
      : db
          .select({ mapId: pins.mapId, count: count().as('count') })
          .from(pins)
          .where(
            and(
              referenceablePin(viewer),
              inIds(
                pins.mapId,
                rows.map((row) => row.id)
              )
            )
          )
          .groupBy(pins.mapId)
  ]);
  const countsByMap = new Map(counts.map((row) => [row.mapId, row.count]));

  return c.json<CountedMap[]>(
    listed.map((map) => ({ ...map, pins_count: countsByMap.get(map.id) ?? 0 }))
  );
});

app.post(
  '/:mapId/journeys',
  pathParams(z.object({ mapId: id })),
  jsonBody(newJourneyInput),
  async (c) => {
    const db = c.get('db');
    const viewer = c.get('viewer');
    const map = await findMap(
      db,
      and(referenceableMap(viewer), eq(maps.id, c.req.valid('param').mapId))
    );
    const journeyId = await createJourney(db, {
      userId: viewer.id,
      mapId: map.id,
      period: c.req.valid('json')
    });

    return c.json<Journey>(
      await journeyDetail(
        db,
        eq(journeys.id, journeyId),
        encryptionSecrets(c.env)
      )
    );
  }
);

export default app;
