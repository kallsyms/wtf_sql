DELIMITER $$


DROP PROCEDURE IF EXISTS `create_user`$$
CREATE PROCEDURE `create_user` (IN email TEXT, IN name TEXT, IN password TEXT)
BEGIN
    DECLARE hashed TEXT;
    SET hashed = (SELECT SHA2(password, 256));
    INSERT INTO `users` (`email`, `name`, `pass_hash`) VALUES (email, name, hashed);
END$$

DROP PROCEDURE iF EXISTS `check_password`$$
CREATE PROCEDURE `check_password` (IN email TEXT, IN password TEXT, OUT correct BOOLEAN)
BEGIN
    DECLARE hashed TEXT;
    SET hashed = (SELECT SHA2(password, 256));
    SET correct = (SELECT EXiSTS (SELECT 1 FROM `users` WHERE `email` = email AND `pass_hash` = hashed));
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
