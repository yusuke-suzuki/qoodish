CREATE TRIGGER `journey_checkins_interval_bi` BEFORE INSERT ON `journey_checkins`
WHEN new.`status` <> 'deleted' AND new.`pin_id` IS NOT NULL
BEGIN
  SELECT RAISE(ABORT, 'journey_checkin_interval') WHERE EXISTS (
    SELECT 1 FROM `journey_checkins`
    WHERE `journey_id` = new.`journey_id`
      AND `pin_id` = new.`pin_id`
      AND `status` <> 'deleted'
      AND round(abs(julianday(`checked_in_at`) - julianday(new.`checked_in_at`)) * 86400000) < 7200000
  );
END;--> statement-breakpoint
CREATE TRIGGER `journey_checkins_interval_bu` BEFORE UPDATE OF `checked_in_at`, `pin_id`, `status` ON `journey_checkins`
WHEN new.`status` <> 'deleted' AND new.`pin_id` IS NOT NULL
  AND (new.`checked_in_at` IS NOT old.`checked_in_at` OR new.`pin_id` IS NOT old.`pin_id` OR new.`status` IS NOT old.`status`)
BEGIN
  SELECT RAISE(ABORT, 'journey_checkin_interval') WHERE EXISTS (
    SELECT 1 FROM `journey_checkins`
    WHERE `id` <> new.`id`
      AND `journey_id` = new.`journey_id`
      AND `pin_id` = new.`pin_id`
      AND `status` <> 'deleted'
      AND round(abs(julianday(`checked_in_at`) - julianday(new.`checked_in_at`)) * 86400000) < 7200000
  );
END;
