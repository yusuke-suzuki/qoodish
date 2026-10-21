ALTER TABLE `journey_checkin_revisions` ADD `latitude` real;--> statement-breakpoint
ALTER TABLE `journey_checkin_revisions` ADD `longitude` real;--> statement-breakpoint
ALTER TABLE `journey_checkin_revisions` ADD `name` text;--> statement-breakpoint
ALTER TABLE `journey_checkin_revisions` ADD `pin_id` integer REFERENCES pins(id);--> statement-breakpoint
CREATE INDEX `index_journey_checkin_revisions_on_pin_id` ON `journey_checkin_revisions` (`pin_id`);