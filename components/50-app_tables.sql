DROP TABLE IF EXISTS `posts`;
DROP TABLE IF EXISTS `users`;

CREATE TABLE `users` (
    `id` INT PRIMARY KEY AUTO_INCREMENT,
    `email` VARCHAR(255) UNIQUE,
    `name` VARCHAR(255),
    `pass_hash` VARCHAR(255)
);

CREATE TABLE `posts` (
    `id` INT PRIMARY KEY AUTO_INCREMENT,
    `user_id` INT NOT NULL,
    `posted` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `text` TEXT,

    FOREIGN KEY (user_id) REFERENCES users(id)
);

DROP TABLE IF EXISTS `banned_post_patterns`;
CREATE TABLE `banned_post_patterns` (
    `pattern` TEXT
);

INSERT INTO `banned_post_patterns` VALUES ('fuck'),
    ('shit'),
    ('piss'),
    ('tiennamen square'),
    ('winnie the pooh'),
    ('zucced'),
    ('bad challenge'),
    ('\\$\\{config_[a-zA-Z0-9_ ]+\\}');

