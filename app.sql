# "Your scientists were so preoccupied with whether or not they could, they didn’t stop to think if they should."
# Nick Gregory 2018

DROP TABLE IF EXISTS `responses`;
CREATE TABLE `responses` (
    `id` INT PRIMARY KEY AUTO_INCREMENT,
    `ts` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `route` VARCHAR(255),
    `code` INT NOT NULL
);

DROP TABLE IF EXISTS `routes`;
CREATE TABLE `routes` (
    `regex` VARCHAR(255) PRIMARY KEY,
    `proc` VARCHAR(255)
);

INSERT INTO `routes` VALUES
    ('^/static/.*$', 'static_handler'),
    ('^/$', 'index_handler'),
    ('^/reflect$', 'reflect_handler');

DROP TABLE IF EXISTS `static_assets`;
CREATE TABLE `static_assets` (
    `path` VARCHAR(255) PRIMARY KEY,
    `data` TEXT
);

INSERT INTO `static_assets` VALUES ('/static/foo', 'foo static file');

DROP PROCEDURE IF EXISTS `static_handler`;
DROP PROCEDURE IF EXISTS `index_handler`;
DROP PROCEDURE IF EXISTS `reflect_handler`;

DROP PROCEDURE IF EXISTS `parse_cookies`;
DROP PROCEDURE IF EXISTS `app`;

DELIMITER $$

CREATE PROCEDURE `static_handler` (IN `route` VARCHAR(255), OUT `status` INT, OUT `resp` TEXT)
BEGIN
    IF ( SELECT EXISTS (SELECT 1 FROM `static_assets` WHERE `path` = route)) THEN
        SELECT 200, `data` INTO status, resp FROM `static_assets` WHERE `path` = route;
    ELSE
        SET status = 404;
        SET resp = 'Static file not found.';
    END IF;
END$$

CREATE PROCEDURE `index_handler` (IN `route` VARCHAR(255), OUT `status` INT, OUT `resp` TEXT)
BEGIN
    SET status = 200;
    SET resp = 'Hello world!';
END$$

CREATE PROCEDURE `reflect_handler` (IN `route` VARCHAR(255), OUT `status` INT, OUT `resp` TEXT)
BEGIN
    SET status = 200;
    
    SET resp = 'Query params: \n';
    SELECT GROUP_CONCAT(CONCAT(`k`, ': ', `v`) SEPARATOR '\n') INTO @query_params_text FROM `query_params`;
    SET resp = CONCAT(resp, IFNULL(@query_params_text, ''));
    
    SET resp = CONCAT(resp, '\n\nHeaders:\n');
    SELECT GROUP_CONCAT(CONCAT(`k`, ': ', `v`) SEPARATOR '\n') INTO @headers_text FROM `headers`;
    SET resp = CONCAT(resp, IFNULL(@headers_text, ''));
    
    SET resp = CONCAT(resp, '\n\nCookies:\n');
    SELECT GROUP_CONCAT(CONCAT(`name`, ': ', `value`) SEPARATOR '\n') INTO @cookies_text FROM `cookies`;
    SET resp = CONCAT(resp, IFNULL(@cookies_text, ''));
END$$

CREATE PROCEDURE `parse_cookies` (IN `cookies` VARCHAR(4095))
BEGIN
    DECLARE cookie, cookie_name, cookie_value VARCHAR(4095);
    SET cookie = SUBSTRING_INDEX(cookies, ';', 1);
    
    SET cookie_name = TRIM(SUBSTRING_INDEX(cookie, '=', 1));
    SET cookie_value = TRIM(SUBSTRING(cookie FROM LENGTH(cookie_name) + 2));
    
    INSERT INTO `cookies` VALUES (cookie_name, cookie_value);
    
    IF ( INSTR(cookies, ';') > 0 ) THEN
        CALL parse_cookies(SUBSTRING(cookies FROM INSTR(cookies, ';') + 1));
    END IF;
END$$

CREATE PROCEDURE `app` (IN `route` VARCHAR(255), OUT `status` INT, OUT `resp` TEXT)
BEGIN
    CREATE TEMPORARY TABLE IF NOT EXISTS `cookies` (`name` VARCHAR(255) PRIMARY KEY, `value` VARCHAR(4095));
    IF ( SELECT EXISTS (SELECT 1 FROM `headers` WHERE `k` = 'COOKIE')) THEN
        SELECT `v` INTO @cookie FROM `headers` WHERE `k` = 'COOKIE';
        CALL parse_cookies(@cookie);
    END IF;
    
    IF ( SELECT EXISTS (SELECT 1 FROM `routes` WHERE route REGEXP `regex`)) THEN
        SET @stmt = CONCAT('CALL ', (SELECT `proc` FROM `routes` WHERE route REGEXP `regex` LIMIT 1), ' (?, ?, ?)');
        PREPARE handler_call FROM @stmt;
        
        SET @route = route;
        EXECUTE handler_call USING @route, @proc_status, @proc_resp;
        
        SET status = @proc_status;
        SET resp = @proc_resp;
    ELSE
        SET status = 404;
        SET resp = 'Route not found.';
    END IF;
    
    INSERT INTO `responses` (route, code) VALUES (route, status);
END$$

DELIMITER ;
