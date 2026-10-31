DELETE FROM blocks WHERE id IN (SELECT block_id FROM unblocks);
DELETE FROM blocks WHERE id NOT IN (SELECT min(id) FROM blocks GROUP BY blocker_id, blocked_id);
DELETE FROM mutes WHERE id IN (SELECT mute_id FROM unmutes);
DELETE FROM mutes WHERE id NOT IN (SELECT min(id) FROM mutes GROUP BY muter_id, muted_id);
