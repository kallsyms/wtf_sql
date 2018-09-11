-- Template helpers

DELIMITER $$

DROP PROCEDURE IF EXISTS `populate_common_template_vars`$$
CREATE PROCEDURE `populate_common_template_vars` ()
BEGIN
    INSERT INTO `template_vars` SELECT CONCAT('config_', name), value FROM `config`;
    INSERT INTO `template_vars` SELECT CONCAT('cookie_', name), value FROM `cookies`;
    INSERT INTO `template_vars` SELECT CONCAT('request_', name), value FROM `query_params`;
END$$

DROP PROCEDURE IF EXISTS `template_string`$$
CREATE PROCEDURE `template_string` (IN `template_string` TEXT, OUT `resp` TEXT)
BEGIN
    DECLARE formatted TEXT;
    DECLARE done BOOLEAN;
    DECLARE fmt_name, fmt_val TEXT;
    DECLARE kwarg_cur CURSOR FOR SELECT `name`, `value` FROM `template_vars`;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

    CREATE TEMPORARY TABLE IF NOT EXISTS `template_vars` (`name` VARCHAR(255) PRIMARY KEY, `value` VARCHAR(4095));
    CALL populate_common_template_vars();

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

DELIMITER ;
