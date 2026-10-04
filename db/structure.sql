
/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;
DROP TABLE IF EXISTS `ar_internal_metadata`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `ar_internal_metadata` (
  `key` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `value` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `created_at` datetime(6) NOT NULL,
  `updated_at` datetime(6) NOT NULL,
  PRIMARY KEY (`key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `blocks`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `blocks` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `blocked_id` bigint NOT NULL,
  `blocker_id` bigint NOT NULL,
  `created_at` datetime(6) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `index_blocks_on_blocked_id` (`blocked_id`),
  KEY `index_blocks_on_blocker_id_and_blocked_id` (`blocker_id`,`blocked_id`),
  CONSTRAINT `fk_blocks_blocked_id` FOREIGN KEY (`blocked_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_blocks_blocker_id` FOREIGN KEY (`blocker_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `bookmarks`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `bookmarks` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `created_at` datetime(6) NOT NULL,
  `map_id` bigint NOT NULL,
  `updated_at` datetime(6) NOT NULL,
  `user_id` bigint NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_bookmarks_on_map_id_and_user_id` (`map_id`,`user_id`),
  KEY `index_bookmarks_on_map_id` (`map_id`),
  KEY `index_bookmarks_on_user_id` (`user_id`),
  CONSTRAINT `fk_rails_2c0d39b33f` FOREIGN KEY (`map_id`) REFERENCES `maps` (`id`),
  CONSTRAINT `fk_rails_c1ff6fa4ac` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `chapter_revision_images`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `chapter_revision_images` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `chapter_revision_id` bigint NOT NULL,
  `created_at` datetime(6) NOT NULL,
  `image_id` bigint NOT NULL,
  `updated_at` datetime(6) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_on_chapter_revision_id_image_id_9e3b64d6f1` (`chapter_revision_id`,`image_id`),
  KEY `index_chapter_revision_images_on_chapter_revision_id` (`chapter_revision_id`),
  KEY `index_chapter_revision_images_on_image_id` (`image_id`),
  CONSTRAINT `fk_rails_19dc8fb849` FOREIGN KEY (`image_id`) REFERENCES `images` (`id`),
  CONSTRAINT `fk_rails_95a4fd07d2` FOREIGN KEY (`chapter_revision_id`) REFERENCES `chapter_revisions` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `chapter_revisions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `chapter_revisions` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `chapter_id` bigint NOT NULL,
  `content` json NOT NULL,
  `created_at` datetime(6) NOT NULL,
  `map_features` json NOT NULL,
  `status` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL DEFAULT 'draft',
  `title` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `updated_at` datetime(6) NOT NULL,
  `user_id` bigint NOT NULL,
  PRIMARY KEY (`id`),
  KEY `index_chapter_revisions_on_chapter_id_and_id` (`chapter_id`,`id`),
  KEY `index_chapter_revisions_on_chapter_id` (`chapter_id`),
  KEY `index_chapter_revisions_on_user_id` (`user_id`),
  CONSTRAINT `fk_rails_b57929191e` FOREIGN KEY (`chapter_id`) REFERENCES `chapters` (`id`),
  CONSTRAINT `fk_rails_fcc72d6b6f` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `chapters`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `chapters` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `content` json NOT NULL,
  `created_at` datetime(6) NOT NULL,
  `current_revision_id` bigint DEFAULT NULL,
  `journey_id` bigint DEFAULT NULL,
  `map_features` json NOT NULL,
  `map_id` bigint DEFAULT NULL,
  `status` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL DEFAULT 'draft',
  `title` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `updated_at` datetime(6) NOT NULL,
  `user_id` bigint NOT NULL,
  `content_text` mediumtext COLLATE utf8mb4_general_ci GENERATED ALWAYS AS (json_unquote(json_extract(`content`,_utf8mb4'$**.text'))) STORED,
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_chapters_on_journey_id` (`journey_id`),
  KEY `index_chapters_on_current_revision_id` (`current_revision_id`),
  KEY `index_chapters_on_map_id` (`map_id`),
  KEY `index_chapters_on_status_and_created_at` (`status`,`created_at`),
  KEY `index_chapters_on_user_id_and_status` (`user_id`,`status`),
  FULLTEXT KEY `index_chapters_on_title_and_content_text` (`title`,`content_text`) /*!50100 WITH PARSER `ngram` */ ,
  CONSTRAINT `fk_chapters_current_revision_id` FOREIGN KEY (`current_revision_id`) REFERENCES `chapter_revisions` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_rails_227ce80201` FOREIGN KEY (`map_id`) REFERENCES `maps` (`id`),
  CONSTRAINT `fk_rails_b5e9549ad2` FOREIGN KEY (`journey_id`) REFERENCES `journeys` (`id`),
  CONSTRAINT `fk_rails_ca7ffbce5f` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `coauthorship_invitations`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `coauthorship_invitations` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `created_at` datetime(6) NOT NULL,
  `invitee_id` bigint NOT NULL,
  `inviter_id` bigint NOT NULL,
  `map_id` bigint NOT NULL,
  `status` int NOT NULL DEFAULT '0',
  `updated_at` datetime(6) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `index_coauthorship_invitations_on_invitee_id_and_status` (`invitee_id`,`status`),
  KEY `index_coauthorship_invitations_on_invitee_id` (`invitee_id`),
  KEY `index_coauthorship_invitations_on_inviter_id` (`inviter_id`),
  KEY `index_coauthorship_invitations_on_map_id_and_invitee_id` (`map_id`,`invitee_id`),
  KEY `index_coauthorship_invitations_on_map_id` (`map_id`),
  CONSTRAINT `fk_rails_1631a8d4e9` FOREIGN KEY (`map_id`) REFERENCES `maps` (`id`),
  CONSTRAINT `fk_rails_3cea8e66e8` FOREIGN KEY (`inviter_id`) REFERENCES `users` (`id`),
  CONSTRAINT `fk_rails_534c82981e` FOREIGN KEY (`invitee_id`) REFERENCES `users` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `coauthorships`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `coauthorships` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `created_at` datetime(6) NOT NULL,
  `map_id` bigint NOT NULL,
  `updated_at` datetime(6) NOT NULL,
  `user_id` bigint NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_coauthorships_on_map_id_and_user_id` (`map_id`,`user_id`),
  KEY `index_coauthorships_on_map_id` (`map_id`),
  KEY `index_coauthorships_on_user_id` (`user_id`),
  CONSTRAINT `fk_rails_544840f0e4` FOREIGN KEY (`map_id`) REFERENCES `maps` (`id`),
  CONSTRAINT `fk_rails_9f0ddc29ef` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `comment_revisions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `comment_revisions` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `body` text CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `comment_id` bigint NOT NULL,
  `created_at` datetime(6) NOT NULL,
  `status` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL DEFAULT 'published',
  `updated_at` datetime(6) NOT NULL,
  `user_id` bigint NOT NULL,
  PRIMARY KEY (`id`),
  KEY `index_comment_revisions_on_comment_id_and_id` (`comment_id`,`id`),
  KEY `index_comment_revisions_on_comment_id` (`comment_id`),
  KEY `index_comment_revisions_on_user_id` (`user_id`),
  CONSTRAINT `fk_rails_9fb700ae23` FOREIGN KEY (`comment_id`) REFERENCES `comments` (`id`),
  CONSTRAINT `fk_rails_cbef51d260` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `comments`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `comments` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `body` text CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `commentable_id` bigint NOT NULL,
  `commentable_type` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `created_at` datetime(6) NOT NULL,
  `current_revision_id` bigint DEFAULT NULL,
  `status` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL DEFAULT 'published',
  `updated_at` datetime(6) NOT NULL,
  `user_id` bigint NOT NULL,
  PRIMARY KEY (`id`),
  KEY `index_comments_on_commentable_type_and_commentable_id` (`commentable_type`,`commentable_id`),
  KEY `index_comments_on_current_revision_id` (`current_revision_id`),
  KEY `index_comments_on_user_id` (`user_id`),
  CONSTRAINT `fk_comments_current_revision_id` FOREIGN KEY (`current_revision_id`) REFERENCES `comment_revisions` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `devices`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `devices` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `created_at` datetime(6) NOT NULL,
  `registration_token` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `updated_at` datetime(6) NOT NULL,
  `user_id` bigint NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_devices_on_user_id_and_registration_token` (`user_id`,`registration_token`),
  KEY `index_devices_on_registration_token` (`registration_token`),
  KEY `index_devices_on_user_id` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `featured_maps`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `featured_maps` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `created_at` datetime(6) NOT NULL,
  `map_id` bigint NOT NULL,
  `updated_at` datetime(6) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `index_featured_maps_on_created_at_and_map_id` (`created_at`,`map_id`),
  KEY `index_featured_maps_on_map_id` (`map_id`),
  CONSTRAINT `fk_rails_2fc0ddeb18` FOREIGN KEY (`map_id`) REFERENCES `maps` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `images`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `images` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `created_at` datetime(6) NOT NULL,
  `updated_at` datetime(6) NOT NULL,
  `url` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `user_id` bigint NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_images_on_url` (`url`),
  KEY `index_images_on_user_id` (`user_id`),
  CONSTRAINT `fk_rails_19cd822056` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `journal_bookmarks`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `journal_bookmarks` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `created_at` datetime(6) NOT NULL,
  `journal_id` bigint NOT NULL,
  `updated_at` datetime(6) NOT NULL,
  `user_id` bigint NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_journal_bookmarks_on_journal_id_and_user_id` (`journal_id`,`user_id`),
  KEY `index_journal_bookmarks_on_journal_id` (`journal_id`),
  KEY `index_journal_bookmarks_on_user_id` (`user_id`),
  CONSTRAINT `fk_rails_16cf7d9555` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`),
  CONSTRAINT `fk_rails_1e28fe512e` FOREIGN KEY (`journal_id`) REFERENCES `journals` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `journal_revisions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `journal_revisions` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `created_at` datetime(6) NOT NULL,
  `description` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `journal_id` bigint NOT NULL,
  `title` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `updated_at` datetime(6) NOT NULL,
  `user_id` bigint NOT NULL,
  PRIMARY KEY (`id`),
  KEY `index_journal_revisions_on_journal_id_and_id` (`journal_id`,`id`),
  KEY `index_journal_revisions_on_journal_id` (`journal_id`),
  KEY `index_journal_revisions_on_user_id` (`user_id`),
  CONSTRAINT `fk_rails_3278373085` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`),
  CONSTRAINT `fk_rails_de71c3288c` FOREIGN KEY (`journal_id`) REFERENCES `journals` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `journals`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `journals` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `created_at` datetime(6) NOT NULL,
  `current_revision_id` bigint DEFAULT NULL,
  `description` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `title` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `updated_at` datetime(6) NOT NULL,
  `user_id` bigint NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_journals_on_user_id` (`user_id`),
  KEY `index_journals_on_current_revision_id` (`current_revision_id`),
  CONSTRAINT `fk_journals_current_revision_id` FOREIGN KEY (`current_revision_id`) REFERENCES `journal_revisions` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_rails_1f2015adde` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `journey_checkin_revision_images`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `journey_checkin_revision_images` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `created_at` datetime(6) NOT NULL,
  `image_id` bigint NOT NULL,
  `journey_checkin_revision_id` bigint NOT NULL,
  `updated_at` datetime(6) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_checkin_revision_images_on_revision_id_and_image_id` (`journey_checkin_revision_id`,`image_id`),
  KEY `index_journey_checkin_revision_images_on_image_id` (`image_id`),
  KEY `idx_on_journey_checkin_revision_id_79ea77d6c2` (`journey_checkin_revision_id`),
  CONSTRAINT `fk_rails_174f290b70` FOREIGN KEY (`journey_checkin_revision_id`) REFERENCES `journey_checkin_revisions` (`id`),
  CONSTRAINT `fk_rails_abd2268643` FOREIGN KEY (`image_id`) REFERENCES `images` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `journey_checkin_revisions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `journey_checkin_revisions` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `checked_in_at` datetime(6) NOT NULL,
  `created_at` datetime(6) NOT NULL,
  `journey_checkin_id` bigint NOT NULL,
  `note` text CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci,
  `status` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL DEFAULT 'recorded',
  `updated_at` datetime(6) NOT NULL,
  `user_id` bigint NOT NULL,
  PRIMARY KEY (`id`),
  KEY `index_journey_checkin_revisions_on_journey_checkin_id_and_id` (`journey_checkin_id`,`id`),
  KEY `index_journey_checkin_revisions_on_journey_checkin_id` (`journey_checkin_id`),
  KEY `index_journey_checkin_revisions_on_user_id` (`user_id`),
  CONSTRAINT `fk_rails_52832966a8` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`),
  CONSTRAINT `fk_rails_c5f5bdd3a8` FOREIGN KEY (`journey_checkin_id`) REFERENCES `journey_checkins` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `journey_checkins`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `journey_checkins` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `checked_in_at` datetime(6) NOT NULL,
  `created_at` datetime(6) NOT NULL,
  `current_revision_id` bigint DEFAULT NULL,
  `journey_id` bigint NOT NULL,
  `latitude` decimal(16,6) NOT NULL,
  `longitude` decimal(16,6) NOT NULL,
  `name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `note` text CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci,
  `pin_id` bigint DEFAULT NULL,
  `status` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL DEFAULT 'recorded',
  `updated_at` datetime(6) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_journey_checkins_on_journey_id_and_pin_id` (`journey_id`,`pin_id`),
  KEY `index_journey_checkins_on_current_revision_id` (`current_revision_id`),
  KEY `index_journey_checkins_on_pin_id` (`pin_id`),
  CONSTRAINT `fk_journey_checkins_current_revision_id` FOREIGN KEY (`current_revision_id`) REFERENCES `journey_checkin_revisions` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_rails_0d440e8bad` FOREIGN KEY (`journey_id`) REFERENCES `journeys` (`id`),
  CONSTRAINT `fk_rails_ee27fafe59` FOREIGN KEY (`pin_id`) REFERENCES `pins` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `journeys`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `journeys` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `created_at` datetime(6) NOT NULL,
  `encoded_path` mediumtext CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci,
  `finished_at` datetime(6) DEFAULT NULL,
  `map_id` bigint DEFAULT NULL,
  `started_at` datetime(6) DEFAULT NULL,
  `updated_at` datetime(6) NOT NULL,
  `user_id` bigint NOT NULL,
  PRIMARY KEY (`id`),
  KEY `index_journeys_on_map_id` (`map_id`),
  KEY `index_journeys_on_user_id_and_map_id_and_finished_at` (`user_id`,`map_id`,`finished_at`),
  CONSTRAINT `fk_rails_25c20fde60` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`),
  CONSTRAINT `fk_rails_65731bb809` FOREIGN KEY (`map_id`) REFERENCES `maps` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `map_revision_images`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `map_revision_images` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `created_at` datetime(6) NOT NULL,
  `image_id` bigint NOT NULL,
  `map_revision_id` bigint NOT NULL,
  `updated_at` datetime(6) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_map_revision_images_on_map_revision_id_and_image_id` (`map_revision_id`,`image_id`),
  KEY `index_map_revision_images_on_image_id` (`image_id`),
  KEY `index_map_revision_images_on_map_revision_id` (`map_revision_id`),
  CONSTRAINT `fk_rails_7c26becf6c` FOREIGN KEY (`map_revision_id`) REFERENCES `map_revisions` (`id`),
  CONSTRAINT `fk_rails_a3f2bee281` FOREIGN KEY (`image_id`) REFERENCES `images` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `map_revisions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `map_revisions` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `created_at` datetime(6) NOT NULL,
  `description` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `latitude` decimal(16,6) NOT NULL,
  `longitude` decimal(16,6) NOT NULL,
  `map_id` bigint NOT NULL,
  `name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `private` tinyint(1) NOT NULL DEFAULT '1',
  `status` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL DEFAULT 'published',
  `updated_at` datetime(6) NOT NULL,
  `user_id` bigint DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_map_revisions_on_map_id_and_id` (`map_id`,`id`),
  KEY `index_map_revisions_on_map_id` (`map_id`),
  KEY `index_map_revisions_on_user_id` (`user_id`),
  CONSTRAINT `fk_rails_09a8f15035` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`),
  CONSTRAINT `fk_rails_4b0f20a54a` FOREIGN KEY (`map_id`) REFERENCES `maps` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `maps`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `maps` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `base_id_val` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `base_name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `created_at` datetime(6) NOT NULL,
  `current_revision_id` bigint DEFAULT NULL,
  `description` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `invitable` tinyint(1) DEFAULT '0',
  `latitude` decimal(16,6) NOT NULL DEFAULT '0.000000',
  `longitude` decimal(16,6) NOT NULL DEFAULT '0.000000',
  `name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `private` tinyint(1) DEFAULT '1',
  `shared` tinyint(1) DEFAULT '0',
  `status` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL DEFAULT 'published',
  `updated_at` datetime(6) NOT NULL,
  `user_id` bigint NOT NULL,
  PRIMARY KEY (`id`),
  KEY `index_maps_on_current_revision_id` (`current_revision_id`),
  KEY `index_maps_on_status_and_created_at` (`status`,`created_at`),
  KEY `index_maps_on_user_id` (`user_id`),
  FULLTEXT KEY `index_maps_on_name_and_description` (`name`,`description`) /*!50100 WITH PARSER `ngram` */ ,
  CONSTRAINT `fk_maps_current_revision_id` FOREIGN KEY (`current_revision_id`) REFERENCES `map_revisions` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_rails_4ab1ab6be6` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `milestones`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `milestones` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `created_at` datetime(6) NOT NULL,
  `journey_id` bigint NOT NULL,
  `latitude` decimal(16,6) NOT NULL,
  `longitude` decimal(16,6) NOT NULL,
  `name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `pin_id` bigint DEFAULT NULL,
  `position` int NOT NULL,
  `updated_at` datetime(6) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_milestones_on_journey_id_and_pin_id` (`journey_id`,`pin_id`),
  KEY `index_milestones_on_journey_id_and_position` (`journey_id`,`position`),
  KEY `index_milestones_on_pin_id` (`pin_id`),
  CONSTRAINT `fk_rails_017f147689` FOREIGN KEY (`journey_id`) REFERENCES `journeys` (`id`),
  CONSTRAINT `fk_rails_5fd3ed2e92` FOREIGN KEY (`pin_id`) REFERENCES `pins` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `moderation_decisions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `moderation_decisions` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `author_id` bigint DEFAULT NULL,
  `content_snapshot` text CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci,
  `created_at` datetime(6) NOT NULL,
  `moderatable_id` bigint NOT NULL,
  `moderatable_type` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `moderator_id` bigint DEFAULT NULL,
  `outcome` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `reason` text CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `reviewed_revision_id` bigint DEFAULT NULL,
  `staff_member_id` bigint DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_moderation_decisions_on_author_id` (`author_id`),
  KEY `index_moderation_decisions_on_moderatable_and_time` (`moderatable_type`,`moderatable_id`,`created_at`),
  KEY `index_moderation_decisions_on_moderator_id` (`moderator_id`),
  KEY `index_moderation_decisions_on_staff_member_id` (`staff_member_id`),
  CONSTRAINT `fk_rails_2ae52ee4d0` FOREIGN KEY (`author_id`) REFERENCES `users` (`id`),
  CONSTRAINT `fk_rails_a33845338a` FOREIGN KEY (`staff_member_id`) REFERENCES `staff_members` (`id`),
  CONSTRAINT `fk_rails_e31c3d1fc0` FOREIGN KEY (`moderator_id`) REFERENCES `users` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `mutes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `mutes` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `created_at` datetime(6) NOT NULL,
  `muted_id` bigint NOT NULL,
  `muter_id` bigint NOT NULL,
  PRIMARY KEY (`id`),
  KEY `index_mutes_on_muted_id` (`muted_id`),
  KEY `index_mutes_on_muter_id_and_muted_id` (`muter_id`,`muted_id`),
  CONSTRAINT `fk_mutes_muted_id` FOREIGN KEY (`muted_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_mutes_muter_id` FOREIGN KEY (`muter_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `notifications`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `notifications` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `created_at` datetime(6) NOT NULL,
  `key` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `notifiable_id` bigint DEFAULT NULL,
  `notifiable_type` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `notifier_id` bigint DEFAULT NULL,
  `notifier_type` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `read` tinyint(1) DEFAULT '0',
  `recipient_id` bigint DEFAULT NULL,
  `recipient_type` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `updated_at` datetime(6) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `index_notifications_on_notifiable_id_and_notifiable_type` (`notifiable_id`,`notifiable_type`),
  KEY `index_notifications_on_notifiable_type_and_notifiable_id` (`notifiable_type`,`notifiable_id`),
  KEY `index_notifications_on_notifier_id_and_notifier_type` (`notifier_id`,`notifier_type`),
  KEY `index_notifications_on_notifier_type_and_notifier_id` (`notifier_type`,`notifier_id`),
  KEY `index_notifications_on_recipient_id_and_recipient_type` (`recipient_id`,`recipient_type`),
  KEY `index_notifications_on_recipient_type_and_recipient_id` (`recipient_type`,`recipient_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `pin_properties`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `pin_properties` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `map_id` bigint NOT NULL,
  `name` varchar(255) COLLATE utf8mb4_general_ci NOT NULL,
  `position` int NOT NULL DEFAULT '0',
  `multiple` tinyint(1) NOT NULL DEFAULT '0',
  `status` varchar(255) COLLATE utf8mb4_general_ci NOT NULL DEFAULT 'published',
  `created_at` datetime(6) NOT NULL,
  `updated_at` datetime(6) NOT NULL,
  `current_revision_id` bigint DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_pin_properties_on_map_id` (`map_id`),
  KEY `index_pin_properties_on_current_revision_id` (`current_revision_id`),
  CONSTRAINT `fk_rails_7aa3d21401` FOREIGN KEY (`current_revision_id`) REFERENCES `pin_property_revisions` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_rails_fae93bc161` FOREIGN KEY (`map_id`) REFERENCES `maps` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `pin_property_option_revisions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `pin_property_option_revisions` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `pin_property_option_id` bigint NOT NULL,
  `user_id` bigint DEFAULT NULL,
  `name` varchar(255) COLLATE utf8mb4_general_ci NOT NULL,
  `position` int NOT NULL,
  `status` varchar(255) COLLATE utf8mb4_general_ci NOT NULL DEFAULT 'published',
  `created_at` datetime(6) NOT NULL,
  `updated_at` datetime(6) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `index_pin_property_option_revisions_on_pin_property_option_id` (`pin_property_option_id`),
  KEY `index_pin_property_option_revisions_on_user_id` (`user_id`),
  KEY `idx_on_pin_property_option_id_id_cd060b3bcd` (`pin_property_option_id`,`id`),
  CONSTRAINT `fk_rails_15b9c08085` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_rails_2779a33909` FOREIGN KEY (`pin_property_option_id`) REFERENCES `pin_property_options` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `pin_property_options`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `pin_property_options` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `pin_property_id` bigint NOT NULL,
  `name` varchar(255) COLLATE utf8mb4_general_ci NOT NULL,
  `position` int NOT NULL DEFAULT '0',
  `status` varchar(255) COLLATE utf8mb4_general_ci NOT NULL DEFAULT 'published',
  `created_at` datetime(6) NOT NULL,
  `updated_at` datetime(6) NOT NULL,
  `current_revision_id` bigint DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_pin_property_options_on_pin_property_id` (`pin_property_id`),
  KEY `index_pin_property_options_on_current_revision_id` (`current_revision_id`),
  CONSTRAINT `fk_rails_6c5501d9b4` FOREIGN KEY (`current_revision_id`) REFERENCES `pin_property_option_revisions` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_rails_6db8616e90` FOREIGN KEY (`pin_property_id`) REFERENCES `pin_properties` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `pin_property_revisions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `pin_property_revisions` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `pin_property_id` bigint NOT NULL,
  `user_id` bigint DEFAULT NULL,
  `name` varchar(255) COLLATE utf8mb4_general_ci NOT NULL,
  `position` int NOT NULL,
  `status` varchar(255) COLLATE utf8mb4_general_ci NOT NULL DEFAULT 'published',
  `created_at` datetime(6) NOT NULL,
  `updated_at` datetime(6) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `index_pin_property_revisions_on_pin_property_id` (`pin_property_id`),
  KEY `index_pin_property_revisions_on_user_id` (`user_id`),
  KEY `index_pin_property_revisions_on_pin_property_id_and_id` (`pin_property_id`,`id`),
  CONSTRAINT `fk_rails_af07909f81` FOREIGN KEY (`pin_property_id`) REFERENCES `pin_properties` (`id`),
  CONSTRAINT `fk_rails_ed5042ae90` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `pin_revision_images`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `pin_revision_images` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `created_at` datetime(6) NOT NULL,
  `image_id` bigint NOT NULL,
  `pin_revision_id` bigint NOT NULL,
  `updated_at` datetime(6) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_pin_revision_images_on_pin_revision_id_and_image_id` (`pin_revision_id`,`image_id`),
  KEY `index_pin_revision_images_on_image_id` (`image_id`),
  KEY `index_pin_revision_images_on_pin_revision_id` (`pin_revision_id`),
  CONSTRAINT `fk_rails_30dccb4e7c` FOREIGN KEY (`image_id`) REFERENCES `images` (`id`),
  CONSTRAINT `fk_rails_6d4f867f43` FOREIGN KEY (`pin_revision_id`) REFERENCES `pin_revisions` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `pin_revision_property_options`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `pin_revision_property_options` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `pin_revision_id` bigint NOT NULL,
  `pin_property_option_id` bigint NOT NULL,
  `created_at` datetime(6) NOT NULL,
  `updated_at` datetime(6) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_on_pin_revision_id_pin_property_option_id_e17f1d524a` (`pin_revision_id`,`pin_property_option_id`),
  KEY `index_pin_revision_property_options_on_pin_revision_id` (`pin_revision_id`),
  KEY `index_pin_revision_property_options_on_pin_property_option_id` (`pin_property_option_id`),
  CONSTRAINT `fk_rails_7551758728` FOREIGN KEY (`pin_property_option_id`) REFERENCES `pin_property_options` (`id`),
  CONSTRAINT `fk_rails_b19c669733` FOREIGN KEY (`pin_revision_id`) REFERENCES `pin_revisions` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `pin_revisions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `pin_revisions` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `comment` text CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `created_at` datetime(6) NOT NULL,
  `latitude` decimal(16,6) NOT NULL,
  `longitude` decimal(16,6) NOT NULL,
  `name` text CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `pin_id` bigint NOT NULL,
  `status` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL DEFAULT 'published',
  `updated_at` datetime(6) NOT NULL,
  `user_id` bigint NOT NULL,
  PRIMARY KEY (`id`),
  KEY `index_pin_revisions_on_pin_id_and_id` (`pin_id`,`id`),
  KEY `index_pin_revisions_on_pin_id` (`pin_id`),
  KEY `index_pin_revisions_on_user_id` (`user_id`),
  CONSTRAINT `fk_rails_2f1db096b0` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`),
  CONSTRAINT `fk_rails_90ea29948c` FOREIGN KEY (`pin_id`) REFERENCES `pins` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `pins`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `pins` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `comment` text CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `created_at` datetime(6) NOT NULL,
  `current_revision_id` bigint DEFAULT NULL,
  `latitude` decimal(16,6) NOT NULL,
  `longitude` decimal(16,6) NOT NULL,
  `map_id` bigint NOT NULL,
  `name` text CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `spot_id` bigint DEFAULT NULL,
  `status` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL DEFAULT 'published',
  `updated_at` datetime(6) NOT NULL,
  `user_id` bigint NOT NULL,
  PRIMARY KEY (`id`),
  KEY `index_pins_on_created_at` (`created_at`),
  KEY `index_pins_on_current_revision_id` (`current_revision_id`),
  KEY `index_pins_on_map_id` (`map_id`),
  KEY `index_pins_on_status_and_created_at` (`status`,`created_at`),
  KEY `index_pins_on_user_id` (`user_id`),
  FULLTEXT KEY `index_pins_on_name_and_comment` (`name`,`comment`) /*!50100 WITH PARSER `ngram` */ ,
  CONSTRAINT `fk_pins_current_revision_id` FOREIGN KEY (`current_revision_id`) REFERENCES `pin_revisions` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_rails_51b0c024f1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`),
  CONSTRAINT `fk_rails_717eb8a1a6` FOREIGN KEY (`map_id`) REFERENCES `maps` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `reports`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `reports` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `category` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `content_snapshot` text CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci,
  `created_at` datetime(6) NOT NULL,
  `details` text CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci,
  `locale` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `moderatable_id` bigint NOT NULL,
  `moderatable_type` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `reported_revision_id` bigint DEFAULT NULL,
  `reporter_id` bigint DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_reports_on_moderatable` (`moderatable_type`,`moderatable_id`),
  KEY `index_reports_on_reporter_id` (`reporter_id`),
  CONSTRAINT `fk_rails_c4cb6e6463` FOREIGN KEY (`reporter_id`) REFERENCES `users` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `role_permissions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `role_permissions` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `created_at` datetime(6) NOT NULL,
  `permission` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `role_id` bigint NOT NULL,
  `updated_at` datetime(6) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_role_permissions_on_role_id_and_permission` (`role_id`,`permission`),
  CONSTRAINT `fk_rails_60126080bd` FOREIGN KEY (`role_id`) REFERENCES `roles` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `roles`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `roles` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `created_at` datetime(6) NOT NULL,
  `description` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `updated_at` datetime(6) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_roles_on_name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `schema_migrations`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `schema_migrations` (
  `version` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  PRIMARY KEY (`version`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `staff_member_roles`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `staff_member_roles` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `created_at` datetime(6) NOT NULL,
  `role_id` bigint NOT NULL,
  `staff_member_id` bigint NOT NULL,
  `updated_at` datetime(6) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_staff_member_roles_on_staff_member_id_and_role_id` (`staff_member_id`,`role_id`),
  KEY `index_staff_member_roles_on_role_id` (`role_id`),
  CONSTRAINT `fk_rails_077ebc2c02` FOREIGN KEY (`staff_member_id`) REFERENCES `staff_members` (`id`),
  CONSTRAINT `fk_rails_68fc77497b` FOREIGN KEY (`role_id`) REFERENCES `roles` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `staff_members`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `staff_members` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `created_at` datetime(6) NOT NULL,
  `email` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `revoked_at` datetime(6) DEFAULT NULL,
  `updated_at` datetime(6) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_staff_members_on_email` (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `unblocks`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `unblocks` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `block_id` bigint NOT NULL,
  `created_at` datetime(6) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_unblocks_on_block_id` (`block_id`),
  CONSTRAINT `fk_rails_85f565cf75` FOREIGN KEY (`block_id`) REFERENCES `blocks` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `unmutes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `unmutes` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `created_at` datetime(6) NOT NULL,
  `mute_id` bigint NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_unmutes_on_mute_id` (`mute_id`),
  CONSTRAINT `fk_rails_a64f926098` FOREIGN KEY (`mute_id`) REFERENCES `mutes` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `user_preferences`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `user_preferences` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `created_at` datetime(6) NOT NULL,
  `updated_at` datetime(6) NOT NULL,
  `user_id` bigint NOT NULL,
  `web_push` json NOT NULL,
  PRIMARY KEY (`id`),
  KEY `index_user_preferences_on_user_id` (`user_id`),
  CONSTRAINT `fk_rails_a69bfcfd81` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `user_revisions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `user_revisions` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `biography` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `created_at` datetime(6) NOT NULL,
  `name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `updated_at` datetime(6) NOT NULL,
  `user_id` bigint NOT NULL,
  PRIMARY KEY (`id`),
  KEY `index_user_revisions_on_user_id_and_id` (`user_id`,`id`),
  KEY `index_user_revisions_on_user_id` (`user_id`),
  CONSTRAINT `fk_rails_b23700559c` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `users` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `biography` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `created_at` datetime(6) NOT NULL,
  `current_revision_id` bigint DEFAULT NULL,
  `email` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `image_id` bigint DEFAULT NULL,
  `locale` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `uid` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `updated_at` datetime(6) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_users_on_uid` (`uid`),
  KEY `index_users_on_current_revision_id` (`current_revision_id`),
  KEY `index_users_on_image_id` (`image_id`),
  FULLTEXT KEY `index_users_on_name` (`name`) /*!50100 WITH PARSER `ngram` */ ,
  CONSTRAINT `fk_rails_47c7c64b36` FOREIGN KEY (`image_id`) REFERENCES `images` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_users_current_revision_id` FOREIGN KEY (`current_revision_id`) REFERENCES `user_revisions` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `votes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `votes` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `created_at` datetime(6) NOT NULL,
  `updated_at` datetime(6) NOT NULL,
  `votable_id` bigint DEFAULT NULL,
  `votable_type` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `vote_flag` tinyint(1) DEFAULT NULL,
  `vote_scope` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `vote_weight` int DEFAULT NULL,
  `voter_id` bigint DEFAULT NULL,
  `voter_type` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_votes_on_votable_and_voter` (`votable_type`,`votable_id`,`voter_type`,`voter_id`),
  KEY `index_votes_on_votable_id_and_votable_type_and_vote_scope` (`votable_id`,`votable_type`,`vote_scope`),
  KEY `index_votes_on_votable_type_and_votable_id` (`votable_type`,`votable_id`),
  KEY `index_votes_on_voter_id_and_voter_type_and_vote_scope` (`voter_id`,`voter_type`,`vote_scope`),
  KEY `index_votes_on_voter_type_and_voter_id` (`voter_type`,`voter_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

INSERT INTO `schema_migrations` (version) VALUES
('20261004004236'),
('20261004004235'),
('20261004004231'),
('20261004004228'),
('20261004004224'),
('20261004004221'),
('20261004004218'),
('20261003232736'),
('20261002152648'),
('20261002045305'),
('20261001164544'),
('20260928230444'),
('20260928230443'),
('20260928171758'),
('20260928171753'),
('20260927164425'),
('20260926172813'),
('20260926145115'),
('20260926031008'),
('20260926031007'),
('20260926031006'),
('20260926031005'),
('20260926031004'),
('20260924034943'),
('20260923102408'),
('20260922000001'),
('20260921010004'),
('20260921010003'),
('20260921010002'),
('20260921010001'),
('20260921000006'),
('20260921000005'),
('20260921000004'),
('20260921000003'),
('20260921000002'),
('20260921000001'),
('20260920000012'),
('20260920000011'),
('20260920000010'),
('20260920000009'),
('20260920000008'),
('20260920000007'),
('20260920000006'),
('20260920000005'),
('20260920000004'),
('20260920000003'),
('20260920000002'),
('20260920000001'),
('20260919000004'),
('20260919000003'),
('20260919000002'),
('20260919000001'),
('20260811032237'),
('20260728160209'),
('20260728065006'),
('20260726144020'),
('20260724170000'),
('20260723114052'),
('20260723040613'),
('20260723040610'),
('20260720102542'),
('20260719172202'),
('20260719125538'),
('20260713043049'),
('20260713043047'),
('20260713043046'),
('20260713043035'),
('20260623010032'),
('20260623010030'),
('20260620210612'),
('20260620210611'),
('20260620210610'),
('20260620210609'),
('20260614104139'),
('20260520063537'),
('20231214051127'),
('20231108143416'),
('20231105090816'),
('20231105011256'),
('20231104131944'),
('20230917084320'),
('20220731083040'),
('20210211063444'),
('20201129141625'),
('20201129133236'),
('20201129105952'),
('20201129044356'),
('20200614091031'),
('20200614091013'),
('20200614090950'),
('20200614090918'),
('20200614090255'),
('20200614085730'),
('20200413154721'),
('20200411090857'),
('20200406144810'),
('20200202090741'),
('20190714100814'),
('20190317041543'),
('20190317030446'),
('20181216060157'),
('20181208071824'),
('20181122080626'),
('20180806062008'),
('20180806054847'),
('20180806053336'),
('20180804124320'),
('20180804054204'),
('20180311144911'),
('20171213063648'),
('20171211143203'),
('20170901041457'),
('20170826055656'),
('20170817040207'),
('20170813152955'),
('20170812154700'),
('20170812131748');

