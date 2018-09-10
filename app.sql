-- "Your scientists were so preoccupied with whether or not they could, they didn’t stop to think if they should."

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
    `match` VARCHAR(128) PRIMARY KEY,
    `proc` VARCHAR(128)
);

INSERT INTO `routes` VALUES
    ('/static/%', 'CALL static_handler'),
    ('/', 'CALL index_handler'),
    ('/reflect', 'CALL reflect_handler'),
    ('/template_demo', 'CALL template_demo_handler');

DROP TABLE IF EXISTS `static_assets`;
CREATE TABLE `static_assets` (
    `path` VARCHAR(255) PRIMARY KEY,
    `data` TEXT
);

INSERT INTO `static_assets` VALUES ('/static/foo', 'static foo file');

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
    SET resp = CONCAT(resp, IFNULL(@query_params_text, ''));
    
    SET resp = CONCAT(resp, '\n\nHeaders:\n');
    SELECT GROUP_CONCAT(CONCAT(`name`, ': ', `value`) SEPARATOR '\n') INTO @headers_text FROM `headers`;
    SET resp = CONCAT(resp, IFNULL(@headers_text, ''));
    
    SET resp = CONCAT(resp, '\n\nCookies:\n');
    SELECT GROUP_CONCAT(CONCAT(`name`, ': ', `value`) SEPARATOR '\n') INTO @cookies_text FROM `cookies`;
    SET resp = CONCAT(resp, IFNULL(@cookies_text, ''));
END$$


DROP PROCEDURE IF EXISTS `template`$$
CREATE PROCEDURE `template` (IN `template_string` TEXT, OUT `resp` TEXT)
BEGIN
    DECLARE formatted TEXT;
    DECLARE done BOOLEAN;
    DECLARE fmt_name, fmt_val TEXT;
    DECLARE kwarg_cur CURSOR FOR SELECT `name`, `value` FROM `template_vars`;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

    SET formatted = template_string;

    OPEN kwarg_cur;

    fmt_loop: LOOP
        FETCH kwarg_cur INTO fmt_name, fmt_val;

        SET formatted = REPLACE(formatted, CONCAT('${', fmt_name, '}'), fmt_val);

        IF done THEN
            CLOSE kwarg_cur;
            LEAVE fmt_loop;
        END IF;
    END LOOP fmt_loop;

    SET resp = formatted;

    DROP TEMPORARY TABLE `template_vars`;
END$$


DROP PROCEDURE IF EXISTS `template_demo_handler`$$
CREATE PROCEDURE `template_demo_handler` (IN `route` VARCHAR(255), OUT `status` INT, OUT `resp` TEXT)
BEGIN
    DECLARE template_string TEXT;

    SET status = 200;

    SET template_string = '<html><head><title>asdf</title></head><body>Hello ${name}</body></html>';

    CREATE TEMPORARY TABLE `template_vars` (`name` VARCHAR(255) PRIMARY KEY, `value` VARCHAR(4095));
    INSERT INTO `template_vars` VALUES
        ('name', 'Nick');

    CALL template(template_string, resp);
END$$


DROP PROCEDURE IF EXISTS `parse_cookies`$$
CREATE PROCEDURE `parse_cookies` (IN `cookies` VARCHAR(4095))
BEGIN
    -- Parse cookies in the form a=b; b=c; c=d;
    DECLARE cur_cookies, cookie, cookie_name, cookie_value VARCHAR(4095);
    SET cur_cookies = cookies;

    WHILE ( INSTR(cur_cookies, '=') > 0 ) DO
        SET cookie = SUBSTRING_INDEX(cur_cookies, ';', 1);
        
        SET cookie_name = TRIM(SUBSTRING(cookie FROM 1 FOR INSTR(cookie, '=') - 1));
        SET cookie_value = TRIM(SUBSTRING(cookie FROM INSTR(cookie, '=') + 1));
        
        INSERT INTO `cookies` VALUES (cookie_name, cookie_value) ON DUPLICATE KEY UPDATE `value`=cookie_value;

        -- + 2 because the mysql is 1-indexed and because this needs to pass the ';'
        -- Also TRIM to remove the optional space after the semicolon
        SET cur_cookies = TRIM(SUBSTRING(cur_cookies FROM LENGTH(cookie) + 2));
    END WHILE;
END$$


DROP PROCEDURE IF EXISTS `parse_params`$$
CREATE PROCEDURE `parse_params` (IN `params` VARCHAR(4095))
BEGIN
    -- Parse URL params of the form a=b&b=c&c=d
    DECLARE cur_params, param, param_name, param_value VARCHAR(4095);
    SET cur_params = params;

    WHILE ( INSTR(cur_params, '=') > 0 ) DO 
        SET param = SUBSTRING_INDEX(cur_params, '&', 1);

        SET param_name = TRIM(SUBSTRING(param FROM 1 FOR INSTR(param, '=') - 1));
        SET param_value = TRIM(SUBSTRING(param FROM INSTR(param, '=') + 1));

        INSERT INTO `query_params` VALUES (param_name, param_value) ON DUPLICATE KEY UPDATE `value`=param_value;

        SET cur_params = SUBSTRING(cur_params FROM LENGTH(param) + 2);
    END WHILE;
END$$

DROP PROCEDURE IF EXISTS `app`$$
CREATE PROCEDURE `app` (IN `route` VARCHAR(255), IN `params` VARCHAR(4095), OUT `status` INT, OUT `resp` TEXT)
BEGIN
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
    
    INSERT INTO `responses` (route, code) VALUES (route, status);
END$$

DELIMITER ;
