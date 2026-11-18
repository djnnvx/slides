import hashlib, sys

SALT_NMK = bytes.fromhex("08856daf7cf58186")

def pbkdf1(pw, salt, rounds):
    d = hashlib.sha256(pw + salt).digest()
    for _ in range(rounds - 1):
        d = hashlib.sha256(d).digest()
    return d

pw = (sys.argv[1] if len(sys.argv) > 1 else "HomePlugAV").encode()
nmk = pbkdf1(pw, SALT_NMK, 1000)[:16]
print(f"password : {pw.decode()}")
print(f"NMK      : {nmk.hex()}")
