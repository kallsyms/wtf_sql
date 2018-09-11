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
