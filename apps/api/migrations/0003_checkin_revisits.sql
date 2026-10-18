DROP INDEX `index_journey_checkins_on_journey_id_and_pin_id`;--> statement-breakpoint
CREATE INDEX `index_journey_checkins_on_journey_id_and_pin_id` ON `journey_checkins` (`journey_id`,`pin_id`);