#!/bin/bash

make app.sql && (docker exec -i wtf_sql '/bin/bash' <<< 'mysql -uapp_sql -papp_sql') < app.sql
