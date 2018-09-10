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
