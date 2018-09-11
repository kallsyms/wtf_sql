-- Routes

INSERT INTO `routes` VALUES
    ('/static/%', 'CALL static_handler(?, ?, ?)'),
    ('/', 'CALL index_handler(?, ?, ?)'),
    ('/reflect', 'CALL reflect_handler(?, ?, ?)'),
    ('/template_demo', 'CALL template_demo_handler(?, ?, ?)');

DELIMITER $$

DROP PROCEDURE IF EXISTS `static_handler`$$
CREATE PROCEDURE `static_handler` (IN `route` VARCHAR(255), OUT `status` INT, OUT `resp` TEXT)
BEGIN
    IF ( SELECT EXISTS (SELECT 1 FROM `static_assets` WHERE `path` = route)) THEN
        SELECT 200, `data` INTO status, resp FROM `static_assets` WHERE `path` = route;
    ELSE
        SET status = 404;
        SET resp = 'Static file not found.';
    END IF;
END$$

DROP PROCEDURE IF EXISTS `index_handler`$$
CREATE PROCEDURE `index_handler` (IN `route` VARCHAR(255), OUT `status` INT, OUT `resp` TEXT)
BEGIN
    SET status = 200;
    SET resp = 'Hello world!';
END$$

DROP PROCEDURE IF EXISTS `reflect_handler`$$
CREATE PROCEDURE `reflect_handler` (IN `route` VARCHAR(255), OUT `status` INT, OUT `resp` TEXT)
BEGIN
    SET status = 200;
    
    SET resp = 'Query params: \n';
    SELECT GROUP_CONCAT(CONCAT(`name`, ': ', `value`) SEPARATOR '\n') INTO @query_params_text FROM `query_params`;
    SET resp = CONCAT(resp, COALESCE(@query_params_text, ''));
    
    SET resp = CONCAT(resp, '\n\nHeaders:\n');
    SELECT GROUP_CONCAT(CONCAT(`name`, ': ', `value`) SEPARATOR '\n') INTO @headers_text FROM `headers`;
    SET resp = CONCAT(resp, COALESCE(@headers_text, ''));
    
    SET resp = CONCAT(resp, '\n\nCookies:\n');
    SELECT GROUP_CONCAT(CONCAT(`name`, ': ', `value`) SEPARATOR '\n') INTO @cookies_text FROM `cookies`;
    SET resp = CONCAT(resp, COALESCE(@cookies_text, ''));

    CALL set_cookie('an_cookie', 'an_value');
    CALL set_header('X-Custom-Header', 'custom_header_value');
END$$


DROP PROCEDURE IF EXISTS `template_demo_handler`$$
CREATE PROCEDURE `template_demo_handler` (IN `route` VARCHAR(255), OUT `status` INT, OUT `resp` TEXT)
BEGIN
    SET status = 200;

    CALL template('/templates/asdf.html', resp);
END$$


DROP PROCEDURE IF EXISTS `app`$$
CREATE PROCEDURE `app` (IN `route` VARCHAR(255), IN `params` VARCHAR(4095), OUT `status` INT, OUT `resp` TEXT)
BEGIN
    DECLARE set_cookies VARCHAR(4095);

    CREATE TEMPORARY TABLE `resp_headers` (`name` VARCHAR(255) PRIMARY KEY, `value` VARCHAR(4095));
    CREATE TEMPORARY TABLE `resp_cookies` (`name` VARCHAR(255) PRIMARY KEY, `value` VARCHAR(4095));

    CREATE TEMPORARY TABLE `query_params` (`name` VARCHAR(255) PRIMARY KEY, `value` VARCHAR(4095));
    CALL parse_params(params);

    CREATE TEMPORARY TABLE `cookies` (`name` VARCHAR(255) PRIMARY KEY, `value` VARCHAR(4095));
    IF ( SELECT EXISTS (SELECT 1 FROM `headers` WHERE `name` = 'COOKIE')) THEN
        SELECT `value` INTO @cookie FROM `headers` WHERE `name` = 'COOKIE';
        CALL parse_cookies(@cookie);
    END IF;
    
    IF ( SELECT EXISTS (SELECT 1 FROM `routes` WHERE route LIKE `match`)) THEN
        SET @stmt = (SELECT `proc` FROM `routes` WHERE route LIKE `match` LIMIT 1);
        PREPARE handler_call FROM @stmt;
        
        SET @route = route;
        EXECUTE handler_call USING @route, @proc_status, @proc_resp;
        
        SET status = @proc_status;
        SET resp = @proc_resp;
    ELSE
        SET status = 404;
        SET resp = 'Route not found.';
    END IF;
    
    SET set_cookies = (SELECT GROUP_CONCAT((CONCAT(`name`, '=', `value`)) SEPARATOR '; ') FROM `resp_cookies`);
    IF NOT ISNULL(set_cookies) THEN
        INSERT INTO `resp_headers` VALUES ('Set-Cookie', set_cookies) ON DUPLICATE KEY UPDATE `value` = set_cookies;
    END IF;

    INSERT INTO `responses` (route, code) VALUES (route, status);
END$$

DELIMITER ;
