-- XXX: Don't give config values out
INSERT INTO `config` VALUES
    ('signing_key', 'an_bad_secret_value_nhcq497y8');

INSERT INTO `users` (`email`, `name`, `pass_hash`, `admin`) VALUES
    ('admin@wtf.sql', 'admin', SHA2('keJipjK6KXRKQHcxzoWowVPPZu', 256), TRUE);

