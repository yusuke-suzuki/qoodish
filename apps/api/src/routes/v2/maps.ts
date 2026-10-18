import type { Journey } from '@qoodish/api-contract';
import { and, eq } from 'drizzle-orm';
import { Hono } from 'hono';
import { z } from 'zod';
import { journeys, maps } from '../../db/schema.ts';
import { encryptionSecrets } from '../../encryption.ts';
import {
  createJourney,
  journeyDetail,
  newJourneyInput
} from '../../journeys.ts';
import { findMap } from '../../maps.ts';
import {
  authenticateUser,
  type ViewerEnv
} from '../../middleware/authenticate-user.ts';
import { id, jsonBody, pathParams } from '../../validation.ts';
import { referenceableMap } from '../../visibility.ts';

const app = new Hono<ViewerEnv>();

app.use(authenticateUser);

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
