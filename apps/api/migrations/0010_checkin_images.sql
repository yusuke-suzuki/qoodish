CREATE TABLE `journey_checkin_images` (
	`id` integer PRIMARY KEY AUTOINCREMENT NOT NULL,
	`created_at` text NOT NULL,
	`image_id` integer NOT NULL,
	`journey_checkin_id` integer NOT NULL,
	FOREIGN KEY (`image_id`) REFERENCES `images`(`id`) ON UPDATE no action ON DELETE cascade,
	FOREIGN KEY (`journey_checkin_id`) REFERENCES `journey_checkins`(`id`) ON UPDATE no action ON DELETE cascade
);
--> statement-breakpoint
CREATE UNIQUE INDEX `index_journey_checkin_images_on_checkin_id_and_image_id` ON `journey_checkin_images` (`journey_checkin_id`,`image_id`);--> statement-breakpoint
CREATE INDEX `index_journey_checkin_images_on_image_id` ON `journey_checkin_images` (`image_id`);