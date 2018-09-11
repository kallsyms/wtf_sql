-- Routes

INSERT INTO `routes` VALUES
    ('/static/%', 'CALL static_handler(?, ?, ?)'),
    ('/', 'CALL index_handler(?, ?, ?)'),
    ('/reflect', 'CALL reflect_handler(?, ?, ?)'),
    ('/template_demo', 'CALL template_demo_handler(?, ?, ?)'),
    ('/login', 'CALL login_handler(?, ?, ?)'),
    ('/register', 'CALL register_handler(?, ?, ?)'),
    ('/list_users', 'CALL list_users_handler(?, ?, ?)');

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
    DECLARE logged_in BOOLEAN;

    CALL is_logged_in(logged_in);
    if logged_in THEN
        CALL logged_in_index_handler(status, resp);
    ELSE
        CALL logged_out_index_handler(status, resp);
    END IF;
END$$


DROP PROCEDURE IF EXISTS `logged_in_index_handler`$$
CREATE PROCEDURE `logged_in_index_handler` (OUT `status` INT, OUT `resp` TEXT)
BEGIN
    DECLARE u_email TEXT;
    DECLARE user_id INT;
    DECLARE user_name TEXT;
    DECLARE post_list TEXT;
    DECLARE u_id INT;

    CALL get_cookie('email', u_email);
    SET user_id = (SELECT `id` FROM `users` WHERE `email` = u_email);
    SET user_name = (SELECT `name` FROM `users` WHERE `email` = u_email);

    CALL get_user_recent_post_list(user_id, post_list);
    CALL set_template_var('post_list', post_list);
    CALL set_template_var('user_name', user_name);
    
    SET status = 200;
    CALL template('/templates/index_logged_in.html', resp);
END$$


DROP PROCEDURE IF EXISTS `logged_out_index_handler`$$
CREATE PROCEDURE `logged_out_index_handler` (OUT `status` INT, OUT `resp` TEXT)
BEGIN
    SET status = 200;
    SET resp = 'Hello world (logged_out)!';
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


DROP PROCEDURE IF EXISTS `login_handler`$$
CREATE PROCEDURE `login_handler` (IN `route` VARCHAR(255), OUT `status` INT, OUT `resp` TEXT)
BEGIN
    DECLARE name, email, password TEXT;
    DECLARE auth BOOLEAN;

    
    CALL get_param('email', email);
    CALL get_param('password', password);

    CALL check_password(email, password, auth);
    IF auth THEN
        SET resp = CONCAT(email, ', ', password);
        CALL set_cookie('email', email);
        CALL redirect('/', status);
    ELSE
        SET status = 401;
        
        CALL set_template_var('error_msg', 'Email or password is incorrect.');
        CALL template('/templates/404.html', resp);
    END IF;
END$$


DROP PROCEDURE IF EXISTS `register_handler`$$
CREATE PROCEDURE `register_handler` (IN `route` VARCHAR(255), OUT `status` INT, OUT `resp` TEXT)
BEGIN
    DECLARE name, email, password TEXT;
    DECLARE already_exists BOOLEAN;

    SET `name` = NULL;
    SET `email` = NULL;
    SET `password` = NULL;

    CALL get_param('name', `name`);
    CALL get_param('email', `email`);
    CALL get_param('password', `password`);

    CALL user_exists(email, already_exists);
    IF ISNULL(`name`) OR ISNULL(`email`) OR ISNULL(`password`) THEN
        SET status = 200;
        CALL set_template_var('error_msg', '');
        CALL template('/templates/register.html', resp);
    ELSEIF already_exists THEN
        SET status = 200;
        CALL set_template_var('error_msg', 'User already exists. <a href=/register>Go Back</a>');
        CALL template('/templates/register.html', resp);
    ELSE
        SET resp = 'Registered!!!!';
        CALL create_user(`email`, `name`, `password`);
        CALL redirect('/', status);
    END IF;
END$$


DROP PROCEDURE IF EXISTS `list_users_handler`$$
CREATE PROCEDURE `list_users_handler` (IN `route` VARCHAR(255), OUT `status` INT, OUT `resp` TEXT)
BEGIN
    DECLARE users_table TEXT;

    SET status = 200;

    CALL dump_users(users_table);

    CREATE TEMPORARY TABLE IF NOT EXISTS `template_vars` (`name` VARCHAR(255) PRIMARY KEY, `value` TEXT);
    INSERT INTO `template_vars` VALUES ('users_table', users_table);
    CALL template('/templates/users.html', resp);
END$$


DELIMITER ;
