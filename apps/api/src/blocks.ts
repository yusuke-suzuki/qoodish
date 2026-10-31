import { and, eq } from 'drizzle-orm';
import { removeBookmarksBetween } from './bookmarks.ts';
import { declineInvitationsBetween } from './coauthorship-invitations.ts';
import {
  currentTimestamp,
  type Database,
  generatedId,
  selected
} from './db/client.ts';
import { blocks, users } from './db/schema.ts';
import { ApiError } from './errors.ts';
import { removeCoauthorshipsBetween } from './maps.ts';

export async function blockUser(
  db: Database,
  { blockerId, blockedId }: { blockerId: number; blockedId: number }
): Promise<void> {
  if (blockerId === blockedId) {
    throw ApiError.invalid(['block_self']);
  }

  const now = currentTimestamp();
  const pair = [blockerId, blockedId] as const;

  await db.batch([
    db
      .insert(blocks)
      .select(
        db
          .select({
            id: generatedId(),
            blockedId: users.id,
            blockerId: selected(blockerId, 'blocker_id'),
            createdAt: selected(now, 'created_at')
          })
          .from(users)
          .where(eq(users.id, blockedId))
      )
      .onConflictDoNothing(),
    ...removeBookmarksBetween(db, pair),
    removeCoauthorshipsBetween(db, pair),
    declineInvitationsBetween(db, pair, now)
  ]);
}

export async function unblockUser(
  db: Database,
  { blockerId, blockedId }: { blockerId: number; blockedId: number }
): Promise<void> {
  await db
    .delete(blocks)
    .where(
      and(eq(blocks.blockerId, blockerId), eq(blocks.blockedId, blockedId))
    );
}
