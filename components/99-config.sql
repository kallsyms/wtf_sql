-- XXX: Don't give config values out
INSERT INTO `config` VALUES
    ('signing_key', 'an_bad_secret_value_nhcq497y8');

INSERT INTO `priv_config` VALUES
    ('signing_key', '25lGMJ5vkUMkgtshietdk9NC');

-- XXX: Don't have admin user in prod with privs
INSERT INTO `users` (`email`, `name`, `pass_hash`, `admin`) VALUES
    ('admin@wtf.sql', 'admin', SHA2('keJipjK6KXRKQHcxzoWowVPPZu', 256), TRUE);

INSERT INTO `admin_privs` VALUES
    ('admin@wtf.sql', 'panel_view'),
    ('admin@wtf.sql', 'panel_create');

INSERT INTO `panels` VALUES
    ('admin@wtf.sql', 'information_schema.INNODB_BUFFER_POOL_STATS'),
    ('admin@wtf.sql', 'information_schema.PLUGINS'),
    ('admin@wtf.sql', 'information_schema.PROCESSLIST');
