import { and, eq } from 'drizzle-orm';
import {
  currentTimestamp,
  type Database,
  generatedId,
  selected
} from './db/client.ts';
import { mutes, users } from './db/schema.ts';
import { ApiError } from './errors.ts';

export async function muteUser(
  db: Database,
  { muterId, mutedId }: { muterId: number; mutedId: number }
): Promise<void> {
  if (muterId === mutedId) {
    throw ApiError.invalid(['mute_self']);
  }

  await db
    .insert(mutes)
    .select(
      db
        .select({
          id: generatedId(),
          createdAt: selected(currentTimestamp(), 'created_at'),
          mutedId: users.id,
          muterId: selected(muterId, 'muter_id')
        })
        .from(users)
        .where(eq(users.id, mutedId))
    )
    .onConflictDoNothing();
}

export async function unmuteUser(
  db: Database,
  { muterId, mutedId }: { muterId: number; mutedId: number }
): Promise<void> {
  await db
    .delete(mutes)
    .where(and(eq(mutes.muterId, muterId), eq(mutes.mutedId, mutedId)));
}
