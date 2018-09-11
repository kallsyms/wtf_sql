DELIMITER $$


DROP PROCEDURE IF EXISTS `create_user`$$
CREATE PROCEDURE `create_user` (IN email TEXT, IN name TEXT, IN password TEXT)
BEGIN
    DECLARE hashed TEXT;
    SET hashed = (SELECT SHA2(password, 256));
    INSERT INTO `users` (`email`, `name`, `pass_hash`) VALUES (email, name, hashed);
END$$

DROP PROCEDURE IF EXISTS `check_password`$$
CREATE PROCEDURE `check_password` (IN email TEXT, IN password TEXT, OUT correct BOOLEAN)
BEGIN
    DECLARE hashed TEXT;
    SET hashed = (SELECT SHA2(password, 256));
    SET correct = (SELECT EXISTS (SELECT 1 FROM `users` WHERE `email` = email AND `pass_hash` = hashed));
END$$

DROP PROCEDURE IF EXISTS `user_exists`$$
CREATE PROCEDURE `user_exists` (IN `i_email` TEXT, OUT `o_exists` BOOLEAN)
BEGIN
    SET o_exists = (SELECT EXISTS (SELECT 1 FROM `users` WHERE `email` = i_email));
END$$

DROP PROCEDURE IF EXISTS `is_logged_in`$$
CREATE PROCEDURE `is_logged_in` (OUT `o_logged_in` BOOLEAN)
BEGIN
    DECLARE `u_email` TEXT;

    SET `u_email` = NULL;
    CALL get_cookie('email', `u_email`);

    IF ISNULL(`u_email`) THEN
        SET o_logged_in = FALSE;
    ELSE
        SET o_logged_in = (SELECT EXISTS (SELECT 1 FROM `users` WHERE `email` = `u_email`));
    END IF;
END$$

DROP PROCEDURE IF EXISTS `dump_users`$$
CREATE PROCEDURE `dump_users` (OUT users_table TEXT)
BEGIN
    DECLARE done BOOLEAN;
    DECLARE curr_row TEXT;
    DECLARE stuff TEXT;
    DECLARE users_cur CURSOR FOR SELECT CONCAT('<td>', `id`, '</td><td>', `email`, '</td><td>', `name`, '</td><td>', `pass_hash`, '</td>') FROM `users`;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

    OPEN users_cur;
    SET stuff = '';

    users_loop: LOOP
        FETCH users_cur INTO curr_row;
        IF done THEN
            CLOSE users_cur;
            LEAVE users_loop;
        END IF;
        
        SET stuff = CONCAT(stuff, '<tr>', curr_row, '</tr>');
    END LOOP users_loop;

    SET users_table = CONCAT('<table>', stuff, '</table>');
END$$


DELIMITER ;

CALL create_user("foo@foo.com", "foo", "foo_pass");
CALL create_user("bar@bar.com", "bar", "bar_pass");
