DELETE FROM `journey_checkin_revisions`;--> statement-breakpoint
DELETE FROM `pin_property_option_revisions`;--> statement-breakpoint
DELETE FROM `pin_property_revisions`;--> statement-breakpoint
CREATE TABLE `__saved_sequences` AS SELECT `name`, `seq` FROM `sqlite_sequence` WHERE `name` IN ('journey_checkins', 'pin_properties', 'pin_property_options');--> statement-breakpoint
CREATE TABLE `__saved_journey_checkin_images` AS SELECT * FROM `journey_checkin_images`;--> statement-breakpoint
CREATE TABLE `__saved_pin_revision_property_options` AS SELECT * FROM `pin_revision_property_options`;--> statement-breakpoint
CREATE TABLE `__saved_pin_property_options` AS SELECT "id", "pin_property_id", "name", "position", "status", "created_at", "updated_at" FROM `pin_property_options`;--> statement-breakpoint
CREATE TABLE `__new_journey_checkins` (
	`id` integer PRIMARY KEY AUTOINCREMENT NOT NULL,
	`checked_in_at` text NOT NULL,
	`created_at` text NOT NULL,
	`journey_id` integer NOT NULL,
	`latitude` real NOT NULL,
	`longitude` real NOT NULL,
	`name` text NOT NULL,
	`note` text,
	`origin` text DEFAULT 'tracked' NOT NULL,
	`pin_id` integer,
	`status` text DEFAULT 'recorded' NOT NULL,
	`updated_at` text NOT NULL,
	FOREIGN KEY (`journey_id`) REFERENCES `journeys`(`id`) ON UPDATE no action ON DELETE no action,
	FOREIGN KEY (`pin_id`) REFERENCES `pins`(`id`) ON UPDATE no action ON DELETE no action
);
--> statement-breakpoint
INSERT INTO `__new_journey_checkins`("id", "checked_in_at", "created_at", "journey_id", "latitude", "longitude", "name", "note", "origin", "pin_id", "status", "updated_at") SELECT "id", "checked_in_at", "created_at", "journey_id", "latitude", "longitude", "name", "note", "origin", "pin_id", "status", "updated_at" FROM `journey_checkins`;--> statement-breakpoint
CREATE TABLE `__new_pin_properties` (
	`id` integer PRIMARY KEY AUTOINCREMENT NOT NULL,
	`map_id` integer NOT NULL,
	`name` text NOT NULL,
	`position` integer DEFAULT 0 NOT NULL,
	`multiple` integer DEFAULT false NOT NULL,
	`status` text DEFAULT 'published' NOT NULL,
	`created_at` text NOT NULL,
	`updated_at` text NOT NULL,
	FOREIGN KEY (`map_id`) REFERENCES `maps`(`id`) ON UPDATE no action ON DELETE no action
);
--> statement-breakpoint
INSERT INTO `__new_pin_properties`("id", "map_id", "name", "position", "multiple", "status", "created_at", "updated_at") SELECT "id", "map_id", "name", "position", "multiple", "status", "created_at", "updated_at" FROM `pin_properties`;--> statement-breakpoint
DELETE FROM `journey_checkin_images`;--> statement-breakpoint
DELETE FROM `pin_revision_property_options`;--> statement-breakpoint
DROP TABLE `pin_property_options`;--> statement-breakpoint
DROP TABLE `pin_properties`;--> statement-breakpoint
DROP TABLE `journey_checkins`;--> statement-breakpoint
ALTER TABLE `__new_journey_checkins` RENAME TO `journey_checkins`;--> statement-breakpoint
ALTER TABLE `__new_pin_properties` RENAME TO `pin_properties`;--> statement-breakpoint
CREATE TABLE `pin_property_options` (
	`id` integer PRIMARY KEY AUTOINCREMENT NOT NULL,
	`pin_property_id` integer NOT NULL,
	`name` text NOT NULL,
	`position` integer DEFAULT 0 NOT NULL,
	`status` text DEFAULT 'published' NOT NULL,
	`created_at` text NOT NULL,
	`updated_at` text NOT NULL,
	FOREIGN KEY (`pin_property_id`) REFERENCES `pin_properties`(`id`) ON UPDATE no action ON DELETE no action
);
--> statement-breakpoint
INSERT INTO `pin_property_options` SELECT * FROM `__saved_pin_property_options`;--> statement-breakpoint
DROP TABLE `journey_checkin_revisions`;--> statement-breakpoint
DROP TABLE `pin_property_option_revisions`;--> statement-breakpoint
DROP TABLE `pin_property_revisions`;--> statement-breakpoint
CREATE INDEX `index_journey_checkins_on_journey_id_and_pin_id` ON `journey_checkins` (`journey_id`,`pin_id`);--> statement-breakpoint
CREATE INDEX `index_journey_checkins_on_pin_id` ON `journey_checkins` (`pin_id`);--> statement-breakpoint
CREATE INDEX `index_pin_properties_on_map_id` ON `pin_properties` (`map_id`);--> statement-breakpoint
CREATE INDEX `index_pin_property_options_on_pin_property_id` ON `pin_property_options` (`pin_property_id`);--> statement-breakpoint
INSERT INTO `journey_checkin_images` SELECT * FROM `__saved_journey_checkin_images`;--> statement-breakpoint
INSERT INTO `pin_revision_property_options` SELECT * FROM `__saved_pin_revision_property_options`;--> statement-breakpoint
DELETE FROM `sqlite_sequence` WHERE `name` IN (SELECT `name` FROM `__saved_sequences`);--> statement-breakpoint
INSERT INTO `sqlite_sequence` (`name`, `seq`) SELECT `name`, `seq` FROM `__saved_sequences`;--> statement-breakpoint
DROP TABLE `__saved_sequences`;--> statement-breakpoint
DROP TABLE `__saved_journey_checkin_images`;--> statement-breakpoint
DROP TABLE `__saved_pin_revision_property_options`;--> statement-breakpoint
DROP TABLE `__saved_pin_property_options`;
