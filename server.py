import pymysql
from urllib.parse import parse_qs

STATUS_STRINGS = {
    200: "200 OK",
    404: "404 Not Found",
}

def application(environ, start_response):
    conn = pymysql.connect('localhost', 'app_sql', 'app_sql', 'app_sql')
    with conn.cursor() as cursor:
        headers = {k[5:]: v for (k, v) in environ.items() if k.startswith('HTTP_')}
        cursor.execute("CREATE TEMPORARY TABLE IF NOT EXISTS headers (name VARCHAR(255) PRIMARY KEY, value VARCHAR(4095))")
        print("Headers:")
        for k, v in headers.items():
            print(k,v)
            cursor.execute("INSERT INTO headers VALUES (%s, %s)", (k,v))

        app_args = [environ['PATH_INFO'], environ['QUERY_STRING'], None, None]
        print(app_args)
        try:
            cursor.callproc("app", app_args)
        except pymysql.Error as e:
            print(e)
            start_response('500 Internal Server Error', [('Content-Type', 'text/html')])
            return b"Somethin dun broke"

        cursor.execute("SELECT @_app_2, @_app_3")
        code, resp = cursor.fetchone()
        print(STATUS_STRINGS[code] + ": " + resp)
        headers = []

        conn.commit()

        start_response(STATUS_STRINGS[code], headers)
        return resp.encode('utf-8')
