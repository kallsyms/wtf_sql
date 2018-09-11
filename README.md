# wtf.sql

Description: I heard that moving application logic into the database could improve performance, so I moved _everything_ into the database!
Points: 400
Category: Web

Solve:
1. Template injection -> `${ GET_hi }` if `GET_hi` is `${ secret }` then it will get interpolated again leaking secret
2. secret is used to sign secure cookies
3. allows you to change `is_admin`
4. 
...
n-1. insert route with arb `SELECT ...`
n. leak everything, flag in another table, db, global, etc.

Bug ideas:
    * template injection -> leak config
    * "pass-the-signature" -> get the server to sign an arbitrary value in another cookie, substitute with the `is_admin` cookie since name is not part of the signature

Formatting notes:
    * Types
        * Routes should be VARCHAR(255)
        * header, cookie, template, etc. keys should be VARCHAR(255)
        * header, cookie, template, etc. values should be TEXT
        * response is TEXT
    * Naming
        * k/v pairs are always `name` `value` (to add to the confusion)

TODO:
- remove config
- X-SQL-Facts
