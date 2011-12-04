CREATE TABLE IF NOT EXISTS `user_auth` (
  `type_id` tinyint(1) unsigned NOT NULL DEFAULT '0',
  `identification` varchar(128) NOT NULL DEFAULT '',
  `user_id` int(11) unsigned NOT NULL DEFAULT '0',
  `raw_data` text,
  PRIMARY KEY (`type_id`,`identification`)
) DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `user` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(64) DEFAULT 'guest',
  `email` varchar(128) DEFAULT NULL,
  `visited_at` int(11) unsigned NOT NULL DEFAULT '0',
  `signed_at` int(11) unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`)
) DEFAULT CHARSET=utf8;

/* App WhereILive */
CREATE TABLE IF NOT EXISTS `app_wil_place` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `type_id` tinyint(1) unsigned NOT NULL DEFAULT '0',
  `text` varchar(128) NOT NULL DEFAULT '',
  PRIMARY KEY (`id`)
) DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `app_wil_user_place` (
  `user_id` int(11) unsigned NOT NULL,
  `place_id` int(11) unsigned NOT NULL,
  `inserted_at` int(11) unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`user_id`,`place_id`)
);