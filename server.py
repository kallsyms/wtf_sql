import pymysql
from urllib.parse import parse_qs

STATUS_STRINGS = {
    200: "200 OK",
    404: "404 Not Found",
}

def application(environ, start_response):
    conn = pymysql.connect('localhost', 'app_sql', 'app_sql', 'app_sql')
    with conn.cursor() as cursor:
        cursor.execute("CREATE TEMPORARY TABLE IF NOT EXISTS query_params (k VARCHAR(255) PRIMARY KEY, v VARCHAR(4095))")
        print("Params:")
        for k, v in parse_qs(environ['QUERY_STRING']).items():
            if type(v) is list:
                v = v[0]
            print(k,v)
            cursor.execute("INSERT INTO query_params VALUES (%s, %s)", (k,v))
        
        headers = {k[5:]: v for (k, v) in environ.items() if k.startswith('HTTP_')}
        cursor.execute("CREATE TEMPORARY TABLE IF NOT EXISTS headers (k VARCHAR(255) PRIMARY KEY, v VARCHAR(4095))")
        print("Headers:")
        for k, v in headers.items():
            print(k,v)
            cursor.execute("INSERT INTO headers VALUES (%s, %s)", (k,v))
        
        try:
            cursor.callproc("app", [environ['PATH_INFO'], None, None])
        except pymysql.Error as e:
            print(e)
            start_response('500 Internal Server Error', [('Content-Type', 'text/html')])
            return b"Somethin dun broke"
        
        cursor.execute("SELECT @_app_1, @_app_2")
        code, resp = cursor.fetchone()
        print(STATUS_STRINGS[code] + ": " + resp)
        headers = []
        
        conn.commit()
        
        start_response(STATUS_STRINGS[code], headers)
        return resp.encode('utf-8')