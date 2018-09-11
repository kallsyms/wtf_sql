-- HTTP Core (parsers, cookie handling, etc.)

DELIMITER $$


DROP PROCEDURE IF EXISTS `sign_cookie`$$
CREATE PROCEDURE `sign_cookie` (IN `cookie_value` TEXT, OUT `signed` TEXT)
BEGIN
    DECLARE secret, signature TEXT;
    SET secret = (SELECT `value` FROM `config` WHERE `name` = 'signing_key');

    SET signature = SHA2(CONCAT(cookie_value, secret), 256);

    SET signed = CONCAT(signature, '.', cookie_value);
END$$


DROP PROCEDURE IF EXISTS `verify_cookie`$$
CREATE PROCEDURE `verify_cookie` (IN `signed_value` TEXT, OUT `cookie_value` TEXT, OUT `valid` BOOLEAN)
BEGIN
    DECLARE secret, signature TEXT;
    SET secret = (SELECT `value` FROM `config` WHERE `name` = 'signing_key');
    
    SET signature = SUBSTR(signed_value FROM 1 FOR 64);
    SET cookie_value = SUBSTR(signed_value FROM 66);

    SET valid = (SELECT SHA2(CONCAT(cookie_value, secret), 256) = signature);
END$$


DROP PROCEDURE IF EXISTS `parse_cookies`$$
CREATE PROCEDURE `parse_cookies` (IN `cookies` TEXT)
BEGIN
    -- Parse cookies in the form a=b; b=c; c=d;
    DECLARE cur_cookies, cookie, cookie_name, cookie_value_and_sig, cookie_value TEXT;
    DECLARE cookie_valid BOOLEAN;

    SET cur_cookies = cookies;

    INSERT INTO `cookies` VALUES ('1', '1');

    WHILE ( INSTR(cur_cookies, '=') > 0 ) DO
        SET cookie = SUBSTRING_INDEX(cur_cookies, ';', 1);
        
        SET cookie_name = TRIM(SUBSTRING(cookie FROM 1 FOR INSTR(cookie, '=') - 1));
        SET cookie_value_and_sig = TRIM(SUBSTRING(cookie FROM INSTR(cookie, '=') + 1));

        CALL verify_cookie(cookie_value_and_sig, cookie_value, cookie_valid);

        IF cookie_valid THEN
            INSERT INTO `cookies` VALUES (cookie_name, cookie_value) ON DUPLICATE KEY UPDATE `value` = cookie_value;
        END IF;

        -- + 2 because the mysql is 1-indexed and because this needs to pass the ';'
        -- Also TRIM to remove the optional space after the semicolon
        SET cur_cookies = TRIM(SUBSTRING(cur_cookies FROM LENGTH(cookie) + 2));
    END WHILE;

    INSERT INTO `cookies` VALUES ('3', '3');
END$$


DROP PROCEDURE IF EXISTS `set_cookie`$$
CREATE PROCEDURE `set_cookie` (IN `name` VARCHAR(255), IN `value` TEXT)
BEGIN
    DECLARE signed_value TEXT;
    CALL sign_cookie(value, signed_value);

    INSERT INTO `resp_cookies` VALUES (name, signed_value) ON DUPLICATE KEY UPDATE `value` = signed_value;
END$$





DROP PROCEDURE IF EXISTS `parse_params`$$
CREATE PROCEDURE `parse_params` (IN `params` TEXT)
BEGIN
    -- Parse URL params of the form a=b&b=c&c=d
    DECLARE cur_params, param, param_name, param_value TEXT;
    SET cur_params = params;

    WHILE ( INSTR(cur_params, '=') > 0 ) DO 
        SET param = SUBSTRING_INDEX(cur_params, '&', 1);

        SET param_name = TRIM(SUBSTRING(param FROM 1 FOR INSTR(param, '=') - 1));
        SET param_value = TRIM(SUBSTRING(param FROM INSTR(param, '=') + 1));

        INSERT INTO `query_params` VALUES (param_name, param_value) ON DUPLICATE KEY UPDATE `value` = param_value;

        SET cur_params = SUBSTRING(cur_params FROM LENGTH(param) + 2);
    END WHILE;
END$$


DROP PROCEDURE IF EXISTS `get_param`$$
CREATE PROCEDURE `get_param` (IN `i_name` TEXT, OUT `o_value` TEXT)
BEGIN
    SET o_value = (SELECT `value` FROM `query_params` WHERE `name` = i_name LIMIT 1);
END$$


DROP PROCEDURE IF EXISTS `set_header`$$
CREATE PROCEDURE `set_header` (IN `name` VARCHAR(255), IN `value` TEXT)
BEGIN
    INSERT INTO `resp_headers` VALUES (`name`, `value`) ON DUPLICATE KEY UPDATE `value` = `value`;
END$$


DROP PROCEDURE IF EXISTS `redirect`$$
CREATE PROCEDURE `redirect` (IN `i_location` TEXT, OUT `o_status` INT)
BEGIN
    SET o_status = 302;
    CALL set_header('Location', i_location);
END$$


DELIMITER ;
