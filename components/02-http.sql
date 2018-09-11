-- HTTP Core (parsers)

DELIMITER $$

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
        
        INSERT INTO `cookies` VALUES (cookie_name, cookie_value) ON DUPLICATE KEY UPDATE `value` = cookie_value;

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

        INSERT INTO `query_params` VALUES (param_name, param_value) ON DUPLICATE KEY UPDATE `value` = param_value;

        SET cur_params = SUBSTRING(cur_params FROM LENGTH(param) + 2);
    END WHILE;
END$$


DROP PROCEDURE IF EXISTS `set_header`$$
CREATE PROCEDURE `set_header` (IN `name` VARCHAR(255), IN `value` VARCHAR(4095))
BEGIN
    INSERT INTO `resp_headers` VALUES (`name`, `value`) ON DUPLICATE KEY UPDATE `value` = `value`;
END$$


DROP PROCEDURE IF EXISTS `set_cookie`$$
CREATE PROCEDURE `set_cookie` (IN `name` VARCHAR(255), IN `value` VARCHAR(4095))
BEGIN
    INSERT INTO `resp_cookies` VALUES (`name`, `value`) ON DUPLICATE KEY UPDATE `value` = `value`;
END$$

DELIMITER ;
