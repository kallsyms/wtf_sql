#!/bin/bash

mysql -h 127.0.0.1 -u app_sql --password=app_sql app_sql < app.sql && uwsgi --http :9090 --wsgi-file server.py
