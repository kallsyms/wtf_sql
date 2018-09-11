-- "Your scientists were so preoccupied with whether or not they could, they didn’t stop to think if they should."
-- Common cross-session tables

/*
Privs:
    * INSERT routes (NO UPDATE, DELETE)
*/

DROP TABLE IF EXISTS `responses`;
CREATE TABLE `responses` (
    `id` INT PRIMARY KEY AUTO_INCREMENT,
    `ts` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `route` VARCHAR(255),
    `code` INT NOT NULL
);

DROP TABLE IF EXISTS `routes`;
CREATE TABLE `routes` (
    `match` VARCHAR(255) PRIMARY KEY,
    `proc` VARCHAR(128)
);

DROP TABLE IF EXISTS `static_assets`;
CREATE TABLE `static_assets` (
    `path` VARCHAR(255) PRIMARY KEY,
    `data` TEXT
);

DROP TABLE IF EXISTS `templates`;
CREATE TABLE `templates` (
    `path` VARCHAR(255) PRIMARY KEY,
    `data` TEXT
);

DROP TABLE IF EXISTS `config`;
CREATE TABLE `config` (
    `name` VARCHAR(255) PRIMARY KEY,
    `value` TEXT
);
