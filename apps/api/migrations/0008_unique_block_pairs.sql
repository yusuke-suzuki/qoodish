DROP INDEX `index_blocks_on_blocker_id_and_blocked_id`;--> statement-breakpoint
CREATE UNIQUE INDEX `index_blocks_on_blocker_id_and_blocked_id` ON `blocks` (`blocker_id`,`blocked_id`);--> statement-breakpoint
DROP INDEX `index_mutes_on_muter_id_and_muted_id`;--> statement-breakpoint
CREATE UNIQUE INDEX `index_mutes_on_muter_id_and_muted_id` ON `mutes` (`muter_id`,`muted_id`);