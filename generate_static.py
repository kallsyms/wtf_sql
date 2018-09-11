import os
from binascii import hexlify


statics = {}
for path, _, filenames in os.walk("static"):
    for fn in filenames:
        fullpath = os.path.join(path, fn)
        with open(fullpath, "rb") as f:
            contents = f.read()
        statics[fullpath] = contents

q = (
    "INSERT INTO `static_assets` VALUES "
    + ", ".join(
        "('/{}', UNHEX('{}'))".format(k, hexlify(v).decode("ascii"))
        for k, v in statics.items()
    )
    + ";"
)

print(q)
