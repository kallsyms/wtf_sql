DELIMETER $$

DROP PROCEDURE IF EXISTS `app`$$
CREATE PROCEDURE `app` (IN `route` VARCHAR(255), IN `params` TEXT, IN `post_data` TEXT, OUT `status` TEXT, OUT `resp` TEXT)
BEGIN
    DECLARE req_cookies, resp_cookies TEXT;
    DECLARE status_code INT;

    CREATE TEMPORARY TABLE `resp_headers` (`name` VARCHAR(255) PRIMARY KEY, `value` TEXT);
    CREATE TEMPORARY TABLE `resp_cookies` (`name` VARCHAR(255) PRIMARY KEY, `value` TEXT);

    CREATE TEMPORARY TABLE `query_params` (`name` VARCHAR(255) PRIMARY KEY, `value` TEXT);
    CALL parse_params(params);
    CALL parse_params(post_data);

    CREATE TEMPORARY TABLE `cookies` (`name` VARCHAR(255) PRIMARY KEY, `value` TEXT);
    IF ( SELECT EXISTS (SELECT 1 FROM `headers` WHERE `name` = 'COOKIE')) THEN
        SET req_cookies = (SELECT `value` FROM `headers` WHERE `name` = 'COOKIE');
        CALL parse_cookies(req_cookies);
    END IF;
    
    IF ( SELECT EXISTS (SELECT 1 FROM `routes` WHERE route LIKE `match`)) THEN
        SET @stmt = (SELECT `proc` FROM `routes` WHERE route LIKE `match` LIMIT 1);
        PREPARE handler_call FROM @stmt;
        
        SET @route = route;
        EXECUTE handler_call USING @route, @proc_status, @proc_resp;
        
        SET status_code = @proc_status;
        SET resp = @proc_resp;
    ELSE
        SET status_code = 404;
        SET resp = 'Route not found.';
    END IF;
    
    SET resp_cookies = (SELECT GROUP_CONCAT((CONCAT(`name`, '=', `value`)) SEPARATOR '; ') FROM `resp_cookies`);
    IF NOT ISNULL(resp_cookies) THEN
        INSERT INTO `resp_headers` VALUES ('Set-Cookie', resp_cookies) ON DUPLICATE KEY UPDATE `value` = resp_cookies;
    END IF;

    SET status = (SELECT `message` FROM `status_strings` WHERE `code` = status_code);

    INSERT INTO `responses` (route, code) VALUES (route, status_code);
END$$

DELIMETER ;
