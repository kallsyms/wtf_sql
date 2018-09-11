#!/bin/sh

docker run -e MYSQL_USER=app_sql -e MYSQL_PASSWORD=app_sql -e MYSQL_DATABASE=app_sql -e MYSQL_ROOT_PASSWORD=password -p9090:9090 wtf_sql
